//
//  SessionHistoryViewModel.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@Observable
@MainActor
final class SessionHistoryViewModel {
    // MARK: - Properties
    
    var selectedTimeframe: Timeframe = .week
    var isLoading = false
    
    private let modelContext: ModelContext
    private var sessions: [PostureSession] = []
    
    // MARK: - Types
    
    enum Timeframe: String, CaseIterable, Identifiable {
        case day = "Today"
        case week = "Week"
        case month = "Month"
        case all = "All Time"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSessions()
    }
    
    // MARK: - Data Management
    
    func refreshData() {
        loadSessions()
    }
    
    private func loadSessions() {
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<PostureSession>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            sessions = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load sessions: \(error)")
            sessions = []
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    var filteredSessions: [PostureSession] {
        let calendar = Calendar.current
        let now = Date()
        
        return sessions.filter { session in
            switch selectedTimeframe {
            case .day:
                return calendar.isDateInToday(session.startTime)
            case .week:
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
                return session.startTime >= weekAgo
            case .month:
                guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
                return session.startTime >= monthAgo
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
    
    var totalSessionTime: TimeInterval {
        filteredSessions.reduce(0) { $0 + $1.totalDuration }
    }
    
    var bestSession: PostureSession? {
        filteredSessions.min { $0.poorPosturePercentage < $1.poorPosturePercentage }
    }
    
    var worstSession: PostureSession? {
        filteredSessions.max { $0.poorPosturePercentage < $1.poorPosturePercentage }
    }
    
    // MARK: - Computed Statistics
    
    var averageSessionDuration: TimeInterval {
        guard !filteredSessions.isEmpty else { return 0 }
        return totalSessionTime / Double(filteredSessions.count)
    }
    
    var improvementTrend: String {
        guard filteredSessions.count >= 2 else { return "Not enough data" }
        
        let recentSessions = Array(filteredSessions.prefix(5))
        let olderSessions = Array(filteredSessions.dropFirst(5).prefix(5))
        
        guard !recentSessions.isEmpty && !olderSessions.isEmpty else { return "Not enough data" }
        
        let recentAvg = recentSessions.reduce(0) { $0 + $1.poorPosturePercentage } / recentSessions.count
        let olderAvg = olderSessions.reduce(0) { $0 + $1.poorPosturePercentage } / olderSessions.count
        
        let difference = olderAvg - recentAvg
        
        if difference > 5 {
            return "Improving"
        } else if difference < -5 {
            return "Declining"
        } else {
            return "Stable"
        }
    }
    
    // MARK: - Actions
    
    func deleteSession(_ session: PostureSession) {
        modelContext.delete(session)
        
        do {
            try modelContext.save()
            loadSessions() // Reload sessions after deletion
        } catch {
            print("Failed to delete session: \(error)")
        }
    }
    
    func deleteAllSessions() {
        for session in sessions {
            modelContext.delete(session)
        }
        
        do {
            try modelContext.save()
            loadSessions()
        } catch {
            print("Failed to delete all sessions: \(error)")
        }
    }
    
    func exportData() -> String {
        var csv = "Date,Start Time,End Time,Duration (min),Poor Posture Duration (min),Poor Posture %,Average Pitch,Min Pitch,Max Pitch\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        for session in sessions {
            let startTimeString = dateFormatter.string(from: session.startTime)
            let endTimeString = dateFormatter.string(from: session.endTime)
            let durationMinutes = Int(session.totalDuration / 60)
            let poorPostureMinutes = Int(session.poorPostureDuration / 60)
            
            let row = "\"\(startTimeString)\",\"\(endTimeString)\",\(durationMinutes),\(poorPostureMinutes),\(session.poorPosturePercentage),\(String(format: "%.1f", session.averagePitch)),\(String(format: "%.1f", session.minPitch)),\(String(format: "%.1f", session.maxPitch))\n"
            csv += row
        }
        
        return csv
    }
    
    // MARK: - Helper Methods
    
    func sessionsForTimeframe(_ timeframe: Timeframe) -> [PostureSession] {
        let calendar = Calendar.current
        let now = Date()
        
        return sessions.filter { session in
            switch timeframe {
            case .day:
                return calendar.isDateInToday(session.startTime)
            case .week:
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
                return session.startTime >= weekAgo
            case .month:
                guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
                return session.startTime >= monthAgo
            case .all:
                return true
            }
        }
    }
    
    func getSessionsByDay() -> [Date: [PostureSession]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredSessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
    }
}
