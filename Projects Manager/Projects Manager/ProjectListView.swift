import SwiftUI

struct ProjectListView: View {
    @Binding var projects: [Project]
    @State private var showAddSheet = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            List {
                // --- WORK PROJECTS (SORTATE DUPĂ URGENȚĂ) ---
                let workProjects = projects
                    .filter { $0.type == .work && !$0.isFinished }
                    .sorted { $0.nextDeadline < $1.nextDeadline }
                
                if !workProjects.isEmpty {
                    Section(header: Text("Work Projects").font(.title2).bold().foregroundColor(.primary).textCase(nil).listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 5, trailing: 0))) {
                        ForEach(workProjects) { project in
                            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                                ZStack {
                                    NavigationLink(destination: ProjectDetailView(project: $projects[index], onSave: {
                                        DataManager.shared.saveProjects(projects)
                                    })) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                    
                                    ProjectCard(project: project)
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                            }
                        }
                        .onDelete { indexSet in
                            deleteProjects(at: indexSet, from: workProjects)
                        }
                    }
                }
                
                // --- PERSONAL PROJECTS (SORTATE DUPĂ URGENȚĂ) ---
                let personalProjects = projects
                    .filter { $0.type == .personal && !$0.isFinished }
                    .sorted { $0.nextDeadline < $1.nextDeadline }
                
                if !personalProjects.isEmpty {
                    Section(header: Text("Personal Projects").font(.title2).bold().foregroundColor(.primary).textCase(nil).listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 5, trailing: 0))) {
                        ForEach(personalProjects) { project in
                            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                                ZStack {
                                    NavigationLink(destination: ProjectDetailView(project: $projects[index], onSave: {
                                        DataManager.shared.saveProjects(projects)
                                    })) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                    
                                    ProjectCard(project: project)
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                            }
                        }
                        .onDelete { indexSet in
                            deleteProjects(at: indexSet, from: personalProjects)
                        }
                    }
                }
                
                if workProjects.isEmpty && personalProjects.isEmpty {
                    ContentUnavailableView("No active projects", systemImage: "clipboard", description: Text("Tap the + button to start."))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.top, 50)
                }
                
                Color.clear.frame(height: 80).listRowSeparator(.hidden).listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            
            // Buton Plutitor
            Button { showAddSheet = true } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.medium))
                    .foregroundColor(.primary)
                    .frame(width: 50, height: 50)
                    .background(.regularMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
            }
            .padding(25)
        }
        .navigationTitle("Dashboard")
        .sheet(isPresented: $showAddSheet) {
            AddProjectView(projects: $projects)
        }
    }
    
    func deleteProjects(at offsets: IndexSet, from filteredList: [Project]) {
        offsets.forEach { index in
            let projectToDelete = filteredList[index]
            if let indexInMain = projects.firstIndex(where: { $0.id == projectToDelete.id }) {
                projects.remove(at: indexInMain)
            }
        }
        DataManager.shared.saveProjects(projects)
    }
}
