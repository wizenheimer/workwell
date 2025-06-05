//
//  SessionHistoryViewModel.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import Foundation
import Combine

@MainActor
class SessionHistoryViewModel: ObservableObject {
    @Published var selectedTimeframe: Timeframe = .week
    @Published var isLoading = false
    
    private let dataStore: PostureDataStore
    private var cancellables = Set<AnyCancellable>()
    
    enum Timeframe: String, CaseIterable, Identifiable {
        case day = "Today"
        case week = "Week"
        case month = "Month"
        case all = "All Time"
        
        var id: String { self.rawValue }
    }
    
    init(dataStore: PostureDataStore = .shared) {
        self.dataStore = dataStore
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
    
    var totalSessionTime: TimeInterval {
        filteredSessions.reduce(0) { $0 + $1.totalDuration }
    }
    
    var bestSession: PostureSession? {
        filteredSessions.min { $0.poorPosturePercentage < $1.poorPosturePercentage }
    }
    
    var worstSession: PostureSession? {
        filteredSessions.max { $0.poorPosturePercentage < $1.poorPosturePercentage }
    }
    
    func deleteSession(_ session: PostureSession) {
        if let index = dataStore.sessions.firstIndex(where: { $0.id == session.id }) {
            dataStore.sessions.remove(at: index)
            dataStore.saveSessions()
        }
    }
    
    func exportData() -> String {
        var csv = "Date,Start Time,Duration (min),Poor Posture %,Average Pitch\n"
        
        for session in dataStore.sessions {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            
            let row = "\(dateFormatter.string(from: session.startTime)),\(Int(session.totalDuration / 60)),\(session.poorPosturePercentage),\(String(format: "%.1f", session.averagePitch))\n"
            csv += row
        }
        
        return csv
    }
}
