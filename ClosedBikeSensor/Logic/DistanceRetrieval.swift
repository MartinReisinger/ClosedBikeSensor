//
//  DistanceRetrieval.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Backend logic for ARKit depth processing and distance retrieval. Processes LiDAR depth
//  frames, applies ROI (Region of Interest) filtering, and performs temporal smoothing
//  of distance measurements.
//
//  Key components:
//  - LiDAR depth map processing using ARKit
//  - Confidence-based filtering for accurate measurements
//  - Temporal smoothing buffer for stable readings
//  - Adjustable crosshair offset support
//

import Foundation
@preconcurrency import ARKit
import Combine

@MainActor
class DistanceRetrieval: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    /// Shared configuration containing session settings and measurements
    private let config = RetrievalConfig.shared
    
    /// ARKit session for depth data capture
    let arSession = ARSession()
    
    /// Background queue for ARKit operations
    private let arkitQueue = DispatchQueue(label: "ARKitSessionQueue")
    
    /// Buffer for temporal smoothing of distance readings
    private var distanceBuffer: [Float] = []
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Starts the ARKit session with depth tracking
    /// Uses smoothed depth data if available, falls back to regular depth
    nonisolated func startSession() {
        Task { @MainActor in
            // Check prerequisites
            guard config.isLiDARAvailable, !config.isSessionRunning else {
                print("⚠️ Cannot start ARKit session - LiDAR unavailable or already running")
                return
            }
            
            // Configure AR session
            let configuration = ARWorldTrackingConfiguration()
            
            // Choose depth semantic based on availability
            let semantics: ARWorldTrackingConfiguration.FrameSemantics
            if config.useSmoothedData && ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
                semantics = .smoothedSceneDepth
            } else {
                semantics = .sceneDepth
            }
            
            configuration.frameSemantics.insert(semantics)
            arSession.delegate = self
            arSession.run(configuration)
            config.isSessionRunning = true
            
            print("✅ ARKit session started with \(semantics == .smoothedSceneDepth ? "smoothed" : "regular") depth")
        }
    }
    
    /// Stops the ARKit session and clears distance data
    nonisolated func stopSession() {
        Task { @MainActor in
            guard config.isSessionRunning else { return }
            
            arSession.pause()
            config.isSessionRunning = false
            config.centerDistance = nil
            
            print("✅ ARKit session stopped")
        }
    }
    
    /// Captures and returns the current AR frame for photo extraction
    func captureCurrentFrame() -> ARFrame? {
        return arSession.currentFrame
    }
    
    // MARK: - Private Methods
    
    /// Processes depth data from an AR frame
    /// Applies ROI filtering and temporal smoothing to calculate distance
    private func processDepth(frame: ARFrame) {
        // Get depth and confidence maps
        guard let depthMap = config.useSmoothedData ? frame.smoothedSceneDepth?.depthMap : frame.sceneDepth?.depthMap,
              let confidenceMap = config.useSmoothedData ? frame.smoothedSceneDepth?.confidenceMap : frame.sceneDepth?.confidenceMap
        else {
            return
        }
        
        // Lock buffers for reading
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        CVPixelBufferLockBaseAddress(confidenceMap, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
            CVPixelBufferUnlockBaseAddress(confidenceMap, .readOnly)
        }
        
        // Get buffer pointers
        guard let depthPtr = CVPixelBufferGetBaseAddress(depthMap)?.assumingMemoryBound(to: Float32.self),
              let confidencePtr = CVPixelBufferGetBaseAddress(confidenceMap)?.assumingMemoryBound(to: UInt8.self)
        else {
            return
        }
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        // Calculate ROI (Region of Interest) with crosshair offset
        let centerX = 0.5 + Float(config.crosshairOffsetX)
        let centerY = 0.5 + Float(config.crosshairOffsetY)
        
        let roiX1 = Int(Float(width) * (centerX - config.roiSize / 2))
        let roiX2 = Int(Float(width) * (centerX + config.roiSize / 2))
        let roiY1 = Int(Float(height) * (centerY - config.roiSize / 2))
        let roiY2 = Int(Float(height) * (centerY + config.roiSize / 2))
        
        // Calculate average distance within ROI
        var sum: Float = 0
        var count = 0
        
        for y in roiY1..<roiY2 {
            for x in roiX1..<roiX2 {
                let index = y * width + x
                
                // Only include high-confidence pixels
                if confidencePtr[index] >= ARConfidenceLevel.medium.rawValue {
                    let depth = depthPtr[index]
                    
                    // Validate depth value
                    if depth.isFinite && depth > 0 {
                        sum += depth
                        count += 1
                    }
                }
            }
        }
        
        guard count > 0 else {
            // Not enough confident pixels in ROI
            return
        }
        
        let averageDistance = sum / Float(count)
        
        // Apply temporal smoothing
        distanceBuffer.append(averageDistance)
        if distanceBuffer.count > config.smoothingBufferSize {
            distanceBuffer.removeFirst()
        }
        
        let smoothedDistance = distanceBuffer.reduce(0, +) / Float(distanceBuffer.count)
        
        // Update config with smoothed distance
        Task { @MainActor in
            self.config.centerDistance = smoothedDistance
        }
    }
}

// MARK: - ARSessionDelegate

extension DistanceRetrieval: ARSessionDelegate {
    /// Called when ARKit updates with a new frame
    /// Processes depth data on the main actor
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        Task { @MainActor in
            self.processDepth(frame: frame)
        }
    }
}
