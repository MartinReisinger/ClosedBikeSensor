//
//  CaptureDistance.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Manages measurement capture by combining distance readings, GPS coordinates, and photos
//  into MeasurePoint instances. Handles session lifecycle and location updates.
//

import Foundation
import SwiftUI
import SwiftData
import CoreLocation
import ARKit
import Combine

@MainActor
class CaptureManager: NSObject, ObservableObject {
    @Published var showFeedback = false
    @Published var currentSession: MeasureSession?
    
    private var locationManager = CLLocationManager()
    private var modelContext: ModelContext?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func restoreOrStartSession() {
        guard let context = modelContext else { return }
        
        // Get the most recent session
        let descriptor = FetchDescriptor<MeasureSession>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        let sessions = try? context.fetch(descriptor)
        
        if let mostRecentSession = sessions?.first {
            currentSession = mostRecentSession
        } else {
            startSession()
        }
    }
    
    func startSession() {
        guard let context = modelContext else { return }
        
        // Get next session number
        let descriptor = FetchDescriptor<MeasureSession>(sortBy: [SortDescriptor(\.number, order: .reverse)])
        let sessions = try? context.fetch(descriptor)
        let nextNumber = (sessions?.first?.number ?? 0) + 1
        
        // Create new session
        let session = MeasureSession(number: nextNumber, name: "Session \(nextNumber)", startDate: Date())
        context.insert(session)
        currentSession = session
        
        try? context.save()
    }
    
    func endSession() {
        guard let session = currentSession else { return }
        session.endDate = Date()
        try? modelContext?.save()
        currentSession = nil
    }
    
    func switchToSession(_ session: MeasureSession) {
        // End current session if exists
        if let current = currentSession {
            current.endDate = Date()
        }
        
        // Switch to selected session
        currentSession = session
        try? modelContext?.save()
    }
    
    func capturePoint(distance: Float, frame: ARFrame?) {
        guard let session = currentSession,
              let context = modelContext,
              let location = locationManager.location else { return }
        
        // Extract photo from AR frame
        var photoData: Data?
        if let frame = frame {
            photoData = capturePhoto(from: frame)
        }
        
        // Create measure point
        let point = MeasurePoint(
            date: Date(),
            measurement: distance,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            photo: photoData
        )
        
        point.session = session
        context.insert(point)
        
        try? context.save()
        
        // Show feedback
        showFeedback = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            showFeedback = false
        }
    }
    
    private func capturePhoto(from frame: ARFrame) -> Data? {
        let pixelBuffer = frame.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        // Resize to reasonable size
        let maxDimension: CGFloat = 1024
        let scale = min(maxDimension / uiImage.size.width, maxDimension / uiImage.size.height)
        let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage?.jpegData(compressionQuality: 0.7)
    }
}

// MARK: - CLLocationManagerDelegate
extension CaptureManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Location updates handled automatically
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
