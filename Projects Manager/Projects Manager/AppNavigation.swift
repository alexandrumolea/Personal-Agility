import SwiftUI

enum AppScreen: Hashable, CaseIterable, Identifiable {
    case dashboard
    case clients
    case opportunities
    case objectives
    case hallOfFame
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .clients: return "Clients"
        case .opportunities: return "Opportunities"
        case .objectives: return "Objectives"
        case .hallOfFame: return "Hall of Fame"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.stack.3d.up.fill"
        case .clients: return "person.2.fill"
        case .opportunities: return "eurosign.circle.fill"
        case .objectives: return "target"
        case .hallOfFame: return "trophy.fill"
        }
    }
}

struct AppSidebar: View {
    @Binding var selection: AppScreen?
    
    var body: some View {
        List(selection: $selection) {
            ForEach(AppScreen.allCases) { screen in
                Label(screen.title, systemImage: screen.icon)
                    .tag(screen)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Menu")
    }
}
