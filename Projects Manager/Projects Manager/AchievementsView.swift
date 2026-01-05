import SwiftUI

struct AchievementsView: View {
    @Binding var projects: [Project]
    @Binding var objectives: [Objective] // Acum este Binding
    
    var body: some View {
        List {
            // --- SECTION 1: COMPLETED PROJECTS ---
            let finishedProjects = projects.filter { $0.isFinished }
            if !finishedProjects.isEmpty {
                Section(header: Text("Completed Projects")
                    .font(.title2).bold()
                    .foregroundColor(.primary)
                    .textCase(nil)
                    .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 5, trailing: 0))
                ) {
                    ForEach(finishedProjects) { project in
                        if let index = projects.firstIndex(where: { $0.id == project.id }) {
                            ZStack {
                                // Link către detalii (Read Only)
                                NavigationLink(destination: ProjectDetailView(project: $projects[index], onSave: {}, isReadOnly: true)) {
                                    EmptyView()
                                }
                                .opacity(0)
                                
                                // Cardul vizual
                                HallOfFameCard(image: project.imageData, icon: project.imageName, title: project.title)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                            .swipeActions(edge: .leading) {
                                Button {
                                    returnProject(project)
                                } label: {
                                    Label("Return", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        deleteProjects(at: indexSet, from: finishedProjects)
                    }
                }
            }
            
            // --- SECTION 2: ACHIEVED OBJECTIVES ---
            let finishedObjectives = objectives.filter { $0.isFinished }
            if !finishedObjectives.isEmpty {
                Section(header: Text("Achieved Objectives")
                    .font(.title2).bold()
                    .foregroundColor(.primary)
                    .textCase(nil)
                    .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 5, trailing: 0))
                ) {
                    ForEach(finishedObjectives) { obj in
                        if let index = objectives.firstIndex(where: { $0.id == obj.id }) {
                            ZStack {
                                // Link către detalii (Read Only)
                                NavigationLink(destination: ObjectiveDetailView(objective: $objectives[index], onSave: {}, isReadOnly: true)) {
                                    EmptyView()
                                }
                                .opacity(0)
                                
                                // Cardul vizual
                                HallOfFameCard(image: obj.imageData, icon: obj.imageName, title: obj.title)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                            .swipeActions(edge: .leading) {
                                Button {
                                    returnObjective(obj)
                                } label: {
                                    Label("Return", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        deleteObjectives(at: indexSet, from: finishedObjectives)
                    }
                }
            }
            
            // Mesaj dacă e gol
            if finishedProjects.isEmpty && finishedObjectives.isEmpty {
                ContentUnavailableView("No Trophies Yet", systemImage: "trophy", description: Text("Finish projects or objectives to see them here."))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.top, 50)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle("Hall of Fame")
    }
    
    // --- FUNCȚII DE ȘTERGERE ---
    
    func deleteProjects(at offsets: IndexSet, from filteredList: [Project]) {
        offsets.forEach { index in
            let itemToDelete = filteredList[index]
            if let indexInMain = projects.firstIndex(where: { $0.id == itemToDelete.id }) {
                projects.remove(at: indexInMain)
            }
        }
        DataManager.shared.saveProjects(projects)
    }
    
    func deleteObjectives(at offsets: IndexSet, from filteredList: [Objective]) {
        offsets.forEach { index in
            let itemToDelete = filteredList[index]
            if let indexInMain = objectives.firstIndex(where: { $0.id == itemToDelete.id }) {
                objectives.remove(at: indexInMain)
            }
        }
        DataManager.shared.saveObjectives(objectives)
    }
    
    func returnProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].isFinished = false
            DataManager.shared.saveProjects(projects)
        }
    }
    
    func returnObjective(_ objective: Objective) {
        if let index = objectives.firstIndex(where: { $0.id == objective.id }) {
            objectives[index].isFinished = false
            DataManager.shared.saveObjectives(objectives)
        }
    }
}

// Card reutilizabil
struct HallOfFameCard: View {
    var image: Data?
    var icon: String
    var title: String
    
    var body: some View {
        HStack(spacing: 15) {
            if let data = image, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(.primary)
                    .frame(width: 80, height: 80)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.yellow)
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
