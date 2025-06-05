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
    
    // MARK: - Computed Properties
    
    private var goodPostureDuration: TimeInterval {
        sessionDuration - poorPostureDuration
    }
    
    private var formattedSessionDuration: String {
        formatDuration(sessionDuration)
    }
    
    private var formattedPoorPostureDuration: String {
        formatDuration(poorPostureDuration)
    }
    
    private var formattedGoodPostureDuration: String {
        formatDuration(goodPostureDuration)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress ring
            progressRing
            
            // Metrics grid
            metricsGrid
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
    
    // MARK: - Progress Ring
    
    private var progressRing: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(.tertiarySystemBackground), lineWidth: 12)
                .frame(width: 120, height: 120)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(poorPosturePercentage) / 100)
                .stroke(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: poorPosturePercentage)
            
            // Center content
            VStack(spacing: 4) {
                Text("\(poorPosturePercentage)%")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("Poor Posture")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var gradientColors: [Color] {
        switch poorPosturePercentage {
        case 0...15:
            return [.green, .green.opacity(0.7)]
        case 16...30:
            return [.orange, .yellow]
        default:
            return [.red, .red.opacity(0.7)]
        }
    }
    
    // MARK: - Metrics Grid
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Session Time",
                value: formattedSessionDuration,
                icon: "clock",
                color: .blue
            )
            
            MetricCard(
                title: "Good Posture",
                value: formattedGoodPostureDuration,
                icon: "checkmark.circle",
                color: .green
            )
            
            MetricCard(
                title: "Poor Posture",
                value: formattedPoorPostureDuration,
                icon: "exclamationmark.circle",
                color: poorPosturePercentage > 30 ? .red : .orange
            )
            
            MetricCard(
                title: "Current Angle",
                value: String(format: "%.1f°", currentPitch),
                icon: "angle",
                color: postureColor(for: currentPitch)
            )
        }
    }
    
    private func postureColor(for pitch: Double) -> Color {
        switch pitch {
        case let p where p < -20:
            return .red
        case let p where p < -15:
            return .orange
        default:
            return .green
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    PostureMetricsView(
        sessionDuration: 3665, // 1 hour, 1 minute, 5 seconds
        poorPostureDuration: 550, // 9 minutes, 10 seconds
        poorPosturePercentage: 15,
        currentPitch: -12.5
    )
    .padding()
}