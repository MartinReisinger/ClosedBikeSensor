//
//  AggregateSessionCard.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Card component displaying aggregated statistics from all sessions combined.
//  Shows combined measurements, statistics, and total distance across all sessions.
//
import SwiftUI
import Charts

struct AggregateSessionCard: View {
    let sessions: [MeasureSession]

    var allMeasurements: [MeasurePoint] {
        sessions.flatMap { $0.measurements }
    }

    var minDistance: Float? {
        allMeasurements.map(\.measurement).min()
    }

    var medianDistance: Float? {
        let sorted = allMeasurements.map(\.measurement).sorted()
        guard !sorted.isEmpty else { return nil }
        let mid = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }

    var averageDistance: Float? {
        let sorted = allMeasurements.map(\.measurement).sorted()
        guard !sorted.isEmpty else { return nil }
        let sum = sorted.reduce(0, +)
        return sum / Float(sorted.count)
    }

    var maxDistance: Float? {
        allMeasurements.map(\.measurement).max()
    }

    var totalDistance: Float {
        guard allMeasurements.count > 1 else { return 0 }
        var total: Float = 0
        let sorted = allMeasurements.sorted { $0.date < $1.date }
        for i in 0..<(sorted.count - 1) {
            let point1 = sorted[i]
            let point2 = sorted[i + 1]
            let dx = point2.longitude - point1.longitude
            let dy = point2.latitude - point1.latitude
            let squareRoute = sqrt(dx * dx + dy * dy)
            total += Float(squareRoute) * 111000
        }
        return total
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection

            Divider()
                .background(Color.gray.opacity(0.3))

            statsSection

            if !allMeasurements.isEmpty {
                chartSection
            }

            footerSection
        }
        .padding()
        .background(Color.blue.opacity(0.2))
        .cornerRadius(15)
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: "square.stack.3d.up.fill")
                .foregroundColor(.blue)
            Text("Alles")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
            Text("\(allMeasurements.count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
    }

    private var statsSection: some View {
        HStack(spacing: 20) {
            StatItem(title: "Min", value: minDistance, unit: "m", color: .red)
            StatItem(title: "Median", value: medianDistance, unit: "m", color: .orange)
            StatItem(title: "Ø", value: averageDistance, unit: "m", color: .yellow)
            StatItem(title: "Max", value: maxDistance, unit: "m", color: .green)
        }
    }

    private var chartSection: some View {
        Chart {
            ForEach(Array(allMeasurements.enumerated()), id: \.element.id) { index, point in
                BarMark(
                    x: .value("Index", index),
                    y: .value("Distance", point.measurement)
                )
                .foregroundStyle(colorForDistance(point.measurement))
            }
        }
        .frame(height: 80)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                    .foregroundStyle(.gray)
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .padding(.leading, 10)
        }
        .padding(.leading, 8)
    }

    private var footerSection: some View {
        HStack {
            Label("\(sessions.count) Sessions", systemImage: "folder.fill")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()

            Label(String(format: "%.2f km", totalDistance / 1000), systemImage: "location")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private func colorForDistance(_ distance: Float) -> Color {
        if distance <= 1.0 {
            return .red
        } else if distance <= 1.5 {
            return .yellow
        } else {
            return .green
        }
    }
}
