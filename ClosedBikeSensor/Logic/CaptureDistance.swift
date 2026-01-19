//
//  CaptureDistance.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Manages measurement capture by combining distance readings, GPS coordinates, and photos
//  into MeasurePoint instances. Handles session lifecycle and location updates.
//
//

import Foundation
import SwiftUI
import SwiftData
import CoreLocation
import ARKit
import Combine

@MainActor
class CaptureManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// Shows temporary feedback animation when a measurement is captured
    @Published var showFeedback = false
    
    /// Currently active session for capturing measurements
    /// Nil means no session is selected/active
    @Published var currentSession: MeasureSession?
    
    // MARK: - Private Properties
    
    private var locationManager = CLLocationManager()
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Public Methods
    
    /// Sets the SwiftData model context for database operations
    /// Must be called before using any session-related methods
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// Restores the most recent session or creates a new one if none exist
    /// This ensures the app always has a session ready on startup
    func restoreOrStartSession() {
        guard let context = modelContext else {
            print("⚠️ CaptureManager: Cannot restore session - modelContext not set")
            return
        }
        
        // Fetch all real sessions (excluding aggregate session with number=0)
        let descriptor = FetchDescriptor<MeasureSession>(
            predicate: #Predicate { $0.number != 0 },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        do {
            let sessions = try context.fetch(descriptor)
            
            if let mostRecentSession = sessions.first {
                // Restore most recent session
                currentSession = mostRecentSession
                print("Restored session: \(mostRecentSession.displayName)")
            } else {
                // No sessions exist - create first session
                startSession()
                print("Created first session")
            }
        } catch {
            print("Error fetching sessions: \(error.localizedDescription)")
            // Fallback: create new session
            startSession()
        }
    }
    
    /// Creates and starts a new measurement session
    /// Assigns the next sequential number and a default name "Session N"
    func startSession() {
        guard let context = modelContext else {
            print("⚠️ CaptureManager: Cannot start session - modelContext not set")
            return
        }
        
        // Get next session number
        let descriptor = FetchDescriptor<MeasureSession>(
            sortBy: [SortDescriptor(\.number, order: .reverse)]
        )
        
        do {
            let sessions = try context.fetch(descriptor)
            let nextNumber = (sessions.first?.number ?? 0) + 1
            
            // Create new session with default name "Session N"
            let session = MeasureSession(
                number: nextNumber,
                name: "Session \(nextNumber)",
                startDate: Date()
            )
            
            context.insert(session)
            currentSession = session
            
            try context.save()
            print("Started new session: \(session.displayName)")
        } catch {
            print("Error starting session: \(error.localizedDescription)")
        }
    }
    
    /// Ends the current session by setting its end date
    /// Does NOT clear currentSession (session remains selected but inactive)
    func endSession() {
        guard let session = currentSession else { return }
        
        session.endDate = Date()
        
        do {
            try modelContext?.save()
            print("Ended session: \(session.displayName)")
        } catch {
            print("Error ending session: \(error.localizedDescription)")
        }
        
        // Note: We don't set currentSession = nil here
        // The session remains selected even after ending
    }
    
    /// Switches to a different session
    /// Ends the current session first if one is active and different
    func switchToSession(_ session: MeasureSession) {
        // End current session if it's different from the target session
        if let current = currentSession, current.id != session.id {
            current.endDate = Date()
        }
        
        // Switch to selected session
        currentSession = session
        
        do {
            try modelContext?.save()
            print("Switched to session: \(session.displayName)")
        } catch {
            print("Error switching session: \(error.localizedDescription)")
        }
    }
    
    /// Ensures a session exists before allowing measurement capture
    /// Creates a new session if currentSession is nil
    /// Returns true if a session is ready, false otherwise
    @discardableResult
    func ensureSessionExists() -> Bool {
        if currentSession == nil {
            restoreOrStartSession()
        }
        return currentSession != nil
    }
    
    /// Captures a measurement point with distance, location, and optional photo
    /// Requires an active session to be set
    func capturePoint(distance: Float, frame: ARFrame?) {
        // Ensure we have all required components
        guard let session = currentSession else {
            print("⚠️ No active session - cannot capture point")
            return
        }
        
        guard let context = modelContext else {
            print("⚠️ No model context - cannot capture point")
            return
        }
        
        guard let location = locationManager.location else {
            print("⚠️ No location available - cannot capture point")
            return
        }
        
        // Extract photo from AR frame if available
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
        
        do {
            try context.save()
            print("Captured point: \(String(format: "%.2f", distance))m")
            
            // Show success feedback
            showFeedback = true
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                showFeedback = false
            }
        } catch {
            print("Error saving measurement: \(error.localizedDescription)")
        }
    }
    
    /// Called when a session is deleted externally (e.g., from ListView)
    /// Clears currentSession if the deleted session was active
    func handleSessionDeleted(_ session: MeasureSession) {
        if currentSession?.id == session.id {
            currentSession = nil
            print("Cleared current session after deletion")
        }
    }
    
    // MARK: - Private Methods
    
    /// Converts an ARFrame's camera image to compressed JPEG data
    /// Resizes to max 1024px on the longest side to save storage space
    private func capturePhoto(from frame: ARFrame) -> Data? {
        let pixelBuffer = frame.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        // Resize to reasonable size (max 1024px on longest side)
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
        // Location updates handled automatically by the manager
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
