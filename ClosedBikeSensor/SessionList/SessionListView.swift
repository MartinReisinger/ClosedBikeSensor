//
//  SessionListView.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Displays all measurement sessions with statistics, charts, and visualizations.
//  Includes aggregate session view and supports session deletion in edit mode.
//
//

import SwiftUI
import SwiftData
import Charts

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeasureSession.startDate, order: .reverse) private var allSessions: [MeasureSession]
    
    @StateObject private var config = RetrievalConfig.shared
    @ObservedObject private var captureManager: CaptureManager
    
    @State private var selectedSession: MeasureSession?
    @State private var isAggregateSession: Bool = false
    @State private var editMode: EditMode = .inactive
    
    @Binding var selectedTab: Int
    
    /// Filter out aggregate session (number == 0)
    private var realSessions: [MeasureSession] {
        allSessions.filter { $0.number != 0 }
    }
    
    // MARK: - Initialization
    
    init(selectedTab: Binding<Int>, captureManager: CaptureManager) {
        self._selectedTab = selectedTab
        self._captureManager = ObservedObject(wrappedValue: captureManager)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if realSessions.isEmpty {
                    emptyStateView
                } else {
                    sessionListView
                }
            }
            .navigationTitle("Messungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editMode == .active ? "Fertig" : "Bearbeiten") {
                        editMode = editMode == .active ? .inactive : .active
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session, isAggregateSession: isAggregateSession)
                    .modelContainer(for: [MeasureSession.self, MeasurePoint.self])
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Keine Messungen")
                .font(.title2)
                .foregroundColor(.primary)
            
            Text("Starte eine Messung, um sie in der Liste zu sehen.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: startMeasurement) {
                Text("Messung starten")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    // MARK: - Session List View
    
    private var sessionListView: some View {
        List {
            if !realSessions.isEmpty {
                aggregateSessionRow
            }
            
            ForEach(realSessions) { session in
                regularSessionRow(session)
            }
            .onDelete(perform: deleteSessions)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Aggregate Session Row
    
    private var aggregateSessionRow: some View {
        AggregateSessionCard(sessions: realSessions)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .onTapGesture {
                if editMode == .inactive {
                    selectedSession = createAggregateSession()
                    isAggregateSession = true
                }
            }
    }
    
    // MARK: - Regular Session Row
    
    private func regularSessionRow(_ session: MeasureSession) -> some View {
        SessionCard(session: session)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .onTapGesture {
                if editMode == .inactive {
                    selectedSession = session
                    isAggregateSession = false
                }
            }
    }
    
    // MARK: - Actions
    
    /// Starts a measurement by ensuring a session exists and switching to Live tab
    private func startMeasurement() {
        // Ensure capture manager has model context
        captureManager.setModelContext(modelContext)
        
        // Ensure a session exists (restore or create new)
        if captureManager.currentSession == nil {
            captureManager.restoreOrStartSession()
        }
        
        // Switch to Live tab (index 0)
        selectedTab = 0
    }
    
    /// Deletes sessions at the specified offsets
    /// Prevents deletion of the last remaining session
    private func deleteSessions(at offsets: IndexSet) {
        // CRITICAL: Cannot delete the last remaining session
        guard realSessions.count > 1 else {
            print("⚠️ Cannot delete last session")
            return
        }
        
        // Delete in descending order to avoid index shift issues
        for index in offsets.sorted(by: >) {
            let sessionToDelete = realSessions[index]
            
            // Notify capture manager if we're deleting the active session
            captureManager.handleSessionDeleted(sessionToDelete)
            
            // Delete from context
            modelContext.delete(sessionToDelete)
            
            print("✅ Deleted session: \(sessionToDelete.displayName)")
        }
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Error deleting sessions: \(error.localizedDescription)")
        }
    }
    
    /// Creates a temporary aggregate session combining all measurements
    /// This session is not persisted to the database
    private func createAggregateSession() -> MeasureSession {
        let allMeasurements = realSessions.flatMap { $0.measurements }
        
        let aggregateSession = MeasureSession(
            number: 0, // Special number to indicate aggregate
            name: "Alles",
            startDate: realSessions.last?.startDate ?? Date(),
            endDate: realSessions.first?.endDate ?? Date()
        )
        
        aggregateSession.measurements.append(contentsOf: allMeasurements)
        
        return aggregateSession
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: Float?
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            if let value = value {
                valueText(value)
            } else {
                placeholderText
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func valueText(_ value: Float) -> some View {
        Group {
            Text(String(format: "%.2f", value))
                .font(.headline)
                .foregroundColor(color)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    private var placeholderText: some View {
        Text("--")
            .font(.headline)
            .foregroundColor(.gray)
    }
}

// MARK: - Preview

#Preview {
    ListView(selectedTab: .constant(1), captureManager: CaptureManager())
        .modelContainer(for: [MeasureSession.self, MeasurePoint.self])
}
