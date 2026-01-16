//
//  OnboardingStep2View.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Second onboarding step with scrollable setup instructions for mounting the phone
//  and mirror attachment on the bike handlebar. Includes images and a "Weiter" button.
//

import SwiftUI

struct OnboardingStep2View: View {
    let onContinue: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            Text("Einrichtung")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                    
                    // Instruction 0 - 3D Print Link
                    VStack(alignment: .leading, spacing: 15) {
                        Text("1. Spiegelvorrichtung drucken")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Drucken Sie die Spiegelvorrichtung mit einem 3D-Drucker.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        if let makerworldURL = URL(string: "https://makerworld.com") {
                            Link(destination: makerworldURL) {
                                HStack {
                                    Image(systemName: "printer.fill")
                                    Text("Bambu Makerworld - Spiegelvorrichtung")
                                }
                                .font(.body)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                        } else {
                            HStack {
                                Image(systemName: "printer.fill")
                                Text("Bambu Makerworld - Spiegelvorrichtung")
                            }
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Instruction 1
                    VStack(alignment: .leading, spacing: 15) {
                        Text("2. Handyhalterung anbringen")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Sie müssen eine Handyhalterung auf der linken Seite Ihres Fahrrad-Lenkers anbringen.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Placeholder for image
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: 10) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("Bild: Handyhalterung am Lenker")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                            .padding(.vertical, 10)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Instruction 2
                    VStack(alignment: .leading, spacing: 15) {
                        Text("3. Smartphone und Spiegelvorrichtung installieren")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Nun müssen Sie das Smartphone und die Spiegelvorrichtung in die Handyhalterung installieren.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Placeholder for image
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: 10) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("Bild: Smartphone mit Spiegelvorrichtung")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                            .padding(.vertical, 10)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Instruction 3
                    VStack(alignment: .leading, spacing: 15) {
                        Text("4. Auslöser via Lautstärke- oder Auslöserknopf")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Um den Abstand aufzunehmen, können sie entweder den Lautstärke erhöhen Knopf auf der Linken seite vom iPhone drücken, oder einfach den Roten Auslöserknopf am Bildschirm drücken.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
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
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body)
                    .foregroundColor(.blue)
            }
            .padding()
        }
    }
}

#Preview {
    OnboardingStep2View(onContinue: {}, onBack: {})
}

