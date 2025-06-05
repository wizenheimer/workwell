//
//  SessionHistoryView.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import SwiftUI
import Charts
import SwiftData

struct SessionHistoryView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var viewModel: SessionHistoryViewModel
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: SessionHistoryViewModel(modelContext: modelContext))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                timeframePicker
                
                if viewModel.filteredSessions.isEmpty {
                    emptyStateView
                } else {
                    sessionListView
                }
            }
            .navigationTitle("Session History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.refreshData()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var timeframePicker: some View {
        Picker("Timeframe", selection: $viewModel.selectedTimeframe) {
            ForEach(SessionHistoryViewModel.Timeframe.allCases, id: \.self) { timeframe in
                Text(timeframe.rawValue).tag(timeframe)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .onChange(of: viewModel.selectedTimeframe) { _, _ in
            viewModel.refreshData()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("No sessions yet")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Start tracking your posture to see your history here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var sessionListView: some View {
        ScrollView {
            LazyVStack(spacing: 28) {
                SummaryCard(
                    sessionCount: viewModel.filteredSessions.count,
                    averagePoorPosture: viewModel.averagePoorPosture,
                    totalTime: viewModel.totalSessionTime
                )
                
                if viewModel.filteredSessions.count > 1 {
                    SessionChartView(sessions: viewModel.filteredSessions)
                        .frame(height: 220)
                        .padding(.horizontal, 20)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Sessions")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                    
                    ForEach(viewModel.filteredSessions) { session in
                        SessionRowView(session: session)
                            .padding(.horizontal, 20)
                            .swipeActions {
                                Button(role: .destructive) {
                                    viewModel.deleteSession(session)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.top, 8)
        }
        .refreshable {
            viewModel.refreshData()
        }
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let sessionCount: Int
    let averagePoorPosture: Int
    let totalTime: TimeInterval
    
    private var formattedTotalTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 32) {
                VStack(spacing: 6) {
                    Text("\(sessionCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 6) {
                    Text(formattedTotalTime)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Total Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 6) {
                    Text("\(averagePoorPosture)%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(postureColor(for: averagePoorPosture))
                    Text("Avg Poor")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    private func postureColor(for percentage: Int) -> Color {
        switch percentage {
        case 0...15: return .green
        case 16...30: return .orange
        default: return .red
        }
    }
}

struct SessionChartView: View {
    let sessions: [PostureSession]
    
    private var chartData: [PostureSession] {
        // Take the most recent 15 sessions and reverse for chronological order
        Array(sessions.prefix(15).reversed())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Poor Posture Trend")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            Chart(chartData) { session in
                BarMark(
                    x: .value("Date", session.startTime, unit: .day),
                    y: .value("Poor Posture %", session.poorPosturePercentage)
                )
                .foregroundStyle(barColor(for: session.poorPosturePercentage))
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(position: .bottom, values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .stride(by: 20)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)%")
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func barColor(for percentage: Int) -> Color {
        switch percentage {
        case 0...15: return .green
        case 16...30: return .orange
        default: return .red
        }
    }
}

struct SessionRowView: View {
    let session: PostureSession
    
    private var durationText: String {
        let minutes = Int(session.totalDuration / 60)
        return minutes > 0 ? "\(minutes) min" : "< 1 min"
    }
    
    private var postureGrade: String {
        switch session.poorPosturePercentage {
        case 0...15: return "Excellent"
        case 16...30: return "Good"
        case 31...50: return "Fair"
        default: return "Needs Work"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(durationText) session")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 8) {
                    Text("\(session.poorPosturePercentage)%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(postureColor(for: session.poorPosturePercentage))
                    
                    Image(systemName: postureIcon(for: session.poorPosturePercentage))
                        .foregroundColor(postureColor(for: session.poorPosturePercentage))
                        .font(.caption)
                }
                
                Text(postureGrade)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    private func postureColor(for percentage: Int) -> Color {
        switch percentage {
        case 0...15: return .green
        case 16...30: return .orange
        default: return .red
        }
    }
    
    private func postureIcon(for percentage: Int) -> String {
        switch percentage {
        case 0...15: return "checkmark.circle.fill"
        case 16...30: return "exclamationmark.triangle.fill"
        default: return "xmark.circle.fill"
        }
    }
}

#Preview {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: PostureSession.self, configurations: config)
        
        // Add sample data directly in the container creation
        let context = container.mainContext
        
        // Create sessions with proper time intervals
        let now = Date()
        let sampleSessions = [
            PostureSession(
                startTime: Calendar.current.date(byAdding: .day, value: -5, to: now)!,
                endTime: Calendar.current.date(byAdding: .day, value: -5, to: now)!.addingTimeInterval(3600),
                poorPostureDuration: 540,
                averagePitch: -10,
                minPitch: -15,
                maxPitch: -5
            ),
            PostureSession(
                startTime: Calendar.current.date(byAdding: .day, value: -3, to: now)!,
                endTime: Calendar.current.date(byAdding: .day, value: -3, to: now)!.addingTimeInterval(2700),
                poorPostureDuration: 810,
                averagePitch: -18,
                minPitch: -25,
                maxPitch: -8
            ),
            PostureSession(
                startTime: Calendar.current.date(byAdding: .day, value: -1, to: now)!,
                endTime: Calendar.current.date(byAdding: .day, value: -1, to: now)!.addingTimeInterval(1800),
                poorPostureDuration: 270,
                averagePitch: -8,
                minPitch: -12,
                maxPitch: -3
            )
        ]
        
        for session in sampleSessions {
            context.insert(session)
        }
        
        try! context.save()
        return container
    }()
    
    return SessionHistoryView(modelContext: container.mainContext)
        .modelContainer(container)
}

#Preview("Empty State") {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: PostureSession.self, configurations: config)
        return container
    }()
    
    return SessionHistoryView(modelContext: container.mainContext)
        .modelContainer(container)
}

#Preview("Single Session") {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: PostureSession.self, configurations: config)
        let context = container.mainContext
        
        let session = PostureSession(
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date(),
            poorPostureDuration: 900,
            averagePitch: -20,
            minPitch: -30,
            maxPitch: -10
        )
        
        context.insert(session)
        try! context.save()
        return container
    }()
    
    return SessionHistoryView(modelContext: container.mainContext)
        .modelContainer(container)
}

#Preview("Many Sessions") {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: PostureSession.self, configurations: config)
        let context = container.mainContext
        
        let now = Date()
        let calendar = Calendar.current
        
        // Create 15 sessions over the past month with varied data
        for i in 0..<15 {
            let daysAgo = i * 2
            let startTime = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
                .addingTimeInterval(TimeInterval.random(in: 0...86400)) // Random time of day
            
            let duration = TimeInterval.random(in: 1800...7200) // 30 min to 2 hours
            let endTime = startTime.addingTimeInterval(duration)
            
            let poorPosturePercent = Int.random(in: 5...60)
            let poorPostureDuration = duration * Double(poorPosturePercent) / 100
            
            let avgPitch = Double.random(in: -25...(-5))
            let minPitch = avgPitch - Double.random(in: 5...15)
            let maxPitch = avgPitch + Double.random(in: 2...10)
            
            let session = PostureSession(
                startTime: startTime,
                endTime: endTime,
                poorPostureDuration: poorPostureDuration,
                averagePitch: avgPitch,
                minPitch: minPitch,
                maxPitch: maxPitch
            )
            
            context.insert(session)
        }
        
        try! context.save()
        return container
    }()
    
    return SessionHistoryView(modelContext: container.mainContext)
        .modelContainer(container)
}

#Preview("Excellent Posture History") {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: PostureSession.self, configurations: config)
        let context = container.mainContext
        
        let now = Date()
        let calendar = Calendar.current
        
        // Create sessions with excellent posture (0-15% poor)
        for i in 0..<8 {
            let startTime = calendar.date(byAdding: .day, value: -i, to: now)!
                .addingTimeInterval(TimeInterval(9 * 3600)) // 9 AM each day
            
            let duration = TimeInterval(3600 + i * 300) // Increasing duration
            let endTime = startTime.addingTimeInterval(duration)
            
            let poorPosturePercent = Int.random(in: 0...15)
            let poorPostureDuration = duration * Double(poorPosturePercent) / 100
            
            let session = PostureSession(
                startTime: startTime,
                endTime: endTime,
                poorPostureDuration: poorPostureDuration,
                averagePitch: Double.random(in: -10...(-2)),
                minPitch: Double.random(in: -15...(-5)),
                maxPitch: Double.random(in: 0...5)
            )
            
            context.insert(session)
        }
        
        try! context.save()
        return container
    }()
    
    return SessionHistoryView(modelContext: container.mainContext)
        .modelContainer(container)
}

#Preview("Poor Posture History") {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: PostureSession.self, configurations: config)
        let context = container.mainContext
        
        let now = Date()
        let calendar = Calendar.current
        
        // Create sessions with poor posture (40-80% poor)
        for i in 0..<6 {
            let startTime = calendar.date(byAdding: .day, value: -i, to: now)!
                .addingTimeInterval(TimeInterval(14 * 3600)) // 2 PM each day
            
            let duration = TimeInterval.random(in: 2400...5400) // 40-90 minutes
            let endTime = startTime.addingTimeInterval(duration)
            
            let poorPosturePercent = Int.random(in: 40...80)
            let poorPostureDuration = duration * Double(poorPosturePercent) / 100
            
            let session = PostureSession(
                startTime: startTime,
                endTime: endTime,
                poorPostureDuration: poorPostureDuration,
                averagePitch: Double.random(in: -30...(-15)),
                minPitch: Double.random(in: -40...(-20)),
                maxPitch: Double.random(in: -10...(-2))
            )
            
            context.insert(session)
        }
        
        try! context.save()
        return container
    }()
    
    return SessionHistoryView(modelContext: container.mainContext)
        .modelContainer(container)
}

#Preview("Mixed Short Sessions") {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: PostureSession.self, configurations: config)
        let context = container.mainContext
        
        let now = Date()
        
        // Create many short sessions (under 30 minutes)
        let sessionTimes = [
            -3600, -7200, -10800, -14400, -18000, -86400, -90000, -93600
        ]
        
        for (index, timeOffset) in sessionTimes.enumerated() {
            let startTime = now.addingTimeInterval(TimeInterval(timeOffset))
            let duration = TimeInterval.random(in: 300...1800) // 5-30 minutes
            let endTime = startTime.addingTimeInterval(duration)
            
            let poorPosturePercent = [5, 25, 45, 15, 35, 60, 20, 10][index]
            let poorPostureDuration = duration * Double(poorPosturePercent) / 100
            
            let session = PostureSession(
                startTime: startTime,
                endTime: endTime,
                poorPostureDuration: poorPostureDuration,
                averagePitch: Double.random(in: -20...(-5)),
                minPitch: Double.random(in: -30...(-10)),
                maxPitch: Double.random(in: -2...8)
            )
            
            context.insert(session)
        }
        
        try! context.save()
        return container
    }()
    
    return SessionHistoryView(modelContext: container.mainContext)
        .modelContainer(container)
}

