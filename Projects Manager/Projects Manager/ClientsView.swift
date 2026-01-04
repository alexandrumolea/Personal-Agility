import SwiftUI

struct ClientsView: View {
    @Binding var clients: [Client]
    @State private var showAddSheet = false
    @State private var newName = ""
    @State private var newRole = ""
    
    var sortedClients: [Client] {
        clients.sorted { c1, c2 in
            guard let d1 = c1.nextCheckInDate else { return false }
            guard let d2 = c2.nextCheckInDate else { return true }
            return d1 < d2
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    ForEach(sortedClients) { client in
                        if let index = clients.firstIndex(where: { $0.id == client.id }) {
                            NavigationLink(destination: ClientDetailView(client: $clients[index], onSave: {
                                DataManager.shared.saveClients(clients)
                            })) {
                                HStack {
                                    Text(client.name.prefix(1).uppercased())
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(client.isOverdue ? Color.red : Color.blue)
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
                    .onDelete(perform: deleteClient)
                    
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
                    }
                    .navigationTitle("New Client")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showAddSheet = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                let newClient = Client(name: newName, role: newRole)
                                clients.append(newClient)
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
    
    func deleteClient(at offsets: IndexSet) {
        offsets.map { sortedClients[$0] }.forEach { clientToDelete in
            if let index = clients.firstIndex(where: { $0.id == clientToDelete.id }) {
                clients.remove(at: index)
            }
        }
        DataManager.shared.saveClients(clients)
    }
}
