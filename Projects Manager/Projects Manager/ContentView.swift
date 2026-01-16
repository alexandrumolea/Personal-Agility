import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // TAB 1
            NavigationStack {
                ProjectListView()
            }
            .tabItem { Label("Dashboard", systemImage: "square.stack.3d.up.fill") }
            
            // TAB 2
            ClientsView()
            .tabItem { Label("Clients", systemImage: "person.2.fill") }
            
            // TAB 3
            ObjectivesView()
            .tabItem { Label("Objectives", systemImage: "target") }
            
            // TAB 4
            NavigationStack {
                AchievementsView()
            }
            .tabItem { Label("Hall of Fame", systemImage: "trophy.fill") }
        }
    }
}
