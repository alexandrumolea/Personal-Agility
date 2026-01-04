import SwiftUI

struct ContentView: View {
    @State private var projects: [Project] = []
    @State private var clients: [Client] = []
    @State private var objectives: [Objective] = []
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        TabView {
            // TAB 1
            NavigationStack { ProjectListView(projects: $projects) }
            .tabItem { Label("Dashboard", systemImage: "square.stack.3d.up.fill") }
            
            // TAB 2
            ClientsView(clients: $clients)
            .tabItem { Label("Clients", systemImage: "person.2.fill") }
            
            // TAB 3
            ObjectivesView(objectives: $objectives)
            .tabItem { Label("Objectives", systemImage: "target") }
            
            // TAB 4
            NavigationStack {
                // MODIFICARE: Pasăm $objectives (Binding) ca să putem șterge
                AchievementsView(projects: $projects, objectives: $objectives)
            }
            .tabItem { Label("Hall of Fame", systemImage: "trophy.fill") }
        }
        .onAppear {
            projects = DataManager.shared.loadProjects()
            clients = DataManager.shared.loadClients()
            objectives = DataManager.shared.loadObjectives()
        }
        .onChange(of: projects) { _, newValue in DataManager.shared.saveProjects(newValue) }
        .onChange(of: clients) { _, newValue in DataManager.shared.saveClients(newValue) }
        .onChange(of: objectives) { _, newValue in DataManager.shared.saveObjectives(newValue) }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                DataManager.shared.saveProjects(projects)
                DataManager.shared.saveClients(clients)
                DataManager.shared.saveObjectives(objectives)
            }
        }
    }
}
