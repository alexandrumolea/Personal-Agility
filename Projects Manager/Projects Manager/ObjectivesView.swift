import SwiftUI

struct ObjectivesView: View {
    @Binding var objectives: [Objective]
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                
                // 1. FOLOSIM LIST PENTRU SWIPE-TO-DELETE
                List {
                    // --- CATEGORIE 1: PERSONAL GROWTH ---
                    let growthObjs = objectives.filter { $0.type == .personalGrowth && !$0.isFinished }
                    if !growthObjs.isEmpty {
                        objectiveSection(title: "Personal Growth", items: growthObjs)
                    }
                    
                    // --- CATEGORIE 2: PROFESSIONAL ---
                    let profObjs = objectives.filter { $0.type == .professional && !$0.isFinished }
                    if !profObjs.isEmpty {
                        objectiveSection(title: "Professional", items: profObjs)
                    }
                    
                    // --- CATEGORIE 3: LONGEVITY ---
                    let longObjs = objectives.filter { $0.type == .longevity && !$0.isFinished }
                    if !longObjs.isEmpty {
                        objectiveSection(title: "Longevity", items: longObjs)
                    }
                    
                    // Mesaj dacă nu există obiective active
                    if growthObjs.isEmpty && profObjs.isEmpty && longObjs.isEmpty {
                        ContentUnavailableView("No active objectives", systemImage: "target", description: Text("Set your big life goals."))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .padding(.top, 50)
                    }
                    
                    // Spațiu gol jos
                    Color.clear.frame(height: 80)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                
                // 2. BUTONUL PLUTITOR
                Button {
                    showAddSheet = true
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
            .navigationTitle("Objectives")
            .sheet(isPresented: $showAddSheet) {
                AddObjectiveView(objectives: $objectives)
            }
        }
    }
    
    // --- HELPER PENTRU SECȚIUNI ---
    @ViewBuilder
    func objectiveSection(title: String, items: [Objective]) -> some View {
        Section(header: Text(title)
            .font(.title2).bold()
            .foregroundColor(.primary)
            .textCase(nil)
            .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 5, trailing: 0))
        ) {
            ForEach(items) { obj in
                if let index = objectives.firstIndex(where: { $0.id == obj.id }) {
                    ZStack {
                        // Link invizibil
                        NavigationLink(destination: ObjectiveDetailView(objective: $objectives[index], onSave: {
                            DataManager.shared.saveObjectives(objectives)
                        })) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        // Cardul vizual
                        ObjectiveCard(objective: obj)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                }
            }
            .onDelete { indexSet in
                deleteObjectives(at: indexSet, from: items)
            }
        }
    }
    
    // --- FUNCȚIA DE ȘTERGERE ---
    func deleteObjectives(at offsets: IndexSet, from filteredList: [Objective]) {
        offsets.forEach { index in
            let objToDelete = filteredList[index]
            if let indexInMain = objectives.firstIndex(where: { $0.id == objToDelete.id }) {
                objectives.remove(at: indexInMain)
            }
        }
        DataManager.shared.saveObjectives(objectives)
    }
}

// --- DEFINEȘTE CARDUL AICI (CA SĂ FIE GĂSIT) ---
struct ObjectiveCard: View {
    let objective: Objective
    
    var body: some View {
        HStack(spacing: 12) {
            if let data = objective.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: objective.imageName).font(.system(size: 24)).foregroundColor(.primary).frame(width: 60, height: 60).background(Color.gray.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(objective.title).font(.headline).bold().lineLimit(1).foregroundColor(.primary)
                Text("Target: \(objective.dueDate.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundColor(.gray)
                
                // Bara de progres (Acum o va găsi în SharedViews)
                HStack(spacing: 4) {
                    TimeProgressBar(progress: objective.timeProgress(), color: .primary)
                    Text("\(Int(objective.timeProgress() * 100))%").font(.caption2).bold().foregroundColor(.primary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// FIX PENTRU PREVIEW
#Preview {
    ObjectivesView(objectives: .constant([]))
}
