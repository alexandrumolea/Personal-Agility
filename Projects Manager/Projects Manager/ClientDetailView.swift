import SwiftUI

struct ClientDetailView: View {
    @Binding var client: Client
    var onSave: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var showingAddMeeting = false
    @State private var newMeetingDate = Date()
    @State private var newMeetingNote = ""
    
    // State pentru editare
    @State private var meetingToEdit: Meeting? = nil

    var body: some View {
        List {
            // --- SECTION 1: HEADER & INFO ---
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        // Avatar generat din inițiale
                        ZStack {
                            Circle().fill(Color.blue.gradient)
                            Text(getInitials(name: client.name))
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                        }
                        .frame(width: 70, height: 70)
                        
                        VStack(alignment: .leading) {
                            TextField("Client Name", text: $client.name)
                                .font(.title2).bold()
                            TextField("Role / Position", text: $client.role)
                                .font(.subheadline).foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)
                    
                    Divider()
                    
                    // Setări Frecvență
                    HStack {
                        Image(systemName: "clock.arrow.circlepath").foregroundColor(.blue)
                        Text("Check-in Frequency")
                        Spacer()
                        Picker("", selection: $client.frequency) {
                            ForEach(CheckInFrequency.allCases, id: \.self) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                        .tint(.primary)
                    }
                    
                    // Status Check-in
                    HStack {
                        Image(systemName: "calendar").foregroundColor(client.isOverdue ? .red : .green)
                        Text(client.isOverdue ? "Overdue" : "On Track")
                            .foregroundColor(client.isOverdue ? .red : .green)
                            .bold()
                        
                        Spacer()
                        
                        if let next = client.nextCheckInDate {
                            Text("Next: \(next.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("No schedule").font(.caption).foregroundColor(.gray)
                        }
                    }
                }
            }
            
            // --- SECTION 2: ADD CHECK-IN ---
            Section {
                Button {
                    withAnimation { showingAddMeeting.toggle() }
                } label: {
                    HStack {
                        Image(systemName: "plus.bubble.fill").foregroundColor(.blue)
                        Text("Log New Meeting / Check-in").bold().foregroundColor(.blue)
                    }
                }
                
                if showingAddMeeting {
                    VStack(alignment: .leading, spacing: 10) {
                        DatePicker("Date", selection: $newMeetingDate, displayedComponents: .date)
                        
                        Text("Notes & Conclusions:")
                            .font(.caption).foregroundColor(.gray)
                        TextEditor(text: $newMeetingNote)
                            .frame(height: 80)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        
                        Button("Save Check-in") {
                            let newMeeting = Meeting(date: newMeetingDate, conclusion: newMeetingNote)
                            withAnimation {
                                client.meetings.insert(newMeeting, at: 0)
                                newMeetingNote = ""
                                showingAddMeeting = false
                            }
                        }
                        .disabled(newMeetingNote.isEmpty)
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.vertical)
                }
            }
            
            // --- SECTION 3: HISTORY (EDITABLE) ---
            if !client.meetings.isEmpty {
                Section(header: Text("History")) {
                    ForEach(client.meetings) { meeting in
                        Button {
                            // Deschidem fereastra de editare
                            meetingToEdit = meeting
                        } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text(meeting.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption).bold()
                                        .foregroundColor(.secondary)
                                    Text(meeting.conclusion)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "pencil") // Iconiță discretă că se poate edita
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteMeeting) // ACTIVARE SWIPE TO DELETE
                }
            } else {
                Section {
                    ContentUnavailableView("No history", systemImage: "text.bubble", description: Text("Log your first meeting."))
                }
            }
        }
        .navigationTitle("Client Details")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { onSave() }
        
        // --- FEREASTRA DE EDITARE (SHEET) ---
        .sheet(item: $meetingToEdit) { meeting in
            // Căutăm indexul real în array pentru a modifica originalul
            if let index = client.meetings.firstIndex(where: { $0.id == meeting.id }) {
                EditMeetingSheet(meeting: $client.meetings[index])
            }
        }
    }
    
    // Funcție pentru generarea inițialelor
    func getInitials(name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }
    
    // Funcție pentru ștergere
    func deleteMeeting(at offsets: IndexSet) {
        withAnimation {
            client.meetings.remove(atOffsets: offsets)
        }
    }
}

// --- STRUCTURĂ SEPARATĂ PENTRU EDITARE ---
struct EditMeetingSheet: View {
    @Binding var meeting: Meeting
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Meeting Details")) {
                    DatePicker("Date", selection: $meeting.date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $meeting.conclusion)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("Edit Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large]) // Fereastra apare până la jumătate sau complet
    }
}
