//
//  PostureDataStore.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import Foundation
import Combine

class PostureDataStore: ObservableObject {
    static let shared = PostureDataStore()
    
    @Published var sessions: [PostureSession] = []
    @Published var currentSession: PostureSession?
    
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "posture_sessions"
    
    init() {
        loadSessions()
    }
    
    func startNewSession() {
        currentSession = PostureSession()
    }
    
    func endSession(with metrics: SessionMetrics) {
        guard var session = currentSession else { return }
        
        session.endTime = Date()
        session.poorPostureDuration = metrics.poorPostureDuration
        session.averagePitch = metrics.averagePitch
        session.minPitch = metrics.minPitch
        session.maxPitch = metrics.maxPitch
        
        sessions.insert(session, at: 0)
        saveSessions()
        currentSession = nil
    }
    
    func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: sessionsKey)
        }
    }
    
    private func loadSessions() {
        if let data = userDefaults.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([PostureSession].self, from: data) {
            sessions = decoded
        }
    }
    
    func clearAllSessions() {
        sessions.removeAll()
        userDefaults.removeObject(forKey: sessionsKey)
    }
}

struct SessionMetrics {
    let poorPostureDuration: TimeInterval
    let averagePitch: Double
    let minPitch: Double
    let maxPitch: Double
}
