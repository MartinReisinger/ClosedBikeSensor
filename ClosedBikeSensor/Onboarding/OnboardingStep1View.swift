//
//  OnboardingStep1View.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  First onboarding step displaying general information about the app, GitHub link,
//  and privacy statement. Includes a "Weiter" button to proceed to the next step.
//

import SwiftUI

struct OnboardingStep1View: View {
    let onContinue: () -> Void
    let onBack: (() -> Void)?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
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
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        
                        // Content
                        VStack(alignment: .leading, spacing: 20) {
                            // What this app does
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Was macht diese App?")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Diese App misst Abstände zu Objekten während des Radfahrens mithilfe von LiDAR-Technologie. Sie erfasst automatisch GPS-Koordinaten und Fotos für jede Messung.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            // GitHub Link
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Projekt & 3D-Dateien")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                if let githubURL = URL(string: "https://github.com/placeholder") {
                                    Link(destination: githubURL) {
                                        HStack {
                                            Image(systemName: "link")
                                            Text("GitHub Projekt")
                                        }
                                        .font(.body)
                                        .foregroundColor(.blue)
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: "link")
                                        Text("GitHub Projekt (Placeholder)")
                                    }
                                    .font(.body)
                                    .foregroundColor(.gray)
                                }
                                Text("3D-druckbare Datei für die Spiegelvorrichtung")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            // Privacy Statement
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Datenschutz")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Alle Daten, die diese App sammelt, werden nur auf Ihrem Smartphone gespeichert. Es gibt keine Telemetrie, keine Werbung und keine Datenübertragung an externe Server. Dies ist ein privates Side-Projekt.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
                
                // Continue Button at bottom
                VStack {
                    Divider()
                    Button(action: onContinue) {
                        Text("Weiter")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                    .background(Color(.systemBackground))
                }
            }
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
    }
}

#Preview {
    OnboardingStep1View(onContinue: {}, onBack: nil)
}

