//
//  MapView.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Interactive map view displaying all measurement points with color-coded markers based on
//  distance. Supports session filtering, route line visualization, and point detail navigation.
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    var onStartMeasurement: (() -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var captureManager: CaptureManager
    @Query private var sessions: [MeasureSession]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.2082, longitude: 16.3738),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedPoint: MeasurePoint?
    @State private var selectedSessionIds: Set<UUID> = []
    @State private var showLines = false
    @State private var showFilterSheet = false
    
    init(onStartMeasurement: (() -> Void)? = nil, captureManager: CaptureManager) {
        self.onStartMeasurement = onStartMeasurement
        self._captureManager = ObservedObject(wrappedValue: captureManager)
    }
    
    var filteredSessions: [MeasureSession] {
        return sessions.filter { selectedSessionIds.contains($0.id) }
    }
    
    var allPoints: [MeasurePoint] {
        filteredSessions.flatMap { $0.measurements }
    }
    
    var body: some View {
        ZStack {
            if sessions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "map")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Keine Messungen")
                        .font(.title2)
                        .foregroundColor(.primary)
                    Text("Starte eine Messung, um sie auf der Karte zu sehen.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Button(action: {
                if captureManager.currentSession == nil {
                    captureManager.setModelContext(modelContext)
                    captureManager.startSession()
                }
                onStartMeasurement?()
            }) {
                        Text("Messung starten")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
            } else {
                Map(position: .constant(.region(region))) {
                    // Draw lines between points if enabled
                    if showLines {
                        ForEach(filteredSessions) { session in
                            let sortedPoints = session.measurements.sorted(by: { $0.date < $1.date })
                            if sortedPoints.count > 1 {
                                MapPolyline(coordinates: sortedPoints.map { $0.coordinate })
                                    .stroke(Color(hex: session.colorHex) ?? .blue, lineWidth: 3)
                            }
                        }
                    }
                    
                    // Draw points
                    ForEach(allPoints) { point in
                        Annotation("", coordinate: point.coordinate) {
                            PointAnnotation(point: point)
                                .onTapGesture {
                                    selectedPoint = point
                                }
                        }
                    }
                }
                .onAppear {
                    centerMapOnPoints()
                }
                
                // Legend
                VStack {
                    Spacer()
                    
                    HStack(spacing: 20) {
                        LegendItem(color: .red, label: "≤ 1.0 m")
                        LegendItem(color: .yellow, label: "< 1.5 m")
                        LegendItem(color: .green, label: "≥ 1.5 m")
                    }
                    .padding()
                    .cornerRadius(10)
                    .padding()
                }
            }
        }
        .onAppear() {
            if selectedSessionIds.isEmpty && !sessions.isEmpty {
                selectedSessionIds = Set(sessions.map { $0.id })
            }
            centerMapOnPoints()
        }
        .navigationTitle("Karte")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 15) {
                    Button(action: { showLines.toggle() }) {
                        Image(systemName: showLines ? "stroke.line.diagonal" : "stroke.line.diagonal.slash")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: { showFilterSheet = true }) {
                        Image(systemName: selectedSessionIds.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(item: $selectedPoint) { point in
            NavigationStack {
                MeasurementDetailView(point: point)
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            SessionFilterView(sessions: sessions, selectedSessionIds: $selectedSessionIds)
        }
    }
    
    private func centerMapOnPoints() {
        guard !allPoints.isEmpty else { return }
        
        let latitudes = allPoints.map { $0.latitude }
        let longitudes = allPoints.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let spanLat = (maxLat - minLat) * 1.5
        let spanLon = (maxLon - minLon) * 1.5
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(spanLat, 0.01),
                longitudeDelta: max(spanLon, 0.01)
            )
        )
    }
}

// MARK: - Point Annotation
struct PointAnnotation: View {
    let point: MeasurePoint
    
    var body: some View {
        ZStack {
            Circle()
                .fill(colorForDistance(point.measurement))
                .frame(width: 16, height: 16)
            Circle()
                .stroke(Color.primary, lineWidth: 2)
                .frame(width: 16, height: 16)
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                .frame(width: 18, height: 18)
        }
        .shadow(radius: 2)
    }
    
    private func colorForDistance(_ distance: Float) -> Color {
        if distance <= 1.0 {
            return .red
        } else if distance < 1.5 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Session Filter View
struct SessionFilterView: View {
    let sessions: [MeasureSession]
    @Binding var selectedSessionIds: Set<UUID>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                List {
                    Section {
                        Button(selectedSessionIds.isEmpty ? "Alle auswählen" : "Alle abwählen") {
                            if selectedSessionIds.isEmpty {
                                selectedSessionIds = Set(sessions.map { $0.id })
                            } else {
                                selectedSessionIds.removeAll()
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Section("Sessions") {
                        ForEach(sessions) { session in
                            HStack {
                                Circle()
                                    .fill(Color(hex: session.colorHex) ?? .blue)
                                    .frame(width: 12, height: 12)
                                
                                VStack(alignment: .leading) {
                                    Text(session.displayName)
                                        .foregroundColor(.primary)
                                    Text("\(session.measurements.count) Messungen")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if selectedSessionIds.contains(session.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedSessionIds.contains(session.id) {
                                    selectedSessionIds.remove(session.id)
                                } else {
                                    selectedSessionIds.insert(session.id)
                                }
                            }
                            .listRowBackground(Color.gray.opacity(0.2))
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Sessions filtern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    NavigationStack {
        MapView(captureManager: CaptureManager())
            .modelContainer(for: [MeasureSession.self, MeasurePoint.self])
    }
}

