//
//  MainTabView.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Main tab bar navigation container with three tabs: Live measurement, Sessions list, and Map view.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Live Distance View
            NavigationStack {
                LiveDistanceView()
            }
            .tabItem {
                Label("Live", systemImage: "camera.fill")
            }
            .tag(0)
            
            // List View
            ListView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet")
                }
                .tag(1)
            
            // Map View
            NavigationStack {
                MapView(onStartMeasurement: {
                        selectedTab = 0
                    })
            }
            .tabItem {
                Label("Karte", systemImage: "map.fill")
            }
            .tag(2)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [MeasureSession.self, MeasurePoint.self])
}
