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
        do {
            let schema = Schema([
                Project.self,
                Client.self,
                Opportunity.self,
                Objective.self,
                Win.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Request notification permissions
            NotificationManager.shared.requestAuthorization()
            
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
