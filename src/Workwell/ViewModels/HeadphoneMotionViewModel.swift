import Foundation
import CoreMotion
import Combine
import SwiftUI

@MainActor
class HeadphoneMotionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    @Published var yaw: Double = 0
    @Published var isConnected = false
    @Published var connectionStatus = "Not Connected"
    @Published var postureQuality: PostureQuality = .good
    @Published var pitchHistory: [Double] = []
    @Published var poorPostureDuration: TimeInterval = 0
    @Published var sessionDuration: TimeInterval = 0
    @Published var poorPosturePercentage: Int = 0
    
    // MARK: - Private Properties
    private let motionManager = CMHeadphoneMotionManager()
    private var updateTimer: Timer?
    private var sessionTimer: Timer?
    private var poorPostureStartTime: Date?
    private var sessionStartTime = Date()
    private var pitchSum: Double = 0
    private var pitchCount: Int = 0
    private var minPitch: Double = 0
    private var maxPitch: Double = 0
    private var lastPoorPostureCheck: Date?
    
    // MARK: - Constants
    private let poorPostureThreshold: Double = -20.0
    private let warningThreshold: Double = -15.0
    private let maxHistoryPoints = 100
    private let updateInterval: TimeInterval = 1.0/30.0 // 30 FPS
    
    // MARK: - Posture Quality
    enum PostureQuality {
        case good
        case warning
        case poor
        
        var color: Color {
            switch self {
            case .good: return .green
            case .warning: return .orange
            case .poor: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .good: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .poor: return "xmark.circle.fill"
            }
        }
        
        var message: String {
            switch self {
            case .good: return "Good posture"
            case .warning: return "Posture declining"
            case .poor: return "Poor posture detected"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        setupMotionUpdates()
    }
    
    deinit {
        // Clean up resources directly without capturing self
        motionManager.stopDeviceMotionUpdates()
        updateTimer?.invalidate()
        sessionTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    func startTracking() {
        guard motionManager.isDeviceMotionAvailable else {
            connectionStatus = "AirPods Pro not available"
            return
        }
        
        resetSession()
        connectionStatus = "Connecting..."
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self else { return }
            
            if let error = error {
                self.connectionStatus = "Error: \(error.localizedDescription)"
                self.isConnected = false
                return
            }
            
            guard let motion = motion else { return }
            self.processMotionData(motion)
        }
        
        // Start session timer with Task wrapper for MainActor
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateSessionMetrics()
            }
        }
    }
    
    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
        updateTimer?.invalidate()
        sessionTimer?.invalidate()
        
        if isConnected {
            saveSession()
        }
        
        isConnected = false
        connectionStatus = "Disconnected"
    }
    
    func resetSession() {
        pitchHistory.removeAll()
        poorPostureDuration = 0
        sessionDuration = 0
        poorPosturePercentage = 0
        poorPostureStartTime = nil
        lastPoorPostureCheck = nil
        sessionStartTime = Date()
        pitchSum = 0
        pitchCount = 0
        minPitch = 0
        maxPitch = 0
        PostureDataStore.shared.startNewSession()
    }
    
    // MARK: - Private Methods
    private func setupMotionUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkConnectionStatus()
            }
        }
    }
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        let newPitch = motion.attitude.pitch * 180 / .pi
        let newRoll = motion.attitude.roll * 180 / .pi
        let newYaw = motion.attitude.yaw * 180 / .pi
        
        // Apply low-pass filter for smoother values
        pitch = pitch * 0.8 + newPitch * 0.2
        roll = roll * 0.8 + newRoll * 0.2
        yaw = yaw * 0.8 + newYaw * 0.2
        
        isConnected = true
        connectionStatus = "Connected"
        
        // Update history
        updatePitchHistory(pitch)
        
        // Update posture quality
        updatePostureQuality()
        
        // Track statistics
        updateStatistics(pitch)
    }
    
    private func updatePitchHistory(_ newPitch: Double) {
        pitchHistory.append(newPitch)
        if pitchHistory.count > maxHistoryPoints {
            pitchHistory.removeFirst()
        }
    }
    
    private func updatePostureQuality() {
        let now = Date()
        
        if pitch < poorPostureThreshold {
            postureQuality = .poor
            if poorPostureStartTime == nil {
                poorPostureStartTime = now
                lastPoorPostureCheck = now
            }
        } else if pitch < warningThreshold {
            postureQuality = .warning
            // If we were in poor posture, calculate the duration
            if poorPostureStartTime != nil, let lastCheck = lastPoorPostureCheck {
                poorPostureDuration += now.timeIntervalSince(lastCheck)
            }
            poorPostureStartTime = nil
            lastPoorPostureCheck = nil
        } else {
            postureQuality = .good
            // If we were in poor posture, calculate the duration
            if poorPostureStartTime != nil, let lastCheck = lastPoorPostureCheck {
                poorPostureDuration += now.timeIntervalSince(lastCheck)
            }
            poorPostureStartTime = nil
            lastPoorPostureCheck = nil
        }
    }
    
    private func updateSessionMetrics() {
        let now = Date()
        sessionDuration = now.timeIntervalSince(sessionStartTime)
        
        // Update poor posture duration if currently in poor posture
        if poorPostureStartTime != nil {
            if let lastCheck = lastPoorPostureCheck {
                poorPostureDuration += now.timeIntervalSince(lastCheck)
                lastPoorPostureCheck = now
            }
        }
        
        if sessionDuration > 0 {
            poorPosturePercentage = Int((poorPostureDuration / sessionDuration) * 100)
        }
    }
    
    private func updateStatistics(_ currentPitch: Double) {
        pitchSum += currentPitch
        pitchCount += 1
        
        if pitchCount == 1 {
            minPitch = currentPitch
            maxPitch = currentPitch
        } else {
            minPitch = min(minPitch, currentPitch)
            maxPitch = max(maxPitch, currentPitch)
        }
    }
    
    private func checkConnectionStatus() {
        if !motionManager.isDeviceMotionActive && isConnected {
            isConnected = false
            connectionStatus = "Disconnected"
        }
    }
    
    private func saveSession() {
        let metrics = SessionMetrics(
            poorPostureDuration: poorPostureDuration,
            averagePitch: pitchCount > 0 ? pitchSum / Double(pitchCount) : 0,
            minPitch: minPitch,
            maxPitch: maxPitch
        )
        PostureDataStore.shared.endSession(with: metrics)
    }
}
