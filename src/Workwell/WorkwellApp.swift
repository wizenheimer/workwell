//
//  WorkwellApp.swift
//  Workwell
//
//  Created by Nayan on 05/06/25.
//

import SwiftUI
import SwiftData

@main
struct WorkwellApp: App {
    // MARK: - Properties
    
    private let modelContainer: ModelContainer
    
    // MARK: - Initialization
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: PostureSession.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
