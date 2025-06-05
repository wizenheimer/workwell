//
//  ContentView.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var motionVM = HeadphoneMotionViewModel()
    @EnvironmentObject var dataStore: PostureDataStore
    @State private var showingHistory = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if motionVM.isConnected {
                            // Connected state
                            connectedContent
                        } else {
                            // Disconnected state
                            disconnectedContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Work Well")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
                        
                        if motionVM.isConnected {
                            Divider()
                            
                            Button(role: .destructive) {
                                motionVM.stopTracking()
                            } label: {
                                Label("End Session", systemImage: "stop.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                NavigationStack {
                    SessionHistoryView()
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    // MARK: - Connected Content
    private var connectedContent: some View {
        VStack(spacing: 20) {
            // Posture visualization
            PostureVisualizationView(
                pitch: motionVM.pitch,
                postureQuality: motionVM.postureQuality
            )
            .frame(height: 250)
            
            // Metrics cards
            PostureMetricsView(
                sessionDuration: motionVM.sessionDuration,
                poorPostureDuration: motionVM.poorPostureDuration,
                poorPosturePercentage: motionVM.poorPosturePercentage,
                currentPitch: motionVM.pitch
            )
            
            // Real-time graph
            PostureGraphView(
                dataPoints: motionVM.pitchHistory,
                currentPitch: motionVM.pitch
            )
            .frame(height: 150)
            
            // Orientation details
            OrientationDetailsCard(
                pitch: motionVM.pitch,
                roll: motionVM.roll,
                yaw: motionVM.yaw
            )
        }
    }
    
    // MARK: - Disconnected Content
    private var disconnectedContent: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // AirPods icon
            Image(systemName: "airpodspro")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .symbolEffect(.pulse)
            
            VStack(spacing: 12) {
                Text("Connect AirPods Pro")
                    .font(.title2.bold())
                
                Text("Put on your AirPods Pro to start tracking your posture")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            
            // Connection button
            Button {
                motionVM.startTracking()
            } label: {
                Label("Start Tracking", systemImage: "play.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
            // Connection status
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text(motionVM.connectionStatus)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Orientation Details Card
struct OrientationDetailsCard: View {
    let pitch: Double
    let roll: Double
    let yaw: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Head Orientation")
                .font(.headline)
            
            VStack(spacing: 12) {
                OrientationRow(
                    label: "Pitch",
                    value: pitch,
                    icon: "arrow.up.and.down",
                    color: .blue
                )
                
                OrientationRow(
                    label: "Roll",
                    value: roll,
                    icon: "arrow.left.and.right",
                    color: .green
                )
                
                OrientationRow(
                    label: "Yaw",
                    value: yaw,
                    icon: "arrow.triangle.2.circlepath",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct OrientationRow: View {
    let label: String
    let value: Double
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(.body)
            
            Spacer()
            
            Text(String(format: "%.1f°", value))
                .font(.body.monospacedDigit())
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: PostureDataStore
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Data") {
                    HStack {
                        Text("Total Sessions")
                        Spacer()
                        Text("\(dataStore.sessions.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(role: .destructive) {
                        showingClearAlert = true
                    } label: {
                        Text("Clear All Data")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://support.apple.com")!) {
                        HStack {
                            Text("Help & Support")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear All Data?", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    dataStore.clearAllSessions()
                }
            } message: {
                Text("This will permanently delete all session history.")
            }
        }
    }
}

#Preview("Connected State") {
    ContentView()
        .environmentObject(PostureDataStore())
}

#Preview("Disconnected State") {
    ContentView()
        .environmentObject(PostureDataStore())
}

#Preview("Orientation Details") {
    OrientationDetailsCard(
        pitch: -15.5,
        roll: 2.3,
        yaw: 45.0
    )
    .padding()
}

#Preview("Settings") {
    SettingsView()
        .environmentObject(PostureDataStore())
}
