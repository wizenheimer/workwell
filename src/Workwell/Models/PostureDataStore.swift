//
//  PostureDataStore.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import Foundation
import SwiftData
import SwiftUI

/// Manages the current posture tracking session and provides session-related operations
@Observable
@MainActor
final class PostureDataStore {
    // MARK: - Singleton
    
    static let shared = PostureDataStore()
    
    // MARK: - Properties
    
    /// The currently active session, if any
    private(set) var currentSession: PostureSession?
    
    /// The SwiftData model context for database operations
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Session Management
    
    /// Sets the model context for the data store
    /// - Parameter context: The SwiftData model context to use
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// Starts a new posture tracking session
    func startNewSession() {
        currentSession = PostureSession()
    }
    
    /// Ends the current session with the provided metrics
    /// - Parameter metrics: The metrics collected during the session
    func endSession(with metrics: SessionMetrics) {
        guard let session = currentSession,
              let context = modelContext else { return }
        
        session.endTime = Date()
        session.poorPostureDuration = metrics.poorPostureDuration
        session.averagePitch = metrics.averagePitch
        session.minPitch = metrics.minPitch
        session.maxPitch = metrics.maxPitch
        
        do {
            context.insert(session)
            try context.save()
        } catch {
            print("Failed to save session: \(error)")
        }
        
        currentSession = nil
    }
    
    /// Deletes all sessions from the database
    func clearAllSessions() {
        guard let context = modelContext else { return }
        
        do {
            try context.delete(model: PostureSession.self)
        } catch {
            print("Failed to clear sessions: \(error)")
        }
    }
}

// MARK: - Supporting Types

/// Metrics collected during a posture tracking session
struct SessionMetrics {
    /// Duration of poor posture during the session
    let poorPostureDuration: TimeInterval
    
    /// Average pitch angle during the session
    let averagePitch: Double
    
    /// Minimum pitch angle recorded during the session
    let minPitch: Double
    
    /// Maximum pitch angle recorded during the session
    let maxPitch: Double
}
