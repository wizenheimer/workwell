//
//  PostureMetricsView.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import SwiftUI

struct PostureMetricsView: View {
    let sessionDuration: TimeInterval
    let poorPostureDuration: TimeInterval
    let poorPosturePercentage: Int
    let currentPitch: Double
    
    var body: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Session Time",
                value: formatDuration(sessionDuration),
                icon: "clock",
                color: .blue
            )
            
            MetricCard(
                title: "Poor Posture",
                value: "\(poorPosturePercentage)%",
                icon: "exclamationmark.triangle",
                color: poorPosturePercentage > 30 ? .red : .green
            )
            
            MetricCard(
                title: "Current Pitch",
                value: String(format: "%.1f°", currentPitch),
                icon: "arrow.up.and.down",
                color: .purple
            )
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview("Good Posture") {
    PostureMetricsView(
        sessionDuration: 1800, // 30 minutes
        poorPostureDuration: 300, // 5 minutes
        poorPosturePercentage: 17,
        currentPitch: 0.0
    )
    .padding()
}

#Preview("Poor Posture") {
    PostureMetricsView(
        sessionDuration: 3600, // 1 hour
        poorPostureDuration: 1800, // 30 minutes
        poorPosturePercentage: 50,
        currentPitch: -15.0
    )
    .padding()
}

#Preview("Short Session") {
    PostureMetricsView(
        sessionDuration: 300, // 5 minutes
        poorPostureDuration: 60, // 1 minute
        poorPosturePercentage: 20,
        currentPitch: 5.0
    )
    .padding()
}
