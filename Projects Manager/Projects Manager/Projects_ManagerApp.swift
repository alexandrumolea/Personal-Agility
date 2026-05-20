//
//  Projects_ManagerApp.swift
//  Projects Manager
//
//  Created by Alexandru Molea on 03.01.2026.
//

import SwiftUI
import SwiftData

@main
struct Projects_ManagerApp: App {
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            Project.self,
            Client.self,
            Opportunity.self,
            Objective.self,
            Win.self,
            DailyPlan.self,
            DailyMealPhotoRecord.self,
            ProfileSettings.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            #if DEBUG
            let shouldReset = true
            #else
            #if targetEnvironment(simulator)
            let shouldReset = true
            #else
            let shouldReset = false
            #endif
            #endif
            
            if shouldReset {
                print("SwiftData failed to load. Resetting store for development: \(error.localizedDescription)")
                let storeURL = modelConfiguration.url
                let fm = FileManager.default
                if fm.fileExists(atPath: storeURL.path) {
                    try? fm.removeItem(at: storeURL)
                    let shmURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
                    let walURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
                    try? fm.removeItem(at: shmURL)
                    try? fm.removeItem(at: walURL)
                }
                do {
                    container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                } catch {
                    fatalError("Could not create ModelContainer even after reset: \(error)")
                }
            } else {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
        
        // Request notification permissions
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
