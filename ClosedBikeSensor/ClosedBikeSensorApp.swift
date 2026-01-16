//
//  ClosedBikeSensorApp.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Main app entry point. Configures SwiftData model container and sets up the app window.
//

import SwiftUI
import SwiftData

@main
struct ClosedBikeSensorApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MeasureSession.self,
            MeasurePoint.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
