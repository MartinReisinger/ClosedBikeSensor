//
//  SessionSelectorView.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Horizontal scrollable session selector with ability to create new sessions, switch between
//  existing sessions, and edit session names via long-press gesture.
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
                    
                    // MARK: - New Session Button
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
                    
                    // MARK: - Existing Sessions
                    ForEach(sessions.prefix(10)) { session in
                        SessionCardView(
                            session: session,
                            isSelected: captureManager.currentSession?.id == session.id,
                            isLongPressed: longPressedSessionId == session.id
                        )
                        .onTapGesture {
                            selectedSession = session
                            captureManager.switchToSession(session)
                        }
                        .onLongPressGesture(minimumDuration: 0.25, pressing: { isPressing in
                            if isPressing {
                                // Visual feedback on start
                                longPressedSessionId = session.id
                            } else {
                                // Reset when released without completion
                                if editingSession?.id != session.id {
                                    longPressedSessionId = nil
                                }
                            }
                        }, perform: {
                            // Haptic feedback after 0.35s
                            let generator = UIImpactFeedbackGenerator(style: .rigid)
                            generator.impactOccurred()
                            
                            // Show sheet
                            editingSession = session
                            showEditSessionSheet = true
                            longPressedSessionId = nil
                        })
                    }
                }
                .padding(.vertical, 8)
            }
        }
        // New Session Alert
        .alert("Neue Session", isPresented: $showNewSessionAlert) {
            TextField("Name (optional)", text: $newSessionName)
            Button("Abbrechen", role: .cancel) { newSessionName = "" }
            Button("Erstellen") { createNewSession() }
        } message: { Text("Erstelle eine neue Mess-Session") }
        // Edit Session Sheet
        .sheet(isPresented: $showEditSessionSheet, onDismiss: {
            editingSession = nil
            longPressedSessionId = nil
        }) {
            if let session = editingSession {
                EditSessionSheet(
                    session: session,
                    onDelete: {
                        modelContext.delete(session)
                        try? modelContext.save()
                        if selectedSession?.id == session.id { selectedSession = nil }
                        showEditSessionSheet = false
                    },
                    onSave: { name in
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        session.name = trimmed.isEmpty ? "Session \(session.number)" : trimmed
                        try? modelContext.save()
                        showEditSessionSheet = false
                    }
                )
            }
        }
    }
    
    private func createNewSession() {
        let nextNumber = (sessions.first?.number ?? 0) + 1
        let trimmedName = newSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "Session \(nextNumber)" : trimmedName
        let session = MeasureSession(
            number: nextNumber,
            name: finalName,
            startDate: Date()
        )
        modelContext.insert(session)
        try? modelContext.save()
        
        captureManager.switchToSession(session)
        selectedSession = session
        newSessionName = ""
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
    let onDelete: () -> Void
    let onSave: (_ name: String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var sessionName: String
    
    init(session: MeasureSession, onDelete: @escaping () -> Void, onSave: @escaping (_ name: String) -> Void) {
        self.session = session
        self.onDelete = onDelete
        self.onSave = onSave
        _sessionName = State(initialValue: session.name ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Session Info")) {
                    TextField("Name", text: $sessionName)
                    
                }
                
                Section("Details") {
                    HStack {
                        Text("Nummer")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(session.number)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Messungen")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(session.measurements.count)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Start am")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(session.startDate, formatter: dateTimeFormatter)
                                .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Ende am")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(session.endDate, formatter: dateTimeFormatter)
                                .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Löschen", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                }
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
}

private let dateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy HH:mm" // Day.Month.Year Hours:Minutes
    return formatter
}()


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
