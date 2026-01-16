//
//  SessionDetail.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Detailed view of a single session showing statistics, distance trend chart, and sortable
//  list of all measurement points. Supports editing session name and deleting measurements.
//

import SwiftUI
import Charts
import SwiftData

struct SessionDetailView: View {
    let session: MeasureSession
    let isAggregateSession: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode

    @State private var sortAscending = false
    @State private var sortByDistance = true // true = Distance, false = Timestamp

    var body: some View {
        NavigationStack {
            List {
                statsSummarySection

                if !session.measurements.isEmpty {
                    chartSection
                }

                measurementsSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    titleView
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if !isAggregateSession { EditButton() }
                }
            }
        }
    }

    private var titleView: some View {
        Group {
            if editMode?.wrappedValue == .active && !isAggregateSession {
                TextField("Session Name", text: sessionNameBinding)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
            } else {
                Text(session.name ?? "Session \(session.number)")
                    .font(.headline)
            }
        }
    }

    private var sessionNameBinding: Binding<String> {
        Binding(
            get: { session.name ?? "Session \(session.number)" },
            set: { newValue in
                session.name = newValue.isEmpty ? nil : newValue
                try? modelContext.save()
            }
        )
    }

    private var statsSummarySection: some View {
        Section {
            VStack(spacing: 15) {
                statsRow
                countersRow
            }
            .padding(.vertical)
        }
        .listRowBackground(Color.gray.opacity(0.2))
    }

    private var statsRow: some View {
        HStack(spacing: 20) {
            StatItem(title: "Min", value: session.minDistance, unit: "m", color: .red)
            StatItem(title: "Median", value: session.medianDistance, unit: "m", color: .orange)
            StatItem(title: "Ø", value: session.averageDistance, unit: "m", color: .yellow)
            StatItem(title: "Max", value: session.maxDistance, unit: "m", color: .green)
        }
    }

    private var countersRow: some View {
        HStack {
            counterItem(value: "\(session.measurements.count)", label: "Messungen")
            counterItem(value: String(format: "%.2f km", session.totalDistance / 1000), label: "Strecke")
        }
    }

    private func counterItem(value: String, label: String) -> some View {
        VStack {
            Text(value).font(.title).foregroundColor(.primary)
            Text(label).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private var chartSection: some View {
        Section("Distanzverlauf") { detailChart }
            .listRowBackground(Color.gray.opacity(0.2))
    }

    private var detailChart: some View {
        Chart {
            ForEach(Array(sortedMeasurements.enumerated()), id: \.element.id) { index, point in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Distance", point.measurement)
                )
                .foregroundStyle(.blue)

                AreaMark(
                    x: .value("Index", index),
                    y: .value("Distance", point.measurement)
                )
                .foregroundStyle(.blue.opacity(0.3))
            }

            RuleMark(y: .value("1.5m", 1.5))
                .foregroundStyle(.yellow.opacity(0.5))
                .lineStyle(StrokeStyle(dash: [5]))
        }
        .frame(height: 200)
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel().foregroundStyle(.gray)
            }
        }
    }

    private var measurementsSection: some View {
        Section {
            ForEach(sortedMeasurements, id: \.id) { point in
                NavigationLink(destination: MeasurementDetailView(point: point)) {
                    MeasurementRow(point: point)
                }
            }
            .onDelete(perform: isAggregateSession ? { _ in } : deletePoints)
        } header: {
            measurementsSectionHeader
        }
    }

    private var measurementsSectionHeader: some View {
        HStack(spacing: 15) {
            Text("Messpunkte")
            Spacer()

            // Toggle 1: Distance / Timestamp
            Button(action: { sortByDistance.toggle() }) {
                Image(systemName: sortByDistance ? "ruler" : "clock")
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())

            // Toggle 2: ascending / descending
            Button(action: { sortAscending.toggle() }) {
                Image(systemName: "arrow.up.arrow.down")
                    .scaleEffect(x: 1, y: sortAscending ? 1 : -1)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var sortedMeasurements: [MeasurePoint] {
        let base: [MeasurePoint]
        if sortByDistance {
            base = session.measurements.sorted { $0.measurement < $1.measurement }
        } else {
            base = session.measurements.sorted { $0.date < $1.date }
        }
        return sortAscending ? base : base.reversed()
    }

    private func deletePoints(at offsets: IndexSet) {
        guard !isAggregateSession else { return }
        let toDelete = offsets.sorted(by: >).compactMap { sortedMeasurements[$0] }
        for measurement in toDelete {
            if let idx = session.measurements.firstIndex(where: { $0.id == measurement.id }) {
                session.measurements.remove(at: idx)
            }
            modelContext.delete(measurement)
        }
        withAnimation { try? modelContext.save() }
    }
}
