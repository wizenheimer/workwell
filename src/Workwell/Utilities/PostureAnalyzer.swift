//
//  PostureAnalyzer.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import Foundation
import CoreMotion

class PostureAnalyzer {
    static let shared = PostureAnalyzer()
    
    private let poorPostureThreshold: Double = -20.0
    private let warningThreshold: Double = -15.0
    
    func analyzePosture(pitch: Double) -> PostureAnalysis {
        let quality: PostureQuality
        let recommendation: String
        
        if pitch < poorPostureThreshold {
            quality = .poor
            recommendation = "Lift your chin up and straighten your neck"
        } else if pitch < warningThreshold {
            quality = .warning
            recommendation = "Your posture is declining, adjust your position"
        } else {
            quality = .good
            recommendation = "Great posture! Keep it up"
        }
        
        return PostureAnalysis(
            quality: quality,
            pitch: pitch,
            recommendation: recommendation
        )
    }
    
    func calculateSessionScore(session: PostureSession) -> Int {
        // Score from 0-100 based on posture quality
        let baseScore = 100 - session.poorPosturePercentage
        
        // Bonus points for longer sessions with good posture
        let durationBonus = min(Int(session.totalDuration / 600), 10) // Max 10 points for 100+ minutes
        
        return min(baseScore + durationBonus, 100)
    }
}

struct PostureAnalysis {
    let quality: PostureQuality
    let pitch: Double
    let recommendation: String
}

enum PostureQuality {
    case good
    case warning
    case poor
}