#Preview("Long Sessions") {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: PostureSession.self, configurations: config)
        let context = container.mainContext
        
        let now = Date()
        let calendar = Calendar.current
        
        // Create fewer but longer sessions (2+ hours)
        for i in 0..<4 {
            let startTime = calendar.date(byAdding: .day, value: -(i * 3), to: now)!
                .addingTimeInterval(TimeInterval(8 * 3600)) // 8 AM
            
            let duration = TimeInterval.random(in: 7200...14400) // 2-4 hours
            let endTime = startTime.addingTimeInterval(duration)
            
            let poorPosturePercent = [18, 32, 28, 22][i]
            let poorPostureDuration = duration * Double(poorPosturePercent) / 100
            
            let session = PostureSession(
                startTime: startTime,
                endTime: endTime,
                poorPostureDuration: poorPostureDuration,
                averagePitch: Double.random(in: -18...(-8)),
                minPitch: Double.random(in: -25...(-12)),
                maxPitch: Double.random(in: -2...5)
            )
            
            context.insert(session)
        }
        
        try! context.save()
        return container
    }()
    
    return SessionHistoryView(modelContext: container.mainContext)
        .modelContainer(container)
}

#Preview("Summary Card") {
    SummaryCard(sessionCount: 5, averagePoorPosture: 25, totalTime: 18000)
        .padding()
}

