//
//  PostureGraphView.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import SwiftUI
import Charts

struct PostureGraphView: View {
    let dataPoints: [Double]
    let currentPitch: Double
    
    // MARK: - Constants
    
    private let goodPostureThreshold: Double = -15.0
    private let poorPostureThreshold: Double = -20.0
    private let maxDisplayPoints = 50
    
    // MARK: - Computed Properties
    
    private var chartData: [(index: Int, pitch: Double)] {
        let points = Array(dataPoints.suffix(maxDisplayPoints))
        return points.enumerated().map { (index: $0.offset, pitch: $0.element) }
    }
    
    private var yAxisRange: ClosedRange<Double> {
        let minValue = min(-30.0, dataPoints.min() ?? -30.0)
        let maxValue = max(10.0, dataPoints.max() ?? 10.0)
        return minValue...maxValue
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            if dataPoints.isEmpty {
                emptyStateView
            } else {
                chartView
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Collecting posture data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Chart View
    
    private var chartView: some View {
        Chart {
            // Good posture zone (background)
            RectangleMark(
                xStart: .value("Start", 0),
                xEnd: .value("End", maxDisplayPoints),
                yStart: .value("Good Start", goodPostureThreshold),
                yEnd: .value("Good End", yAxisRange.upperBound)
            )
            .foregroundStyle(.green.opacity(0.1))
            
            // Warning posture zone
            RectangleMark(
                xStart: .value("Start", 0),
                xEnd: .value("End", maxDisplayPoints),
                yStart: .value("Warning Start", poorPostureThreshold),
                yEnd: .value("Warning End", goodPostureThreshold)
            )
            .foregroundStyle(.orange.opacity(0.1))
            
            // Poor posture zone
            RectangleMark(
                xStart: .value("Start", 0),
                xEnd: .value("End", maxDisplayPoints),
                yStart: .value("Poor Start", yAxisRange.lowerBound),
                yEnd: .value("Poor End", poorPostureThreshold)
            )
            .foregroundStyle(.red.opacity(0.1))
            
            // Threshold lines
            RuleMark(y: .value("Good Threshold", goodPostureThreshold))
                .foregroundStyle(.green.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            
            RuleMark(y: .value("Poor Threshold", poorPostureThreshold))
                .foregroundStyle(.red.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            
            // Main data line
            ForEach(Array(chartData.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Time", point.index),
                    y: .value("Pitch", point.pitch)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [colorForPitch(point.pitch), colorForPitch(point.pitch).opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }
            
            // Current position indicator
            if let lastPoint = chartData.last {
                PointMark(
                    x: .value("Current Time", lastPoint.index),
                    y: .value("Current Pitch", lastPoint.pitch)
                )
                .foregroundStyle(colorForPitch(lastPoint.pitch))
                .symbol(.circle)
                .symbolSize(100)
            }
        }
        .chartYScale(domain: yAxisRange)
        .chartXAxis {
            AxisMarks(position: .bottom, values: .stride(by: 10)) { _ in
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: 5)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary)
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue))°")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: dataPoints.count)
    }
    
    // MARK: - Helper Methods
    
    private func colorForPitch(_ pitch: Double) -> Color {
        switch pitch {
        case let p where p < poorPostureThreshold:
            return .red
        case let p where p < goodPostureThreshold:
            return .orange
        default:
            return .green
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        // With data
        PostureGraphView(
            dataPoints: generateSampleData(),
            currentPitch: -12.5
        )
        .frame(height: 120)
        
        // Empty state
        PostureGraphView(
            dataPoints: [],
            currentPitch: 0
        )
        .frame(height: 120)
    }
    .padding()
}

// Helper function for generating sample data
private func generateSampleData() -> [Double] {
    var data: [Double] = []
    var currentValue: Double = -10
    
    for i in 0..<50 {
        // Add some randomness and trends
        let noise = Double.random(in: -2...2)
        let trend = sin(Double(i) * 0.1) * 5
        currentValue += noise + trend * 0.1
        
        // Keep within reasonable bounds
        currentValue = max(-35, min(5, currentValue))
        data.append(currentValue)
    }
    
    return data
}
