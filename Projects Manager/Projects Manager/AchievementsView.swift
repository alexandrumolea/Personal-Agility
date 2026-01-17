import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var projects: [Project]
    @Query private var objectives: [Objective]
    @Query private var wins: [Win]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showAddWinSheet = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
                            if projects.contains(where: { $0.id == project.id }) {
                                ZStack {
                                    // Link către detalii (Read Only)
                                    NavigationLink(destination: ProjectDetailView(project: project, isReadOnly: true)) {
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
                            if objectives.contains(where: { $0.id == obj.id }) {
                                ZStack {
                                    // Link către detalii (Read Only)
                                    NavigationLink(destination: ObjectiveDetailView(objective: obj, isReadOnly: true)) {
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
                
                // --- SECTION 3: MANUAL WINS (By Category) ---
                ForEach(ObjectiveType.allCases, id: \.self) { type in
                    let typeWins = wins.filter { $0.type == type }
                    if !typeWins.isEmpty {
                        Section(header: Text("Wins - \(type.rawValue)")
                            .font(.title2).bold()
                            .foregroundColor(.primary)
                            .textCase(nil)
                            .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 5, trailing: 0))
                        ) {
                            ForEach(typeWins) { win in
                                if wins.contains(where: { $0.id == win.id }) {
                                    ZStack {
                                        NavigationLink(destination: WinDetailView(win: win)) {
                                            EmptyView()
                                        }
                                        .opacity(0)
                                        
                                        // Card Visual - folosim anul ca subtitle
                                        HallOfFameCard(
                                            image: win.imageData,
                                            icon: win.imageName,
                                            title: win.title,
                                            subtitle: "Win \(Calendar.current.component(.year, from: win.date))"
                                        )
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                                }
                            }
                            .onDelete { indexSet in
                                deleteWins(at: indexSet, from: typeWins)
                            }
                        }
                    }
                }
                
                // Mesaj dacă e gol
                if finishedProjects.isEmpty && finishedObjectives.isEmpty && wins.isEmpty {
                    ContentUnavailableView("No Trophies Yet", systemImage: "trophy", description: Text("Finish projects, objectives, or add wins to see them here."))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.top, 50)
                }
                
                // Spațiu pentru buton
                Color.clear.frame(height: 80)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            
            // 2. BUTONUL PLUTITOR
            Button {
                showAddWinSheet = true
            } label: {
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
        .navigationTitle("Hall of Fame")
        .sheet(isPresented: $showAddWinSheet) {
            AddWinView()
        }
    }
    
    // --- FUNCȚII DE ȘTERGERE ---
    
    func deleteProjects(at offsets: IndexSet, from filteredList: [Project]) {
        offsets.forEach { index in
            let itemToDelete = filteredList[index]
            modelContext.delete(itemToDelete)
        }
    }
    
    func deleteObjectives(at offsets: IndexSet, from filteredList: [Objective]) {
        offsets.forEach { index in
            let itemToDelete = filteredList[index]
            modelContext.delete(itemToDelete)
        }
    }
    
    // NEW: Delete Wins
    func deleteWins(at offsets: IndexSet, from filteredList: [Win]) {
        offsets.forEach { index in
            let itemToDelete = filteredList[index]
            modelContext.delete(itemToDelete)
        }
    }
    
    func returnProject(_ project: Project) {
        project.isFinished = false
    }
    
    func returnObjective(_ objective: Objective) {
        objective.isFinished = false
    }
}

// Card reutilizabil - Updated with optional subtitle
struct HallOfFameCard: View {
    var image: Data?
    var icon: String
    var title: String
    var subtitle: String? = nil
    
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
                    Text(subtitle ?? "Completed")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(15)
        .shadow(color: .primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
