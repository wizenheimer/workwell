//
//  SessionHistoryView.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import SwiftUI
import Charts

struct SessionHistoryView: View {
    @EnvironmentObject var dataStore: PostureDataStore
    @Environment(\.dismiss) var dismiss
    @State private var selectedTimeframe = Timeframe.week
    
    enum Timeframe: String, CaseIterable {
        case day = "Today"
        case week = "Week"
        case month = "Month"
        case all = "All"
    }
    
    var filteredSessions: [PostureSession] {
        let calendar = Calendar.current
        let now = Date()
        
        return dataStore.sessions.filter { session in
            switch selectedTimeframe {
            case .day:
                return calendar.isDateInToday(session.startTime)
            case .week:
                return session.startTime > calendar.date(byAdding: .day, value: -7, to: now)!
            case .month:
                return session.startTime > calendar.date(byAdding: .month, value: -1, to: now)!
            case .all:
                return true
            }
        }
    }
    
    var averagePoorPosture: Int {
        guard !filteredSessions.isEmpty else { return 0 }
        let total = filteredSessions.reduce(0) { $0 + $1.poorPosturePercentage }
        return total / filteredSessions.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Timeframe picker
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.rawValue).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if filteredSessions.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "chart.bar")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No sessions yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Summary card
                            SummaryCard(
                                sessionCount: filteredSessions.count,
                                averagePoorPosture: averagePoorPosture
                            )
                            
                            // Chart
                            SessionChartView(sessions: filteredSessions)
                                .frame(height: 200)
                                .padding(.horizontal)
                            
                            // Session list
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sessions")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(filteredSessions) { session in
                                    SessionRowView(session: session)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
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
        }
    }
}

struct SummaryCard: View {
    let sessionCount: Int
    let averagePoorPosture: Int
    
    var body: some View {
        HStack(spacing: 40) {
            VStack(spacing: 4) {
                Text("\(sessionCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("Sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("\(averagePoorPosture)%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(averagePoorPosture > 30 ? .red : .green)
                Text("Avg Poor Posture")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct SessionChartView: View {
    let sessions: [PostureSession]
    
    var body: some View {
        Chart(sessions.prefix(10)) { session in
            BarMark(
                x: .value("Date", session.startTime, unit: .day),
                y: .value("Poor %", session.poorPosturePercentage)
            )
            .foregroundStyle(
                session.poorPosturePercentage > 30 ? Color.red : Color.green
            )
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

struct SessionRowView: View {
    let session: PostureSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int(session.totalDuration / 60)) min session")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.poorPosturePercentage)%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(session.poorPosturePercentage > 30 ? .red : .green)
                
                Text("poor posture")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}
