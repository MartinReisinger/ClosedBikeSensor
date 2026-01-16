//
//  SessionCard.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Reusable card component displaying session information including statistics (min, median,
//  average, max), measurement count, bar chart visualization, duration, and total distance.
//

import SwiftUI
import Charts

struct SessionCard: View {
    let session: MeasureSession

    // Use a stable, sorted representation for display
    private var sortedMeasurements: [MeasurePoint] {
        session.measurements.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection

            Divider()
                .background(Color.gray.opacity(0.3))

            statsSection

            if !session.measurements.isEmpty {
                chartSection
            }

            footerSection
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name ?? "Session \(session.number)")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(session.startDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.measurements.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("Messungen")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 20) {
            StatItem(title: "Min", value: session.minDistance, unit: "m", color: .red)
            StatItem(title: "Median", value: session.medianDistance, unit: "m", color: .orange)
            StatItem(title: "Ø", value: session.averageDistance, unit: "m", color: .yellow)
            StatItem(title: "Max", value: session.maxDistance, unit: "m", color: .green)
        }
    }

    private var chartSection: some View {
        Chart {
            ForEach(Array(sortedMeasurements.enumerated()), id: \.element.id) { index, point in
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
            Label(formatDuration(session.duration), systemImage: "clock")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()

            Label(String(format: "%.2f km", session.totalDistance / 1000), systemImage: "location")
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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
