//
//  MeasurePoint.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  SwiftData model representing a single measurement point with distance, GPS coordinates,
//  timestamp, and optional photo snapshot.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class MeasurePoint {
    @Attribute(.unique) var id: UUID
    var date: Date
    var measurement: Float
    var latitude: Double
    var longitude: Double
    var photo: Data?
    
    var session: MeasureSession?
    
    init(id: UUID = UUID(), date: Date, measurement: Float, latitude: Double, longitude: Double, photo: Data? = nil) {
        self.id = id
        self.date = date
        self.measurement = measurement
        self.latitude = latitude
        self.longitude = longitude
        self.photo = photo
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
