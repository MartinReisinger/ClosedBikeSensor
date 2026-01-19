//
//  SessionSelectorView.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Horizontal scrollable session selector with ability to create new sessions, switch between
//  existing sessions, and edit session names via long-press gesture.
//
//

import SwiftUI
import SwiftData

struct SessionSelectorView: View {
    let sessions: [MeasureSession]
    @Binding var selectedSession: MeasureSession?
    @ObservedObject var captureManager: CaptureManager
    let modelContext: ModelContext
    
    @State private var showNewSessionAlert = false
    @State private var newSessionName = ""
    
    @State private var showEditSessionSheet = false
    @State private var editingSession: MeasureSession?
    @State private var longPressedSessionId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session wählen")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    newSessionButton
                    existingSessionsList
                }
                .padding(.vertical, 8)
            }
        }
        .alert("Neue Session", isPresented: $showNewSessionAlert) {
            TextField("Name (optional)", text: $newSessionName)
            Button("Abbrechen", role: .cancel) { newSessionName = "" }
            Button("Erstellen") { createNewSession() }
        } message: {
            Text("Erstelle eine neue Mess-Session")
        }
        .sheet(isPresented: $showEditSessionSheet, onDismiss: {
            editingSession = nil
            longPressedSessionId = nil
        }) {
            if let session = editingSession {
                EditSessionSheet(
                    session: session,
                    sessionsCount: sessions.count,
                    onDelete: {
                        deleteSession(session)
                    },
                    onSave: { name in
                        saveSessionName(session: session, name: name)
                    }
                )
            }
        }
    }
    
    // MARK: - New Session Button
    
    private var newSessionButton: some View {
        Button {
            showNewSessionAlert = true
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Text("Neu")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .frame(width: 100, height: 100)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(16)
            .shadow(radius: 1)
        }
    }
    
    // MARK: - Existing Sessions List
    
    private var existingSessionsList: some View {
        ForEach(sessions.prefix(10)) { session in
            SessionCardView(
                session: session,
                isSelected: captureManager.currentSession?.id == session.id,
                isLongPressed: longPressedSessionId == session.id
            )
            .onTapGesture {
                selectSession(session)
            }
            .onLongPressGesture(minimumDuration: 0.25, pressing: { isPressing in
                handleLongPressChange(isPressing: isPressing, session: session)
            }, perform: {
                showEditSheet(for: session)
            })
        }
    }
    
    // MARK: - Actions
    
    /// Selects a session and switches the capture manager to it
    private func selectSession(_ session: MeasureSession) {
        selectedSession = session
        captureManager.switchToSession(session)
    }
    
    /// Creates a new session with the next sequential number
    private func createNewSession() {
        // Get next session number
        let nextNumber = (sessions.map(\.number).max() ?? 0) + 1
        
        // Trim and validate name
        let trimmedName = newSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "Session \(nextNumber)" : trimmedName
        
        // Create session
        let session = MeasureSession(
            number: nextNumber,
            name: finalName,
            startDate: Date()
        )
        
        modelContext.insert(session)
        
        do {
            try modelContext.save()
            
            // Switch to new session
            captureManager.switchToSession(session)
            selectedSession = session
            
            // Reset form
            newSessionName = ""
            
            print("✅ Created new session: \(session.displayName)")
        } catch {
            print("❌ Error creating session: \(error.localizedDescription)")
        }
    }
    
    /// Saves the edited session name
    private func saveSessionName(session: MeasureSession, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Never allow empty names - fallback to "Session N"
        session.name = trimmed.isEmpty ? "Session \(session.number)" : trimmed
        
        do {
            try modelContext.save()
            showEditSessionSheet = false
            print("✅ Updated session name: \(session.displayName)")
        } catch {
            print("❌ Error saving session name: \(error.localizedDescription)")
        }
    }
    
    /// Deletes a session (prevents deletion of last session)
    private func deleteSession(_ session: MeasureSession) {
        // CRITICAL: Cannot delete the last remaining session
        guard sessions.count > 1 else {
            print("⚠️ Cannot delete last session")
            return
        }
        
        // Notify capture manager that session is being deleted
        captureManager.handleSessionDeleted(session)
        
        // Delete from context
        modelContext.delete(session)
        
        do {
            try modelContext.save()
            
            // Clear selected session if it was deleted
            if selectedSession?.id == session.id {
                selectedSession = nil
            }
            
            showEditSessionSheet = false
            print("✅ Deleted session: \(session.displayName)")
        } catch {
            print("❌ Error deleting session: \(error.localizedDescription)")
        }
    }
    
    /// Shows the edit sheet for a session
    private func showEditSheet(for session: MeasureSession) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
        
        // Show sheet
        editingSession = session
        showEditSessionSheet = true
        longPressedSessionId = nil
    }
    
    /// Handles long press state changes for visual feedback
    private func handleLongPressChange(isPressing: Bool, session: MeasureSession) {
        if isPressing {
            // Visual feedback on start
            longPressedSessionId = session.id
        } else {
            // Reset when released without completion
            if editingSession?.id != session.id {
                longPressedSessionId = nil
            }
        }
    }
}