#Preview("Session Chart") {
    @Previewable @State var sampleSessions = [
        PostureSession(
            startTime: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
            endTime: Calendar.current.date(byAdding: .day, value: -6, to: Date())!.addingTimeInterval(3600),
            poorPostureDuration: 720,
            averagePitch: -15,
            minPitch: -25,
            maxPitch: -5
        ),
        PostureSession(
            startTime: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
            endTime: Calendar.current.date(byAdding: .day, value: -4, to: Date())!.addingTimeInterval(3600),
            poorPostureDuration: 900,
            averagePitch: -20,
            minPitch: -30,
            maxPitch: -10
        ),
        PostureSession(
            startTime: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            endTime: Calendar.current.date(byAdding: .day, value: -2, to: Date())!.addingTimeInterval(3600),
            poorPostureDuration: 540,
            averagePitch: -10,
            minPitch: -15,
            maxPitch: -5
        ),
        PostureSession(
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            poorPostureDuration: 360,
            averagePitch: -8,
            minPitch: -12,
            maxPitch: -3
        )
    ]
    
    return SessionChartView(sessions: sampleSessions)
        .frame(height: 200)
        .padding()
}

#Preview("Session Row") {
    @Previewable @State var sampleSession = PostureSession(
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        poorPostureDuration: 720,
        averagePitch: -15,
        minPitch: -25,
        maxPitch: -5
    )
    
    return SessionRowView(session: sampleSession)
        .padding()
}
