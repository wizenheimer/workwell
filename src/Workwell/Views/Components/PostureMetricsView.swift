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
