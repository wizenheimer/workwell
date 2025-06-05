//
//  SettingsView.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [PostureSession]
    @State private var showingClearAlert = false
    @State private var showingExportSheet = false
    @State private var exportedData = ""
    
    // User preferences (you can expand these with UserDefaults or other persistence)
    @State private var notificationsEnabled = true
    @State private var poorPostureThreshold = 20.0 // in degrees
    @State private var reminderInterval = 30.0 // in minutes
    @State private var hapticFeedback = true
    
    var body: some View {
        NavigationStack {
            List {
                // Statistics Section
                statisticsSection
                
                // Preferences Section
                preferencesSection
                
                // Data Management Section
                dataSection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .alert("Clear All Data?", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all \(sessions.count) session(s) and cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(data: exportedData)
            }
        }
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        Section {
            StatRow(
                title: "Total Sessions",
                value: "\(sessions.count)",
                icon: "chart.bar",
                color: .blue
            )
            
            StatRow(
                title: "Total Time Tracked",
                value: totalTimeTracked,
                icon: "clock",
                color: .green
            )
            
            StatRow(
                title: "Average Session",
                value: averageSessionDuration,
                icon: "timer",
                color: .orange
            )
            
            StatRow(
                title: "Best Posture Score",
                value: bestPostureScore,
                icon: "trophy",
                color: .yellow
            )
        } header: {
            Label("Statistics", systemImage: "chart.line.uptrend.xyaxis")
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        Section {
            // Notifications Toggle
            HStack {
                Label("Posture Reminders", systemImage: "bell")
                Spacer()
                Toggle("", isOn: $notificationsEnabled)
            }
            
            // Poor Posture Threshold
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Poor Posture Threshold", systemImage: "angle")
                    Spacer()
                    Text("\(Int(poorPostureThreshold))°")
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                
                Slider(
                    value: $poorPostureThreshold,
                    in: 10...30,
                    step: 1
                ) {
                    Text("Threshold")
                } minimumValueLabel: {
                    Text("10°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("30°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .tint(.blue)
            }
            
            // Reminder Interval
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Reminder Interval", systemImage: "timer")
                    Spacer()
                    Text("\(Int(reminderInterval)) min")
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                
                Slider(
                    value: $reminderInterval,
                    in: 5...60,
                    step: 5
                ) {
                    Text("Interval")
                } minimumValueLabel: {
                    Text("5m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("60m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .tint(.blue)
            }
            
            // Haptic Feedback
            HStack {
                Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                Spacer()
                Toggle("", isOn: $hapticFeedback)
            }
        } header: {
            Label("Preferences", systemImage: "slider.horizontal.3")
        } footer: {
            Text("Customize how Workwell tracks and reminds you about your posture.")
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        Section {
            Button {
                exportData()
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
            .disabled(sessions.isEmpty)
            
            Button(role: .destructive) {
                showingClearAlert = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }
            .disabled(sessions.isEmpty)
        } header: {
            Label("Data Management", systemImage: "externaldrive")
        } footer: {
            if sessions.isEmpty {
                Text("No data to manage. Start tracking to see options here.")
            } else {
                Text("Export your data for backup or analysis. Clearing data cannot be undone.")
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://support.apple.com")!) {
                Label("Help & Support", systemImage: "questionmark.circle")
            }
            
            Link(destination: URL(string: "https://apple.com/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            
            Button {
                // Add feedback action
            } label: {
                Label("Send Feedback", systemImage: "envelope")
            }
        } header: {
            Label("About", systemImage: "info")
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalTimeTracked: String {
        let total = sessions.reduce(0) { $0 + $1.totalDuration }
        return formatDuration(total)
    }
    
    private var averageSessionDuration: String {
        guard !sessions.isEmpty else { return "0m" }
        let average = sessions.reduce(0) { $0 + $1.totalDuration } / Double(sessions.count)
        return formatDuration(average)
    }
    
    private var bestPostureScore: String {
        guard !sessions.isEmpty else { return "N/A" }
        let best = sessions.min { $0.poorPosturePercentage < $1.poorPosturePercentage }
        return "\(100 - (best?.poorPosturePercentage ?? 100))%"
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func exportData() {
        let viewModel = SessionHistoryViewModel(modelContext: modelContext)
        exportedData = viewModel.exportData()
        showingExportSheet = true
    }
    
    private func clearAllData() {
        do {
            try modelContext.delete(model: PostureSession.self)
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ExportDataView: View {
    let data: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Export Complete")
                    .font(.title2.bold())
                
                Text("Your posture data has been formatted as CSV and is ready to share or save.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share Data", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        UIPasteboard.general.string = data
                    } label: {
                        Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [data])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: PostureSession.self, configurations: config)
        
        // Add sample data
        let context = container.mainContext
        let sampleSessions = [
            PostureSession(
                startTime: Date().addingTimeInterval(-86400 * 5),
                endTime: Date().addingTimeInterval(-86400 * 5 + 3600),
                poorPostureDuration: 540,
                averagePitch: -10,
                minPitch: -15,
                maxPitch: -5
            ),
            PostureSession(
                startTime: Date().addingTimeInterval(-86400 * 3),
                endTime: Date().addingTimeInterval(-86400 * 3 + 2700),
                poorPostureDuration: 810,
                averagePitch: -18,
                minPitch: -25,
                maxPitch: -8
            )
        ]
        
        for session in sampleSessions {
            context.insert(session)
        }
        
        try! context.save()
        return container
    }()
    
    return SettingsView()
        .modelContainer(container)
}