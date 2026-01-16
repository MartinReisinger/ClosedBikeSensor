//
//  RetrievalConfig.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Singleton configuration class holding app state, permissions, capture parameters,
//  and crosshair offset settings. Provides centralized state management.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RetrievalConfig: ObservableObject {
    static let shared = RetrievalConfig()
    
    // MARK: - App State
    enum AppState {
        case onboarding
        case liveCapture
        case viewingData
    }
    
    @Published var appState: AppState = .onboarding
    
    // MARK: - Permissions & Availability
    @Published var isAuthorized: Bool = false
    @Published var isLiDARAvailable: Bool = false
    @Published var isLocationAuthorized: Bool = false
    
    // MARK: - Session State
    @Published var isSessionRunning: Bool = false
    @Published var centerDistance: Float? = nil
    
    // MARK: - Capture Parameters
    @Published var roiSize: Float = 0.05
    @Published var smoothingBufferSize: Int = 5
    @Published var useSmoothedData: Bool = true
    
    // MARK: - Crosshair Offset
    @Published var crosshairOffsetX: CGFloat = 0.0
    @Published var crosshairOffsetY: CGFloat = 0.0
    @Published var cameraRotation: Int = 0 // 0, 90, 180, 270 degrees
    
    // MARK: - Current Session
    @Published var currentSessionId: UUID?
    
    private init() {}
    
    func resetToDefaults() {
        roiSize = 0.05
        smoothingBufferSize = 5
        useSmoothedData = true
        crosshairOffsetX = 0.0
        crosshairOffsetY = 0.0
        cameraRotation = 0
    }
    
    func cycleCameraRotation() {
        cameraRotation = (cameraRotation + 90) % 360
    }
}
