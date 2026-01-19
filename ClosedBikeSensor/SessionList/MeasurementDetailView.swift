//
//  MeasurementDetailView.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Detailed view of a single measurement point displaying photo, distance, GPS coordinates,
//  timestamp, and interactive map showing the measurement location.
//

import SwiftUI
import MapKit

struct MeasurementDetailView: View {
    let point: MeasurePoint
    @State private var region: MKCoordinateRegion
    
    init(point: MeasurePoint) {
        self.point = point
        _region = State(initialValue: MKCoordinateRegion(
            center: point.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }
    
    var body: some View {
        ZStack {
            
            ScrollView {
                VStack(spacing: 20) {
                    // Photo
                    if let photoData = point.photo, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(15)
                    } else {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    Text("Kein Foto")
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                    
                    // Distance Card
                    VStack(spacing: 15) {
                        Text("Distanz")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%.2f m", point.measurement))
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(colorForDistance(point.measurement))
                            .monospacedDigit()
                        
                        HStack(spacing: 20) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                Text(point.date, format: .dateTime.day().month().year())
                                    .foregroundColor(.gray)
                            }
                            .font(.subheadline)
                            
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.gray)
                                Text(point.date, format: .dateTime.hour().minute())
                                    .foregroundColor(.gray)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(15)
                    
                    // GPS Card
                    VStack(alignment: .leading, spacing: 15) {
                        Text("GPS Position")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Lat:")
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.6f", point.latitude))
                                        .foregroundColor(.secondary)
                                        .monospacedDigit()
                                }
                                
                                HStack {
                                    Text("Lon:")
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.6f", point.longitude))
                                        .foregroundColor(.secondary)
                                        .monospacedDigit()
                                }
                            }
                            .font(.subheadline)
                            
                            Spacer()
                        }
                        
                        // Map
                        Map(position: .constant(.region(region))) {
                            Annotation("", coordinate: point.coordinate) {
                                ZStack {
                                    Circle()
                                        .fill(colorForDistance(point.measurement))
                                        .frame(width: 20, height: 20)
                                    Circle()
                                        .stroke(Color.primary, lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                }
                            }
                        }
                        .frame(height: 200)
                        .cornerRadius(10)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(15)
                    
                    // Session Info
                    if let session = point.session {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Session Info")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text(session.name ?? "Session \(session.number)")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(session.measurements.count) Messungen")
                                    .foregroundColor(.blue)
                            }
                            .font(.subheadline)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Messpunkt")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func colorForDistance(_ distance: Float) -> Color {
        if distance <= 1.0 {
            return .red
        } else if distance <= 1.5 {
            return .yellow
        } else {
            return .green
        }
    }
}

#Preview {
    NavigationStack {
        MeasurementDetailView(point: MeasurePoint(
            date: Date(),
            measurement: 1.25,
            latitude: 48.2082,
            longitude: 16.3738
        ))
    }
}
