import SwiftUI
import PhotosUI

struct AddProjectView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var projects: [Project]
    
    @State private var title = ""
    @State private var type: ProjectType = .personal
    @State private var startDate = Date()
    @State private var dueDate = Date().addingTimeInterval(86400 * 30)
    @State private var selectedIcon = "folder.fill"
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    // --- BIBLIOTECA DE 100+ ICONIȚE ---
    let allIcons: [String] = [
        // PEOPLE & USERS
        "person.fill", "person.2.fill", "person.3.fill", "person.crop.circle.fill", "figure.run",
        "figure.walk", "figure.mind.and.body", "figure.socialdance", "brain.head.profile", "hand.thumbsup.fill",
        "star.fill", "heart.fill", "eye.fill", "mouth.fill", "ear.fill",
        
        // WORK & BUSINESS
        "briefcase.fill", "case.fill", "building.2.fill", "chart.bar.fill", "chart.pie.fill",
        "doc.text.fill", "folder.fill", "tray.full.fill", "archivebox.fill", "creditcard.fill",
        "banknote.fill", "signature", "megaphone.fill", "network", "person.2.crop.square.stack.fill",
        "calendar", "paperclip", "scissors", "bag.fill", "cart.fill",
        
        // TECH & DEVICES
        "laptopcomputer", "desktopcomputer", "printer.fill", "server.rack", "cpu",
        "keyboard.fill", "hammer.fill", "wrench.and.screwdriver.fill", "gearshape.fill", "lock.shield.fill",
        "wifi", "antenna.radiowaves.left.and.right", "battery.100", "lightbulb.fill", "bolt.fill",
        "gamecontroller.fill", "headphones", "mic.fill", "video.fill", "camera.fill",
        
        // CREATIVE & EDUCATION
        "paintbrush.fill", "pencil.tip.crop.circle.fill", "music.note", "theatermasks.fill", "book.fill",
        "graduationcap.fill", "bookmark.fill", "scroll.fill", "puzzlepiece.fill", "quote.bubble.fill",
        "bubble.left.and.bubble.right.fill", "film.fill", "camera.aperture", "eyeglasses", "studentdesk",
        
        // NATURE & TRAVEL
        "leaf.fill", "flame.fill", "drop.fill", "cloud.fill", "moon.fill",
        "sun.max.fill", "pawprint.fill", "globe", "map.fill", "airplane",
        "car.fill", "bus.fill", "tram.fill", "bicycle", "sailboat.fill",
        "house.fill", "tent.fill", "mountain.2.fill", "tree.fill", "flower",
        
        // OBJECTS & MISC
        "gift.fill", "bell.fill", "tag.fill", "crown.fill", "diamond.fill",
        "trophy.fill", "medal.fill", "flag.checkered", "timer", "stopwatch.fill",
        "pin.fill", "key.fill", "umbrella.fill", "mug.fill", "fork.knife"
    ]
    
    let columns = [GridItem(.adaptive(minimum: 45))]

    var body: some View {
        NavigationStack {
            Form {
                // --- INFO ---
                Section(header: Text("Project Details")) {
                    TextField("Project Title", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(ProjectType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // --- ICON PICKER (SCROLLABLE) ---
                Section(header: Text("Select Icon")) {
                    ScrollView(.vertical) {
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(allIcons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 45, height: 45)
                                    .background(selectedIcon == icon ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                                    .foregroundColor(selectedIcon == icon ? Color.blue : Color.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            selectedIcon = icon
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    .frame(maxHeight: 250) // Limităm înălțimea ca să nu ocupe tot ecranul
                }
                
                // --- PHOTO ---
                Section(header: Text("Cover Photo (Overrides Icon)")) {
                    if let data = selectedImageData, let uiImage = UIImage(data: data) {
                        HStack {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFill().frame(width: 100, height: 60).clipShape(RoundedRectangle(cornerRadius: 8))
                            Spacer()
                            Button("Remove", role: .destructive) {
                                withAnimation { selectedImageData = nil; selectedPhotoItem = nil }
                            }
                        }
                    } else {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Select Photo", systemImage: "photo")
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { oldValue, newItem in
                    Task { if let data = try? await newItem?.loadTransferable(type: Data.self) { withAnimation { selectedImageData = data } } }
                }
                
                // --- TIMELINE ---
                Section(header: Text("Timeline")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("Deadline", selection: $dueDate, in: startDate..., displayedComponents: .date)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let newProject = Project(
                            title: title,
                            imageName: selectedIcon,
                            imageData: selectedImageData,
                            type: type,
                            startDate: startDate,
                            dueDate: dueDate,
                            milestones: []
                        )
                        withAnimation { projects.append(newProject) }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
