import SwiftUI
import Charts

struct PostureGraphView: View {
    let dataPoints: [Double]
    let currentPitch: Double
    
    private let poorThreshold = -20.0
    private let warningThreshold = -15.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pitch History")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                // Threshold lines
                poorThresholdLine
                warningThresholdLine
                
                // Data lines
                dataLines
                
                // Current point
                currentPointMark
            }
            .chartYScale(domain: -40...20)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 0))
            }
            .frame(height: 120)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Chart Components
    
    @ChartContentBuilder
    private var poorThresholdLine: some ChartContent {
        RuleMark(y: .value("Poor", poorThreshold))
            .foregroundStyle(.red.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            .annotation(position: .trailing) {
                Text("Poor")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
    }
    
    @ChartContentBuilder
    private var warningThresholdLine: some ChartContent {
        RuleMark(y: .value("Warning", warningThreshold))
            .foregroundStyle(.orange.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            .annotation(position: .trailing) {
                Text("Warning")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
    }
    
    @ChartContentBuilder
    private var dataLines: some ChartContent {
        ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, value in
            LineMark(
                x: .value("Time", index),
                y: .value("Pitch", value)
            )
            .foregroundStyle(lineColor(for: value))
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
    }
    
    @ChartContentBuilder
    private var currentPointMark: some ChartContent {
        if let lastIndex = dataPoints.indices.last,
           lastIndex < dataPoints.count {
            PointMark(
                x: .value("Time", lastIndex),
                y: .value("Pitch", dataPoints[lastIndex])
            )
            .foregroundStyle(.blue)
            .symbolSize(100)
        }
    }
    
    // MARK: - Helper Methods
    
    private func lineColor(for value: Double) -> Color {
        if value < poorThreshold {
            return .red
        } else if value < warningThreshold {
            return .orange
        } else {
            return .green
        }
    }
}

#Preview("Good Posture") {
    PostureGraphView(
        dataPoints: [-5, -8, -7, -6, -5, -4],
        currentPitch: -4
    )
}

#Preview("Warning State") {
    PostureGraphView(
        dataPoints: [-12, -14, -16, -15, -14, -13],
        currentPitch: -13
    )
}

#Preview("Poor Posture") {
    PostureGraphView(
        dataPoints: [-18, -22, -25, -23, -21, -20],
        currentPitch: -20
    )
}

#Preview("Mixed States") {
    PostureGraphView(
        dataPoints: [-5, -12, -25, -15, -8, -4],
        currentPitch: -4
    )
}
