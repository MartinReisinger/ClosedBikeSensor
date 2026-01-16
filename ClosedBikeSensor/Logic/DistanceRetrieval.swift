//
//  DistanceRetrieval.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Backend logic for ARKit depth processing and distance retrieval. Processes LiDAR depth
//  frames, applies ROI filtering, and performs temporal smoothing of distance measurements.
//

import Foundation
@preconcurrency import ARKit
import Combine

@MainActor
class DistanceRetrieval: NSObject, ObservableObject {
    private let config = RetrievalConfig.shared
    let arSession = ARSession()
    private let arkitQueue = DispatchQueue(label: "ARKitSessionQueue")
    private var distanceBuffer: [Float] = []
    
    override init() {
        super.init()
    }
    
    nonisolated func startSession() {
        Task { @MainActor in
            guard config.isLiDARAvailable, !config.isSessionRunning else { return }
            
            let configuration = ARWorldTrackingConfiguration()
            let semantics: ARWorldTrackingConfiguration.FrameSemantics = config.useSmoothedData && 
                ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) ? 
                .smoothedSceneDepth : .sceneDepth
            
            configuration.frameSemantics.insert(semantics)
            arSession.delegate = self
            arSession.run(configuration)
            config.isSessionRunning = true
        }
    }
    
    nonisolated func stopSession() {
        Task { @MainActor in
            guard config.isSessionRunning else { return }
            arSession.pause()
            config.isSessionRunning = false
            config.centerDistance = nil
        }
    }
    
    private func processDepth(frame: ARFrame) {
        guard let depthMap = config.useSmoothedData ? frame.smoothedSceneDepth?.depthMap : frame.sceneDepth?.depthMap,
              let confidenceMap = config.useSmoothedData ? frame.smoothedSceneDepth?.confidenceMap : frame.sceneDepth?.confidenceMap
        else { return }
        
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        CVPixelBufferLockBaseAddress(confidenceMap, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
            CVPixelBufferUnlockBaseAddress(confidenceMap, .readOnly)
        }
        
        guard let depthPtr = CVPixelBufferGetBaseAddress(depthMap)?.assumingMemoryBound(to: Float32.self),
              let confidencePtr = CVPixelBufferGetBaseAddress(confidenceMap)?.assumingMemoryBound(to: UInt8.self)
        else { return }
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        // Apply crosshair offset to ROI center
        let centerX = 0.5 + Float(config.crosshairOffsetX)
        let centerY = 0.5 + Float(config.crosshairOffsetY)
        
        let roiX1 = Int(Float(width) * (centerX - config.roiSize / 2))
        let roiX2 = Int(Float(width) * (centerX + config.roiSize / 2))
        let roiY1 = Int(Float(height) * (centerY - config.roiSize / 2))
        let roiY2 = Int(Float(height) * (centerY + config.roiSize / 2))
        
        var sum: Float = 0
        var count = 0
        
        for y in roiY1..<roiY2 {
            for x in roiX1..<roiX2 {
                let index = y * width + x
                if confidencePtr[index] >= ARConfidenceLevel.medium.rawValue {
                    let depth = depthPtr[index]
                    if depth.isFinite && depth > 0 {
                        sum += depth
                        count += 1
                    }
                }
            }
        }
        
        guard count > 0 else { return }
        let averageDistance = sum / Float(count)
        
        // Temporal smoothing
        distanceBuffer.append(averageDistance)
        if distanceBuffer.count > config.smoothingBufferSize {
            distanceBuffer.removeFirst()
        }
        let smoothedDistance = distanceBuffer.reduce(0, +) / Float(distanceBuffer.count)
        
        Task { @MainActor in
            self.config.centerDistance = smoothedDistance
        }
    }
    
    func captureCurrentFrame() -> ARFrame? {
        return arSession.currentFrame
    }
}

// MARK: - ARSessionDelegate
extension DistanceRetrieval: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        Task { @MainActor in
            self.processDepth(frame: frame)
        }
    }
}
