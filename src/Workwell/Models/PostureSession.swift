//
//  PostureSession.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import Foundation

struct PostureSession: Identifiable, Codable {
    var id = UUID()
    let startTime: Date
    var endTime: Date
    var totalDuration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    var poorPostureDuration: TimeInterval
    var goodPostureDuration: TimeInterval {
        totalDuration - poorPostureDuration
    }
    var poorPosturePercentage: Int {
        guard totalDuration > 0 else { return 0 }
        return Int((poorPostureDuration / totalDuration) * 100)
    }
    var averagePitch: Double
    var minPitch: Double
    var maxPitch: Double
    
    init(startTime: Date = Date(),
         endTime: Date = Date(),
         poorPostureDuration: TimeInterval = 0,
         averagePitch: Double = 0,
         minPitch: Double = 0,
         maxPitch: Double = 0) {
        self.startTime = startTime
        self.endTime = endTime
        self.poorPostureDuration = poorPostureDuration
        self.averagePitch = averagePitch
        self.minPitch = minPitch
        self.maxPitch = maxPitch
    }
}
