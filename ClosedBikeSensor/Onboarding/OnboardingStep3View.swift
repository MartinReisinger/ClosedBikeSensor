//
//  OnboardingStep3View.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Third onboarding step that checks and requests required permissions (camera, location) and
//  verifies LiDAR availability. Displays permission status and guides users through setup.
//

import SwiftUI
import ARKit
import AVFoundation
import CoreLocation
import Combine

struct OnboardingStep3View: View {
    @Binding var hasCompletedOnboarding: Bool
    let onBack: (() -> Void)?
    @StateObject private var config = RetrievalConfig.shared
    @StateObject private var locationManager = LocationPermissionManager()
    @State private var isCheckingCamera = false
    @State private var cameraStatus = ""
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "bicycle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("Bike Sensor")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Messe Abstände beim Radfahren")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 60)
                
                Spacer()
                
                VStack(spacing: 20) {
                    PermissionCard(icon: "location.fill", title: "Standort", description: "Für die GPS-Koordinaten", status: config.isLocationAuthorized ? .granted : .notGranted)
                    PermissionCard(icon: "camera.fill", title: "Kamera", description: "Für die Aufnahme der Messung", status: config.isAuthorized ? .granted : .notGranted)
                    PermissionCard(icon: "sensor.fill", title: "LiDAR", description: "Für die Abstandsmessung", status: config.isLiDARAvailable ? .granted : .notAvailable)
                }
                .padding(.horizontal)

                
                Spacer()
                
                // Action Button
                if allPermissionsGranted {
                    Button(action: {
                        hasCompletedOnboarding = true
                    }) {
                        Text("Los geht's")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)
                } else {
                    Button(action: requestPermissions) {
                        Text(isCheckingCamera ? "Prüfe..." : "Berechtigungen anfordern")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(isCheckingCamera ? 0.5 : 1.0))
                            .cornerRadius(15)
                    }
                    .disabled(isCheckingCamera)
                    .padding(.horizontal)
                    
                    if !config.isAuthorized || !config.isLocationAuthorized {
                        Button(action: openSettings) {
                            Text("Einstellungen öffnen")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                if !config.isLiDARAvailable && config.isAuthorized {
                    Text("⚠️ Dieses Gerät unterstützt kein LiDAR")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 40)
        }
        .overlay(alignment: .topLeading) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                .padding()
            }
        }
        .onAppear {
            checkInitialStatus()
        }
    }
    
    private var allPermissionsGranted: Bool {
        config.isAuthorized && config.isLocationAuthorized && config.isLiDARAvailable
    }
    
    private func checkInitialStatus() {
        // Check LiDAR
        config.isLiDARAvailable = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
        
        // Check Camera
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        config.isAuthorized = (cameraStatus == .authorized)
        
        // Check Location
        locationManager.checkStatus()
    }
    
    private func requestPermissions() {
        isCheckingCamera = true
        
        // Request Camera
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                config.isAuthorized = granted
                cameraStatus = granted ? "Gewährt" : "Verweigert"
                
                // Request Location
                locationManager.requestPermission()
                
                isCheckingCamera = false
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    OnboardingStep3View(hasCompletedOnboarding: .constant(false), onBack: {})
}

