//
//  MainTabView.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Main tab bar navigation container with three tabs: Live measurement, Sessions list, and Map view.
//  Shares a single CaptureManager instance across all tabs for consistent session management.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var captureManager = CaptureManager()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            liveTab
            sessionsTab
            mapTab
        }
        .accentColor(.blue)
    }
    
    // MARK: - Live Tab
    
    private var liveTab: some View {
        NavigationStack {
            LiveCaptureView(captureManager: captureManager)
        }
        .tabItem {
            Label("Live", systemImage: "camera.fill")
        }
        .tag(0)
    }
    
    // MARK: - Sessions Tab
    
    private var sessionsTab: some View {
        ListView(selectedTab: $selectedTab, captureManager: captureManager)
            .tabItem {
                Label("Sessions", systemImage: "list.bullet")
            }
            .tag(1)
    }
    
    // MARK: - Map Tab
    
    private var mapTab: some View {
        NavigationStack {
            MapView(
                onStartMeasurement: {
                    // Switch to Live tab when starting a measurement
                    selectedTab = 0
                },
                captureManager: captureManager
            )
        }
        .tabItem {
            Label("Karte", systemImage: "map.fill")
        }
        .tag(2)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [MeasureSession.self, MeasurePoint.self])
}
