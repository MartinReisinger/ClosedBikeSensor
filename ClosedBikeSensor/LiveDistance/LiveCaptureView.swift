//
//  LiveCaptureView.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//  Refactored for better structure and clarity
//
//  Main live measurement view with AR camera preview, real-time distance display,
//  crosshair overlay, and capture functionality. Includes edit mode for session
//  management and crosshair adjustment. Volume buttons work as shutter triggers.
//
//

import SwiftUI
import RealityKit
import ARKit
import SwiftData
import AVFoundation
import MediaPlayer
import Combine

// MARK: - Main View

struct LiveCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeasureSession.startDate, order: .reverse) private var allSessions: [MeasureSession]
    
    @StateObject private var config = RetrievalConfig.shared
    @StateObject private var distanceRetrieval = DistanceRetrieval()
    @ObservedObject private var captureManager: CaptureManager
    @StateObject private var volumeButtonHandler = VolumeButtonHandler()
    @State private var editMode = false
    
    /// Filter out aggregate session (number == 0)
    private var realSessions: [MeasureSession] {
        allSessions.filter { $0.number != 0 }
    }
    
    // MARK: - Initialization
    
    init(captureManager: CaptureManager) {
        self._captureManager = ObservedObject(wrappedValue: captureManager)
    }
    
    var body: some View {
        ZStack {
            mainContent
            if !editMode { captureButton }
            if captureManager.showFeedback { feedbackOverlay }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            editButton
        }
        .onAppear(perform: setupView)
        .onDisappear {
            distanceRetrieval.stopSession()
            volumeButtonHandler.stopListening()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Dynamic title that updates based on current session state
    private var navigationTitle: String {
        if let session = captureManager.currentSession {
            return session.displayName
        } else {
            return "Keine Session"
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 15) {
                if editMode { sessionSelector }
                cameraPreview
                distanceDisplay
                if editMode { crosshairControls }
                if editMode { restartOnboardingButton }
                if !editMode { Spacer().frame(height: 120) }
            }
        }
        .scrollDisabled(!editMode)
    }
    
    // MARK: - Camera Preview with Crosshair
    
    private var cameraPreview: some View {
        ZStack {
            if config.isSessionRunning {
                ARViewRepresentable(session: distanceRetrieval.arSession)
                CrosshairView()
                    .offset(crosshairOffset)
            } else {
                loadingView
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.secondary)
            Text("Kamera startet...")
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.3))
    }
    
    // MARK: - Distance Display
    
    private var distanceDisplay: some View {
        DistanceDisplayView(
            distance: config.centerDistance,
            isActive: config.isSessionRunning
        )
        .padding(.horizontal)
    }
    
    // MARK: - Session Selector
    
    private var sessionSelector: some View {
        SessionSelectorView(
            sessions: realSessions, // Only show real sessions (no aggregate)
            selectedSession: Binding(
                get: { captureManager.currentSession },
                set: { if let session = $0 { captureManager.switchToSession(session) } }
            ),
            captureManager: captureManager,
            modelContext: modelContext
        )
        .padding(.horizontal)
    }
    
    // MARK: - Crosshair Controls
    
    private var crosshairControls: some View {
        VStack(spacing: 15) {
            Text("Fadenkreuz Position")
                .font(.headline)
            
            // Width slider (horizontal adjustment)
            CrosshairSlider(
                label: "W:",
                value: Binding(
                    get: { -config.crosshairOffsetY },
                    set: { config.crosshairOffsetY = -$0 }
                )
            )
            
            // Height slider (vertical adjustment)
            CrosshairSlider(
                label: "H:",
                value: Binding(
                    get: { -config.crosshairOffsetX },
                    set: { config.crosshairOffsetX = -$0 }
                )
            )
            
            Button("Zurücksetzen") {
                config.crosshairOffsetX = 0
                config.crosshairOffsetY = 0
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    // MARK: - Capture Button
    
    private var captureButton: some View {
        VStack {
            Spacer()
            Button(action: captureDistance) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 70, height: 70)
                    Circle()
                        .stroke(Color.primary, lineWidth: 3)
                        .frame(width: 80, height: 80)
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .disabled(config.centerDistance == nil)
            .opacity(config.centerDistance == nil ? 0.5 : 1.0)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Feedback Overlay
    
    private var feedbackOverlay: some View {
        VStack {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Messung gespeichert")
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
            .padding(.top, 60)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Restart Onboarding Button
    
    private var restartOnboardingButton: some View {
        Button(action: restartOnboarding) {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("Onboarding neu starten")
            }
            .font(.body)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - Toolbar
    
    private var editButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(editMode ? "Fertig" : "Bearbeiten") {
                // When entering edit mode, ensure a session is selected
                if !editMode && captureManager.currentSession == nil {
                    captureManager.restoreOrStartSession()
                }
                editMode.toggle()
            }
            .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Crosshair Position Calculation
    
    /// Converts internal offset values to screen coordinates
    /// Note: The offset values are inverted because the AR coordinate system
    /// is different from the UI coordinate system:
    /// - crosshairOffsetY (internal) maps to horizontal (X) screen movement
    /// - crosshairOffsetX (internal) maps to vertical (Y) screen movement
    /// - Negative multiplier inverts the direction to match user expectations
    private var crosshairOffset: CGSize {
        CGSize(
            width: -config.crosshairOffsetY * 375,  // Horizontal: internal Y → screen X
            height: config.crosshairOffsetX * 375   // Vertical: internal X → screen Y
        )
    }
    
    // MARK: - Actions
    
    private func setupView() {
        captureManager.setModelContext(modelContext)
        distanceRetrieval.startSession()
        
        // Always ensure a session exists on view appear
        if captureManager.currentSession == nil {
            captureManager.restoreOrStartSession()
        }
        
        // Setup volume button handler for capture
        volumeButtonHandler.onVolumeButtonPressed = {
            if !self.editMode {
                self.captureDistance()
            }
        }
        volumeButtonHandler.startListening()
    }
    
    private func captureDistance() {
        guard let distance = config.centerDistance else { return }
        captureManager.capturePoint(
            distance: distance,
            frame: distanceRetrieval.captureCurrentFrame()
        )
    }
    
    private func restartOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(false, forKey: "hasSeenIntroSteps")
        NotificationCenter.default.post(name: NSNotification.Name("RestartOnboarding"), object: nil)
    }
}

// MARK: - Subviews

struct ARViewRepresentable: UIViewRepresentable {
    let session: ARSession
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session = session
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

struct CrosshairView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary, lineWidth: 2)
                .frame(width: 30, height: 30)
            Circle()
                .fill(Color.primary.opacity(0.3))
                .frame(width: 6, height: 6)
        }
    }
}

struct CrosshairSlider: View {
    let label: String
    @Binding var value: Double
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
                .frame(width: 30)
            Slider(value: $value, in: -0.3...0.3)
            Text(String(format: "%.2f", value))
                .foregroundColor(.primary)
                .monospacedDigit()
                .frame(width: 50)
        }
    }
}

