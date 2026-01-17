import SwiftUI
import SwiftData
import PhotosUI

struct ClientDetailView: View {
    @Bindable var client: Client
    
    @Environment(\.dismiss) var dismiss
    @State private var showingAddMeeting = false
    @State private var newMeetingDate = Date()
    @State private var newMeetingNote = ""
    
    // State pentru editare
    @State private var meetingToEdit: Meeting? = nil
    
    // State pentru foto
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var zoomImage: Data? = nil // Pentru afișare full screen

    // State pentru tipul de intrare (Meeting vs Reflection)
    @State private var entryType: EntryType = .meeting
    
    enum EntryType: String, CaseIterable {
        case meeting = "Meeting"
        case reflection = "Reflection"
    }
    
    // Helper pentru istoric unificat
    enum HistoryItem: Identifiable {
        case meeting(Meeting)
        case reflection(Reflection)
        
        var id: UUID {
            switch self {
            case .meeting(let m): return m.id
            case .reflection(let r): return r.id
            }
        }
        
        var date: Date {
            switch self {
            case .meeting(let m): return m.date
            case .reflection(let r): return r.date
            }
        }
    }
    
    var sortedHistory: [HistoryItem] {
        let ms = client.meetings.map { HistoryItem.meeting($0) }
        let rs = client.reflections.map { HistoryItem.reflection($0) }
        return (ms + rs).sorted { $0.date > $1.date }
    }

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
                    
                    // Client Status
                    HStack {
                        Image(systemName: "person.crop.circle.badge.questionmark").foregroundColor(.orange)
                        Text("Status")
                        Spacer()
                        Menu {
                            ForEach(ClientStatus.allCases, id: \.self) { status in
                                Button {
                                    withAnimation { client.status = status }
                                } label: {
                                    if client.status == status {
                                        Label(status.rawValue, systemImage: "checkmark")
                                    } else {
                                        Text(status.rawValue)
                                    }
                                }
                            }
                        } label: {
                            Text(client.status.rawValue)
                                .font(.subheadline)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(client.status == .active ? Color.blue.opacity(0.1) : (client.status == .coaching ? Color.purple.opacity(0.1) : Color.orange.opacity(0.1)))
                                .foregroundColor(client.status == .active ? .blue : (client.status == .coaching ? .purple : .orange))
                                .clipShape(Capsule())
                        }
                    }
                    
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
            
            // --- SECTION 2: ADD ACTIVITY ---
            Section {
                Button {
                    withAnimation { showingAddMeeting.toggle() }
                } label: {
                    HStack {
                        Image(systemName: "plus.bubble.fill").foregroundColor(.blue)
                        Text("Log New Activity").bold().foregroundColor(.blue)
                    }
                }
                
                if showingAddMeeting {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Type", selection: $entryType) {
                            ForEach(EntryType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, 5)
                        
                        DatePicker("Date", selection: $newMeetingDate, displayedComponents: .date)
                        
                        Text(entryType == .meeting ? "Notes & Conclusions:" : "Reflection / Context:")
                            .font(.caption).foregroundColor(.gray)
                        TextEditor(text: $newMeetingNote)
                            .frame(height: 80)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        
                        // FOTO ATAȘAMENT (Doar pentru Meeting momentan sau ambele?)
                        // User a cerut reflections "care să nu influențeze check-in". Nu a specificat poze.
                        // Voi lăsa pozele doar la Meetings pentru claritate și simplitate, conform cerinței "Reflections (Notes...)".
                        if entryType == .meeting {
                            HStack {
                                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .onTapGesture {
                                            // Remove photo
                                            withAnimation { selectedImageData = nil; selectedItem = nil }
                                        }
                                } else {
                                    PhotosPicker(selection: $selectedItem, matching: .images) {
                                        HStack {
                                            Image(systemName: "camera.fill")
                                            Text("Attach Photo")
                                        }
                                        .font(.caption).bold()
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            .onChange(of: selectedItem) { oldValue, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        withAnimation { selectedImageData = data }
                                    }
                                }
                            }
                        }
                        
                        Button("Save \(entryType.rawValue)") {
                            withAnimation {
                                if entryType == .meeting {
                                    var newMeeting = Meeting(date: newMeetingDate, conclusion: newMeetingNote)
                                    newMeeting.imageData = selectedImageData
                                    client.meetings.insert(newMeeting, at: 0)
                                } else {
                                    let newReflection = Reflection(date: newMeetingDate, text: newMeetingNote)
                                    client.reflections.insert(newReflection, at: 0)
                                }
                                
                                // Reset
                                newMeetingNote = ""
                                selectedImageData = nil
                                selectedItem = nil
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
            if !sortedHistory.isEmpty {
                Section(header: Text("History")) {
                    ForEach(sortedHistory) { item in
                        switch item {
                        case .meeting(let meeting):
                            // UI PENTRU MEETING
                            VStack(alignment: .leading, spacing: 10) {
                                // 1. Text Button (Edit)
                                Button {
                                    meetingToEdit = meeting
                                } label: {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading) {
                                            HStack {
                                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.caption2)
                                                Text(meeting.date.formatted(date: .abbreviated, time: .omitted))
                                                    .font(.caption).bold()
                                                    .foregroundColor(.secondary)
                                            }
                                            Text(meeting.conclusion)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                        }
                                        Spacer()
                                        Image(systemName: "pencil")
                                            .font(.caption)
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                                // 2. Image Button (Zoom)
                                if let data = meeting.imageData, let uiImage = UIImage(data: data) {
                                    Button {
                                        zoomImage = data
                                    } label: {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                            .padding(.vertical, 8)
                            .swipeActions {
                                Button(role: .destructive) {
                                    if let idx = client.meetings.firstIndex(where: { $0.id == meeting.id }) {
                                        withAnimation { client.meetings.remove(at: idx) }
                                    }
                                } label: { Label("Delete", systemImage: "trash") }
                            }

                        case .reflection(let reflection):
                            // UI PENTRU REFLECTION
                            VStack(alignment: .leading) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "doc.text.fill")
                                                .foregroundColor(.purple)
                                                .font(.caption2)
                                            Text(reflection.date.formatted(date: .abbreviated, time: .omitted))
                                                .font(.caption).bold()
                                                .foregroundColor(.secondary)
                                            Text("Reflection")
                                                .font(.caption)
                                                .foregroundColor(.purple.opacity(0.7))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.purple.opacity(0.1))
                                                .clipShape(Capsule())
                                        }
                                        Text(reflection.text)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 8)
                            .swipeActions {
                                Button(role: .destructive) {
                                    if let idx = client.reflections.firstIndex(where: { $0.id == reflection.id }) {
                                        withAnimation { client.reflections.remove(at: idx) }
                                    }
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                }
            } else {
                Section {
                    ContentUnavailableView("No history", systemImage: "list.bullet.clipboard", description: Text("Log your first meeting or reflection."))
                }
            }
        }
        .navigationTitle("Client Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitleDisplayMode(.inline)
        
        // --- FEREASTRA DE EDITARE (SHEET) ---
        .sheet(item: $meetingToEdit) { meeting in
            // Căutăm indexul real în array pentru a modifica originalul
            if let index = client.meetings.firstIndex(where: { $0.id == meeting.id }) {
                EditMeetingSheet(meeting: $client.meetings[index])
            }
        }
        .fullScreenCover(item: $zoomImage) { data in
             ZoomableImageView(imageData: data)
        }
    }
    
    // Funcție pentru generarea inițialelor
    func getInitials(name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
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

extension Data: @retroactive Identifiable {
    public var id: String { self.hashValue.description }
}
