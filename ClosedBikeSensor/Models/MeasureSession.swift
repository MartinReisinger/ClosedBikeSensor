//
//  MeasureSession.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  SwiftData model representing a measurement session containing multiple measurement points.
//  Provides computed properties for statistics (min, max, average, median) and total distance.
//

import Foundation
import SwiftData

@Model
final class MeasureSession {
    @Attribute(.unique) var id: UUID
    var number: Int
    var name: String?
    var startDate: Date
    var endDate: Date
    var colorHex: String
    
    @Relationship(deleteRule: .cascade, inverse: \MeasurePoint.session)
    var measurements: [MeasurePoint] = []
    
    init(id: UUID = UUID(), number: Int, name: String? = nil, startDate: Date = Date(), endDate: Date = Date()) {
        self.id = id
        self.number = number
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.colorHex = Self.generateRandomColor()
    }
    
    static func generateRandomColor() -> String {
        // Generate colors that are not red, yellow, or green
        let colors = ["#1E90FF", "#9370DB", "#FF69B4", "#00CED1", "#FF8C00",
                      "#8B4513", "#4B0082", "#DC143C", "#2F4F4F", "#FF1493",
                      "#00BFFF", "#BA55D3", "#FF6347", "#4682B4", "#D2691E"]
        return colors.randomElement() ?? "#1E90FF"
    }

    var displayName: String {
        let trimmed = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        return "Session \(number)"
    }
    
    // MARK: - Computed Properties
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    var minDistance: Float? {
        measurements.map(\.measurement).min()
    }
    
    var maxDistance: Float? {
        measurements.map(\.measurement).max()
    }
    
    var averageDistance: Float? {
        guard !measurements.isEmpty else { return nil }
        let sum = measurements.reduce(0.0) { $0 + $1.measurement }
        return sum / Float(measurements.count)
    }
    
    var medianDistance: Float? {
        guard !measurements.isEmpty else { return nil }
        let sorted = measurements.map(\.measurement).sorted()
        let count = sorted.count
        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        } else {
            return sorted[count / 2]
        }
    }
    
    var totalDistance: Double {
        guard measurements.count > 1 else { return 0 }
        var total: Double = 0
        for i in 0..<(measurements.count - 1) {
            let point1 = measurements[i]
            let point2 = measurements[i + 1]
            let distance = calculateDistance(from: point1.coordinate, to: point2.coordinate)
            total += distance
        }
        return total
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let location2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return location1.distance(from: location2)
    }
}

import CoreLocation
