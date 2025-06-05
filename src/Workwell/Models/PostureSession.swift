//
//  PostureSession.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import Foundation
import SwiftData

@Model
final class PostureSession {
    // MARK: - Properties
    
    /// Unique identifier for the session
    var id: UUID
    
    /// When the session started
    var startTime: Date
    
    /// When the session ended
    var endTime: Date
    
    /// Duration of poor posture during the session
    var poorPostureDuration: TimeInterval
    
    /// Average pitch angle during the session
    var averagePitch: Double
    
    /// Minimum pitch angle recorded during the session
    var minPitch: Double
    
    /// Maximum pitch angle recorded during the session
    var maxPitch: Double
    
    // MARK: - Computed Properties
    
    /// Total duration of the session
    var totalDuration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    /// Duration of good posture during the session
    var goodPostureDuration: TimeInterval {
        totalDuration - poorPostureDuration
    }
    
    /// Percentage of time spent in poor posture
    var poorPosturePercentage: Int {
        guard totalDuration > 0 else { return 0 }
        return Int((poorPostureDuration / totalDuration) * 100)
    }
    
    // MARK: - Initialization
    
    init(startTime: Date = Date(),
         endTime: Date = Date(),
         poorPostureDuration: TimeInterval = 0,
         averagePitch: Double = 0,
         minPitch: Double = 0,
         maxPitch: Double = 0) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.poorPostureDuration = poorPostureDuration
        self.averagePitch = averagePitch
        self.minPitch = minPitch
        self.maxPitch = maxPitch
    }
}
