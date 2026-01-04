import SwiftUI

// --- BARA DE PROGRES (folosită peste tot) ---
struct TimeProgressBar: View {
    var progress: Double
    var color: Color = .primary
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Fundalul barei
                Capsule()
                    .frame(width: geometry.size.width, height: 6)
                    .foregroundColor(Color.gray.opacity(0.2))
                
                // Partea plină
                Capsule()
                    .frame(width: min(CGFloat(self.progress) * geometry.size.width, geometry.size.width), height: 6)
                    .foregroundColor(color)
            }
        }
        .frame(height: 6)
    }
}

// --- CARDUL DE PROIECT (folosit în Dashboard) ---
struct ProjectCard: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 12) {
            if let data = project.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: project.imageName).font(.largeTitle).foregroundColor(.primary).frame(width: 60, height: 60).background(Color.gray.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.title).font(.headline).lineLimit(1).foregroundColor(.primary)
                Text("Due: \(project.dueDate.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundColor(.gray)
                TimeProgressBar(progress: project.timeProgress(), color: .blue).padding(.top, 2)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
// ... Păstrează codul existent pentru TimeProgressBar și ProjectCard ...

// --- FORMULAR EDITARE MILESTONE ---
struct EditMilestoneSheet: View {
    @Binding var milestone: Milestone
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Milestone Details")) {
                    TextField("Title", text: $milestone.title)
                    
                    // Selector pentru Dată
                    DatePicker("Deadline", selection: Binding(
                        get: { milestone.deadline ?? Date() },
                        set: { milestone.deadline = $0 }
                    ), displayedComponents: .date)
                    
                    // Buton ștergere dată (dacă vrei să fie fără termen)
                    if milestone.deadline != nil {
                        Button("Remove Deadline") {
                            withAnimation { milestone.deadline = nil }
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Set Deadline") {
                            withAnimation { milestone.deadline = Date() }
                        }
                    }
                }
            }
            .navigationTitle("Edit Milestone")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// --- FORMULAR EDITARE REFLECTION ---
struct EditReflectionSheet: View {
    @Binding var reflection: Reflection
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Edit Note")) {
                    TextEditor(text: $reflection.text)
                        .frame(minHeight: 150)
                    
                    DatePicker("Date", selection: $reflection.date, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Reflection")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
