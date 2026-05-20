import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .compact {
            AppTabView()
        } else {
            AppSplitView()
        }
    }
}

struct AppSplitView: View {
    @State private var selection: AppScreen? = .dashboard
    
    var body: some View {
        NavigationSplitView {
            AppSidebar(selection: $selection)
        } detail: {
            switch selection {
            case .dashboard, nil:
                NavigationStack {
                    ProjectListView()
                }
            case .clients:
                // ClientsView already has NavigationStack
                ClientsView()
            case .opportunities:
                OpportunitiesView()
            case .objectives:
                // ObjectivesView already has NavigationStack
                ObjectivesView()
            case .hallOfFame:
                NavigationStack {
                    AchievementsView()
                }
            case .profile:
                ProfileView()
            }
        }
    }
}

struct AppTabView: View {
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
            OpportunitiesView()
            .tabItem { Label("Opportunities", systemImage: "eurosign.circle.fill") }
            
            // TAB 4
            ObjectivesView()
            .tabItem { Label("Objectives", systemImage: "target") }
            
            // TAB 5
            NavigationStack {
                AchievementsView()
            }
            .tabItem { Label("Hall of Fame", systemImage: "trophy.fill") }
            
            // TAB 6
            ProfileView()
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}