struct DistanceDisplayView: View {
    let distance: Float?
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            if isActive {
                if let distance = distance {
                    Text(String(format: "%.2f m", distance))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(distanceColor(for: distance))
                        .monospacedDigit()
                    Text("Distanz zum Mittelpunkt")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text("--")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                    Text("Warte auf Messung...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(height: 100)
    }
    
    private func distanceColor(for distance: Float) -> Color {
        if distance <= 1.0 { return .red }
        if distance <= 1.5 { return .yellow }
        return .green
    }
}

// MARK: - Volume Button Handler

/// Handles volume button presses to trigger camera shutter
/// Monitors volume changes via AVAudioSession and keeps volume constant using MPVolumeView
class VolumeButtonHandler: NSObject, ObservableObject {
    private var audioSession: AVAudioSession?
    private var volumeView: MPVolumeView?
    private var initialVolume: Float = 0.5
    var onVolumeButtonPressed: (() -> Void)?
    
    func startListening() {
        setupAudioSession()
        setupVolumeView()
        observeVolumeChanges()
    }
    
    func stopListening() {
        audioSession?.removeObserver(self, forKeyPath: "outputVolume")
        volumeView?.removeFromSuperview()
        audioSession = nil
        volumeView = nil
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Set audio session to ambient so it doesn't interfere with other audio
            try audioSession?.setCategory(.ambient, options: [])
            try audioSession?.setActive(true)
            
            // Store initial volume
            initialVolume = audioSession?.outputVolume ?? 0.5
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupVolumeView() {
        // Create hidden MPVolumeView to reset volume after button press
        // This prevents the actual system volume from changing
        volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        
        // Add to a window to make it functional (must be in view hierarchy)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(volumeView!)
        }
    }
    
    private func observeVolumeChanges() {
        audioSession?.addObserver(
            self,
            forKeyPath: "outputVolume",
            options: [.new],
            context: nil
        )
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "outputVolume" {
            // Volume button was pressed - trigger capture
            onVolumeButtonPressed?()
            
            // Reset volume to initial level to keep it constant
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                guard let self = self, let volumeView = self.volumeView else { return }
                
                // Find the slider in MPVolumeView and reset it
                if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
                    slider.value = self.initialVolume
                }
            }
        }
    }
    
    deinit {
        stopListening()
    }
}
