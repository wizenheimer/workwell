//
//  ContentView.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // MARK: - Properties
    
    @StateObject private var motionVM = HeadphoneMotionViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var connectionAttempts = 0
    @State private var isRetrying = false
    
    // MARK: - Connection State
    
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case error(String)
        
        var isConnected: Bool {
            if case .connected = self { return true }
            return false
        }
        
        var canStartTracking: Bool {
            if case .disconnected = self { return true }
            if case .error = self { return true }
            return false
        }
        
        static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected),
                 (.connecting, .connecting),
                 (.connected, .connected):
                return true
            case (.error(let lhsMessage), .error(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    @State private var connectionState: ConnectionState = .disconnected
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                        
                        if connectionState.isConnected {
                            connectedContent
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                    removal: .opacity
                                ))
                        } else {
                            disconnectedContent
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                    removal: .opacity
                                ))
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if connectionState.isConnected {
                        sessionStatusChip
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    menuButton
                }
            }
            .sheet(isPresented: $showingHistory) {
                SessionHistoryView(modelContext: modelContext)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .onAppear {
            PostureDataStore.shared.setModelContext(modelContext)
            updateConnectionState()
        }
        .onChange(of: motionVM.isConnected) { _, newValue in
            updateConnectionState()
        }
        .onChange(of: motionVM.connectionStatus) { _, _ in
            updateConnectionState()
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: connectionState.isConnected ?
                    [Color(.systemBackground), motionVM.postureQuality.color.opacity(0.1)] :
                    [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Animated orbs
            if connectionState.isConnected {
                GeometryReader { geometry in
                    ForEach(0..<3, id: \.self) { index in
                        AnimatedOrb(
                            color: motionVM.postureQuality.color,
                            size: CGSize(width: 120, height: 120),
                            position: CGPoint(
                                x: geometry.size.width * (0.2 + Double(index) * 0.3),
                                y: geometry.size.height * (0.3 + Double(index) * 0.2)
                            ),
                            animationDelay: Double(index) * 0.5
                        )
                    }
                }
                .opacity(0.3)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Work Well")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if connectionState.isConnected {
                        Text("Active Session")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Ready to start tracking")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if connectionState.isConnected {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(sessionDurationText)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("session time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    // MARK: - Session Status Chip
    
    private var sessionStatusChip: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(motionVM.postureQuality.color)
                .frame(width: 8, height: 8)
                .scaleEffect(motionVM.postureQuality == .poor ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: motionVM.postureQuality == .poor)
            
            Text("Live")
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(20)
    }
    
    // MARK: - Menu Button
    
    private var menuButton: some View {
        Menu {
            Button {
                showingHistory = true
            } label: {
                Label("Session History", systemImage: "clock.arrow.circlepath")
            }
            
            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "gear")
            }
            
            if connectionState.isConnected {
                Divider()
                
                Button(role: .destructive) {
                    stopSession()
                } label: {
                    Label("End Session", systemImage: "stop.circle")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.title3)
                .foregroundColor(.primary)
                .background(Color(.tertiarySystemBackground))
                .clipShape(Circle())
        }
    }
    
    // MARK: - Connected Content
    
    private var connectedContent: some View {
        VStack(spacing: 32) {
            // Main posture visualization
            PostureVisualizationView(
                pitch: motionVM.pitch,
                postureQuality: motionVM.postureQuality
            )
            .frame(height: 280)
            
            // Quick metrics row
            quickMetricsRow
            
            // Detailed metrics
            PostureMetricsView(
                sessionDuration: motionVM.sessionDuration,
                poorPostureDuration: motionVM.poorPostureDuration,
                poorPosturePercentage: motionVM.poorPosturePercentage,
                currentPitch: motionVM.pitch
            )
            
            // Real-time graph
            VStack(alignment: .leading, spacing: 16) {
                Text("Posture Timeline")
                    .font(.headline)
                
                PostureGraphView(
                    dataPoints: motionVM.pitchHistory,
                    currentPitch: motionVM.pitch
                )
                .frame(height: 120)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
            
            // Action button
            Button {
                stopSession()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title3)
                    Text("End Session")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.red, .red.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Quick Metrics Row
    
    private var quickMetricsRow: some View {
        HStack(spacing: 20) {
            QuickMetricCard(
                title: "Posture Quality",
                value: motionVM.postureQuality.message,
                icon: motionVM.postureQuality.icon,
                color: motionVM.postureQuality.color
            )
            
            QuickMetricCard(
                title: "Poor Posture",
                value: "\(motionVM.poorPosturePercentage)%",
                icon: "percent",
                color: motionVM.poorPosturePercentage > 30 ? .red : .green
            )
        }
    }
    
    // MARK: - Disconnected Content
    
    private var disconnectedContent: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Main illustration
            connectionIllustration
            
            // Content based on connection state
            VStack(spacing: 20) {
                connectionTitle
                connectionDescription
                connectionButton
                connectionStatusInfo
            }
            
            // Feature highlights
            if case .disconnected = connectionState {
                featureHighlights
            }
            
            Spacer()
        }
    }
    
    // MARK: - Connection Illustration
    
    private var connectionIllustration: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                .frame(width: 160, height: 160)
                .scaleEffect(isRetrying ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isRetrying)
            
            // Inner ring
            Circle()
                .stroke(Color.blue.opacity(0.4), lineWidth: 2)
                .frame(width: 120, height: 120)
                .scaleEffect(isRetrying ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isRetrying)
            
            // AirPods icon
            Image(systemName: "airpodspro")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .symbolEffect(.pulse, isActive: connectionState == .connecting)
        }
    }
    
    // MARK: - Connection State Content
    
    private var connectionTitle: some View {
        Text(connectionTitleText)
            .font(.title2.bold())
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
    }
    
    private var connectionDescription: some View {
        Text(connectionDescriptionText)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 320)
    }
    
    private var connectionButton: some View {
        Group {
            switch connectionState {
            case .disconnected, .error:
                Button {
                    startSession()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                        Text("Start Tracking")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .disabled(isRetrying)
                
            case .connecting:
                Button {
                    cancelConnection()
                } label: {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.secondary)
                        Text("Connecting...")
                            .font(.headline)
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(16)
                }
                
            case .connected:
                EmptyView()
            }
        }
        .frame(maxWidth: 280)
    }
    
    private var connectionStatusInfo: some View {
        Group {
            if case .error(let message) = connectionState {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(20)
                    
                    if connectionAttempts > 0 {
                        Button("Retry Connection") {
                            startSession()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            } else if case .connecting = connectionState {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                    Text("Put on your AirPods Pro and wait for connection")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Feature Highlights
    
    private var featureHighlights: some View {
        VStack(spacing: 20) {
            Text("Track Your Posture")
                .font(.headline)
                .padding(.top, 40)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                FeatureCard(
                    icon: "figure.stand",
                    title: "Real-time Monitoring",
                    description: "Track your head position continuously"
                )
                
                FeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress Analytics",
                    description: "View detailed session history"
                )
                
                FeatureCard(
                    icon: "bell.badge",
                    title: "Smart Reminders",
                    description: "Get notified about poor posture"
                )
                
                FeatureCard(
                    icon: "heart.circle",
                    title: "Health Benefits",
                    description: "Improve your long-term wellness"
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var sessionDurationText: String {
        let minutes = Int(motionVM.sessionDuration / 60)
        let seconds = Int(motionVM.sessionDuration.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var connectionTitleText: String {
        switch connectionState {
        case .disconnected:
            return "Connect AirPods Pro"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .error:
            return "Connection Failed"
        }
    }
    
    private var connectionDescriptionText: String {
        switch connectionState {
        case .disconnected:
            return "Put on your AirPods Pro to start tracking your posture and improve your work wellness."
        case .connecting:
            return "Establishing connection with your AirPods Pro. This may take a few moments."
        case .connected:
            return "Successfully connected to your AirPods Pro."
        case .error:
            return "Unable to connect to AirPods Pro. Make sure they're properly connected to your device."
        }
    }
    
    // MARK: - Actions
    
    private func startSession() {
        guard connectionState.canStartTracking else { return }
        
        connectionState = .connecting
        isRetrying = true
        connectionAttempts += 1
        
        withAnimation(.easeInOut(duration: 0.3)) {
            motionVM.startTracking()
        }
        
        // Timeout after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if case .connecting = connectionState {
                connectionState = .error("Connection timeout. Please try again.")
                isRetrying = false
            }
        }
    }
    
    private func stopSession() {
        withAnimation(.easeInOut(duration: 0.3)) {
            motionVM.stopTracking()
            connectionState = .disconnected
            isRetrying = false
            connectionAttempts = 0
        }
    }
    
    private func cancelConnection() {
        motionVM.stopTracking()
        connectionState = .disconnected
        isRetrying = false
    }
    
    private func updateConnectionState() {
        DispatchQueue.main.async {
            if motionVM.isConnected {
                connectionState = .connected
                isRetrying = false
            } else if motionVM.connectionStatus.contains("Error") || motionVM.connectionStatus.contains("not available") {
                connectionState = .error(motionVM.connectionStatus)
                isRetrying = false
            } else if motionVM.connectionStatus == "Connecting..." {
                connectionState = .connecting
            } else {
                connectionState = .disconnected
                isRetrying = false
            }
        }
    }
}

// MARK: - Supporting Views

struct AnimatedOrb: View {
    let color: Color
    let size: CGSize
    let position: CGPoint
    let animationDelay: Double
    
    @State private var offset: CGSize = .zero
    @State private var scale: Double = 1.0
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.6), color.opacity(0.1), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width / 2
                )
            )
            .frame(width: size.width, height: size.height)
            .position(
                x: position.x + offset.width,
                y: position.y + offset.height
            )
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 3.0 + animationDelay)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = CGSize(width: 20, height: 30)
                    scale = 1.2
                }
            }
    }
}

struct QuickMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
                .frame(height: 30)
            
            Text(title)
                .font(.subheadline.bold())
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Previews

#Preview("Connected State") {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: PostureSession.self, configurations: config)
    }()
    
    return ContentView()
        .modelContainer(container)
}

#Preview("Disconnected State") {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: PostureSession.self, configurations: config)
    }()
    
    return ContentView()
        .modelContainer(container)
}
