//
//  MeasurmentRow.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Compact row component for displaying a measurement point in lists, showing thumbnail,
//  timestamp, and distance with color coding.
//

import SwiftUI

struct MeasurementRow: View {
    let point: MeasurePoint

    var body: some View {
        HStack {
            photoThumbnail

            VStack(alignment: .leading, spacing: 2) {
                Text(point.date, style: .time)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(String(format: "%.2f m", point.measurement))
                    .font(.subheadline)
                    .foregroundColor(colorForDistance(point.measurement))
            }

            Spacer()
        }
    }

    private var photoThumbnail: some View {
        Group {
            if let photoData = point.photo, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    )
            }
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
