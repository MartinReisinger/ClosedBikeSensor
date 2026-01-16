//
//  ListView.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Displays all measurement sessions with statistics, charts, and visualizations.
//  Includes aggregate session view and supports session deletion in edit mode.
//

import SwiftUI
import SwiftData
import Charts

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeasureSession.startDate, order: .reverse) private var sessions: [MeasureSession]
    @StateObject private var config = RetrievalConfig.shared
    @State private var selectedSession: MeasureSession?
    @State private var isAggregateSession: Bool = false
    @State private var editMode: EditMode = .inactive
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ZStack {
                if sessions.isEmpty {
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
                    .modelContainer(for: [MeasureSession.self, MeasurePoint.self]) // in case Sheet needs separate Container
            }
        }
    }

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

            Button(action: { selectedTab = 0 }) {
                Text("Messung starten")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }

    private var sessionListView: some View {
        List {
            if !sessions.isEmpty {
                aggregateSessionRow
            }

            ForEach(sessions) { session in
                regularSessionRow(session)
            }
            .onDelete(perform: deleteSessions)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var aggregateSessionRow: some View {
        AggregateSessionCard(sessions: sessions)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .onTapGesture {
                if editMode == .inactive {
                    selectedSession = createAggregateSession()
                    isAggregateSession = true
                }
            }
    }

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

    private func deleteSessions(at offsets: IndexSet) {
        // delete in descending order to avoid index shift issues
        for index in offsets.sorted(by: >) {
            modelContext.delete(sessions[index])
        }
        try? modelContext.save()
    }

    private func createAggregateSession() -> MeasureSession {
        let allMeasurements = sessions.flatMap { $0.measurements }
        let aggregateSession = MeasureSession(
            number: 0,
            name: "Alles",
            startDate: sessions.last?.startDate ?? Date(),
            endDate: sessions.first?.endDate ?? Date()
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

#Preview {
    ListView(selectedTab: .constant(1))
        .modelContainer(for: [MeasureSession.self, MeasurePoint.self])
}