// MARK: - Session Card View

private struct SessionCardView: View {
    let session: MeasureSession
    let isSelected: Bool
    let isLongPressed: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Text("\(session.number)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(session.displayName)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
            
            HStack(spacing: 4) {
                Image(systemName: "list.bullet")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
                Text("\(session.measurements.count)")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
            }
            .foregroundColor(.secondary)
        }
        .foregroundColor(isSelected ? .primary : .secondary)
        .frame(width: 100, height: 100)
        .background(isSelected ? Color.blue : Color.gray.opacity(0.15))
        .cornerRadius(16)
        .shadow(radius: 1)
        .scaleEffect(isLongPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLongPressed)
    }
}

// MARK: - Edit Session Sheet

private struct EditSessionSheet: View {
    let session: MeasureSession
    let sessionsCount: Int
    let onDelete: () -> Void
    let onSave: (_ name: String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var sessionName: String
    
    init(session: MeasureSession, sessionsCount: Int, onDelete: @escaping () -> Void, onSave: @escaping (_ name: String) -> Void) {
        self.session = session
        self.sessionsCount = sessionsCount
        self.onDelete = onDelete
        self.onSave = onSave
        
        // Initialize with current name or default
        _sessionName = State(initialValue: session.name ?? "Session \(session.number)")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                sessionInfoSection
                detailsSection
                deleteSection
            }
            .navigationTitle("Session bearbeiten")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        onSave(sessionName)
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Session Info Section
    
    private var sessionInfoSection: some View {
        Section(header: Text("Session Info")) {
            TextField("Name", text: $sessionName)
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        Section("Details") {
            DetailRow(label: "Nummer", value: "\(session.number)")
            DetailRow(label: "Messungen", value: "\(session.measurements.count)")
            DetailRow(label: "Start am", value: session.startDate, formatter: dateTimeFormatter)
            DetailRow(label: "Ende am", value: session.endDate, formatter: dateTimeFormatter)
        }
    }
    
    // MARK: - Delete Section
    
    private var deleteSection: some View {
        Section {
            Button("Löschen", role: .destructive) {
                onDelete()
                dismiss()
            }
            .disabled(sessionsCount <= 1) // Prevent deletion of last session
        }
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let label: String
    let value: String
    
    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    init(label: String, value: Date?, formatter: DateFormatter) {
        self.label = label
        if let value = value {
            self.value = formatter.string(from: value)
        } else {
            self.value = "—"
        }
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Date Formatter

private let dateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy HH:mm"
    return formatter
}()

// MARK: - Preview

#Preview {
    let mockSession = MeasureSession(number: 1, name: "Test Session", startDate: Date())
    let mockCaptureManager = CaptureManager()
    return SessionSelectorView(
        sessions: [mockSession],
        selectedSession: .constant(nil),
        captureManager: mockCaptureManager,
        modelContext: try! ModelContainer(for: MeasureSession.self).mainContext
    )
    .background(Color.primary.opacity(0.01))
}
