import SwiftUI
import SwiftData

struct ClientsView: View {
    @Query private var clients: [Client]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false
    @State private var newName = ""
    @State private var newRole = ""
    
    @State private var newStatus: ClientStatus = .active
    
    // Sortare clienți activi
    var activeClients: [Client] {
        clients.filter { $0.status == .active }
            .sorted { c1, c2 in
                guard let d1 = c1.nextCheckInDate else { return false }
                guard let d2 = c2.nextCheckInDate else { return true }
                return d1 < d2
            }
    }
    
    // Sortare clienți coaching
    var coachingClients: [Client] {
        clients.filter { $0.status == .coaching }
            .sorted { c1, c2 in
                guard let d1 = c1.nextCheckInDate else { return false }
                guard let d2 = c2.nextCheckInDate else { return true }
                return d1 < d2
            }
    }

    // Sortare prospecți
    var prospects: [Client] {
        clients.filter { $0.status == .prospect }
            .sorted { c1, c2 in
                guard let d1 = c1.nextCheckInDate else { return false }
                guard let d2 = c2.nextCheckInDate else { return true }
                return d1 < d2
            }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    // --- SECTION 1: CLIENTS ---
                    if !activeClients.isEmpty {
                        Section(header: Text("Clients").font(.title2).bold().foregroundColor(.primary).textCase(nil)) {
                            ForEach(activeClients) { client in
                                ClientRow(client: client)
                            }
                            .onDelete(perform: deleteActiveClient)
                        }
                    }
                    
                    // --- SECTION 2: COACHING CLIENTS ---
                    if !coachingClients.isEmpty {
                        Section(header: Text("Coaching Clients").font(.title2).bold().foregroundColor(.primary).textCase(nil)) {
                            ForEach(coachingClients) { client in
                                ClientRow(client: client)
                            }
                            .onDelete(perform: deleteCoachingClient)
                        }
                    }
                    
                    // --- SECTION 3: PROSPECTS ---
                    if !prospects.isEmpty {
                        Section(header: Text("Prospects").font(.title2).bold().foregroundColor(.primary).textCase(nil)) {
                            ForEach(prospects) { client in
                                ClientRow(client: client)
                            }
                            .onDelete(perform: deleteProspect)
                        }
                    }
                    
                    if activeClients.isEmpty && prospects.isEmpty {
                         ContentUnavailableView("No clients", systemImage: "person.2", description: Text("Add your first client or prospect."))
                             .listRowSeparator(.hidden)
                             .listRowBackground(Color.clear)
                             .padding(.top, 50)
                    }
                    
                    Color.clear.frame(height: 60).listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                
                // BUTON STIL APPLE
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
            .navigationTitle("Clients")
            .sheet(isPresented: $showAddSheet) {
                NavigationStack {
                    Form {
                        TextField("Name", text: $newName)
                        TextField("Role / Company", text: $newRole)
                        
                        Picker("Status", selection: $newStatus) {
                            ForEach(ClientStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                    }
                    .navigationTitle("New Client")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showAddSheet = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                let newClient = Client(name: newName, role: newRole, status: newStatus)
                                modelContext.insert(newClient)
                                newName = ""; newRole = ""
                                showAddSheet = false
                            }
                            .disabled(newName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    func deleteActiveClient(at offsets: IndexSet) {
        offsets.map { activeClients[$0] }.forEach { modelContext.delete($0) }
    }
    
    func deleteCoachingClient(at offsets: IndexSet) {
        offsets.map { coachingClients[$0] }.forEach { modelContext.delete($0) }
    }
    
    func deleteProspect(at offsets: IndexSet) {
        offsets.map { prospects[$0] }.forEach { modelContext.delete($0) }
    }
}

// Extracted Row for Reusability
struct ClientRow: View {
    let client: Client
    
    var body: some View {
        NavigationLink(destination: ClientDetailView(client: client)) {
            HStack {
                Text(client.name.prefix(1).uppercased())
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(client.isOverdue ? Color.red : (client.status == .active ? Color.blue : (client.status == .coaching ? Color.purple : Color.orange)))
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(client.name).font(.headline)
                    if !client.role.isEmpty {
                        Text(client.role).font(.caption).foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if let next = client.nextCheckInDate {
                    VStack(alignment: .trailing) {
                        Text(client.isOverdue ? "URGENT" : "Next")
                            .font(.caption2).bold()
                            .foregroundColor(client.isOverdue ? .red : .gray)
                        Text(next.formatted(.dateTime.day().month()))
                            .font(.caption)
                            .foregroundColor(client.isOverdue ? .red : .gray)
                    }
                } else {
                    Text("No schedule").font(.caption2).foregroundColor(.gray).opacity(0.5)
                }
            }
        }
    }
}
