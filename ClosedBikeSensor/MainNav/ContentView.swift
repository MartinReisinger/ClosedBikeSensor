//
//  ContentView.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Root view that checks permissions and displays either the onboarding flow or main app interface.
//

import SwiftUI
import SwiftData
import ARKit
import AVFoundation
import Combine

struct ContentView: View {
    @StateObject private var config = RetrievalConfig.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if hasCompletedOnboarding && config.isAuthorized && config.isLocationAuthorized && config.isLiDARAvailable {
                MainTabView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .onAppear {
            checkPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RestartOnboarding"))) { _ in
            // Refresh the view when onboarding restart is requested
            hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        }
    }
    
    private func checkPermissions() {
        // Check LiDAR
        config.isLiDARAvailable = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
        
        // Check Camera
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        config.isAuthorized = (cameraStatus == .authorized)
        
        // Location will be checked by OnboardingView's LocationPermissionManager
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [MeasureSession.self, MeasurePoint.self])
}
