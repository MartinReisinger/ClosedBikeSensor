//
//  PermissionCard.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Reusable card component for displaying permission status with icon, title, description,
//  and visual status indicator (granted, not granted, or not available).
//

import SwiftUI
import AVFoundation
import ARKit
import CoreLocation

struct PermissionCard: View {
    enum Status {
        case granted, notGranted, notAvailable
    }
    
    let icon: String
    let title: String
    let description: String
    let status: Status
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(statusColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.title3)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .granted: return .green
        case .notGranted: return .orange
        case .notAvailable: return .red
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .granted: return "checkmark.circle.fill"
        case .notGranted: return "exclamationmark.circle.fill"
        case .notAvailable: return "xmark.circle.fill"
        }
    }
}
