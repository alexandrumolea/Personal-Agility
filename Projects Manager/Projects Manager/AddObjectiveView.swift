import SwiftUI
import PhotosUI

struct AddObjectiveView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var objectives: [Objective]
    
    @State private var newTitle = ""
    @State private var newSuccessCriteria = ""
    @State private var selectedType: ObjectiveType = .personalGrowth
    @State private var selectedIcon = "target"
    @State private var startDate = Date()
    @State private var dueDate = Date().addingTimeInterval(90*24*60*60) // 3 luni default
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    let icons = ["target", "figure.mind.and.body", "book.fill", "chart.bar.fill", "heart.fill", "leaf.fill", "hourglass", "mountain.2.fill"]
    let columns = [GridItem(.adaptive(minimum: 45))]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Objective Info")) {
                    TextField("Title (e.g. Learn Spanish)", text: $newTitle)
                    Picker("Category", selection: $selectedType) {
                        ForEach(ObjectiveType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle()) // Sau MenuPickerStyle dacă preferi
                }
                
                Section(header: Text("The 'Why'"), footer: Text("Why is this objective important for you?")) {
                    TextField("Success criteria...", text: $newSuccessCriteria, axis: .vertical).lineLimit(3...5)
                }
                
                Section(header: Text("Motivation Photo")) {
                    if let data = selectedImageData, let uiImage = UIImage(data: data) {
                        HStack {
                            Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 80, height: 80).clipShape(RoundedRectangle(cornerRadius: 10))
                            Button("Remove", role: .destructive) { withAnimation { selectedImageData = nil; selectedPhotoItem = nil } }
                        }
                    } else {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) { Label("Select Photo", systemImage: "photo") }
                    }
                }
                .onChange(of: selectedPhotoItem) { oldValue, newItem in
                    Task { if let data = try? await newItem?.loadTransferable(type: Data.self) { withAnimation { selectedImageData = data } } }
                }
                
                Section(header: Text("Timeline")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("Target Date", selection: $dueDate, in: startDate..., displayedComponents: .date)
                }
                
                Section(header: Text("Icon")) {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon).font(.title2).frame(width: 45, height: 45)
                                .background(selectedIcon == icon ? Color.primary : Color.gray.opacity(0.1))
                                .foregroundColor(selectedIcon == icon ? Color(uiColor: .systemBackground) : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("New Objective")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newObj = Objective(
                            title: newTitle,
                            successCriteria: newSuccessCriteria,
                            imageName: selectedIcon,
                            imageData: selectedImageData,
                            type: selectedType,
                            startDate: startDate,
                            dueDate: dueDate,
                            milestones: [Milestone(title: "First step", isCompleted: false)]
                        )
                        objectives.append(newObj)
                        dismiss()
                    }
                    .disabled(newTitle.isEmpty)
                }
            }
        }
    }
}
