import SwiftUI
import PhotosUI

struct ProjectDetailView: View {
    @Binding var project: Project
    var onSave: () -> Void
    var isReadOnly: Bool = false
    
    @Environment(\.dismiss) var dismiss
    @State private var newMilestoneTitle = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    // State pentru editare iconiță
    @State private var showIconPicker = false
    
    @State private var isEditingSuccess = false
    @FocusState private var isSuccessFocused: Bool
    
    // State pentru reflexii
    @State private var newReflectionText = ""
    @State private var isAddingReflection = false
    
    // --- LISTA COMPLETĂ DE 100+ ICONIȚE (Sincronizată cu AddProject) ---
    let availableIcons: [String] = [
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

    var body: some View {
        ZStack(alignment: .bottom) {
            
            List {
                // --- SECTION 1: HEADER & ICON ---
                Section {
                    VStack(alignment: .leading, spacing: 0) {
                        // FOTO DE COPERTĂ
                        ZStack(alignment: .bottomTrailing) {
                            if let data = project.imageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable().scaledToFill().frame(height: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .overlay(alignment: .topTrailing) {
                                        // Buton de ștergere poză (ca să revii la iconiță)
                                        if !isReadOnly {
                                            Button {
                                                withAnimation { project.imageData = nil }
                                            } label: {
                                                Image(systemName: "trash")
                                                    .fontWeight(.medium)
                                                    .padding(8)
                                                    .background(.regularMaterial)
                                                    .clipShape(Circle())
                                                    .foregroundColor(.primary)
                                                    .shadow(radius: 3)
                                                    .padding(10)
                                            }
                                        }
                                    }
                            } else {
                                Rectangle().fill(.ultraThinMaterial).frame(height: 200)
                                    .overlay(
                                        VStack {
                                            // ICONIȚA MARE (TAPPABLE PENTRU EDITARE)
                                            Button {
                                                if !isReadOnly { showIconPicker = true }
                                            } label: {
                                                Image(systemName: project.imageName)
                                                    .font(.system(size: 60))
                                                    .foregroundColor(.gray)
                                                    .padding()
                                                    .background(Circle().fill(.regularMaterial))
                                                    .overlay(
                                                        Group {
                                                            if !isReadOnly {
                                                                Image(systemName: "pencil")
                                                                    .fontWeight(.medium)
                                                                    .padding(8)
                                                                    .background(.regularMaterial)
                                                                    .clipShape(Circle())
                                                                    .foregroundColor(.primary)
                                                                    .shadow(radius: 3)
                                                                    .padding(10)
                                                                    .offset(x: 25, y: 25)
                                                            }
                                                        }
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Text(isReadOnly ? "" : "Tap icon to change")
                                                .font(.caption2).foregroundColor(.gray).padding(.top, 5)
                                        }
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                            
                            if !isReadOnly {
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    Image(systemName: "camera")
                                        .fontWeight(.medium)
                                        .padding(8)
                                        .background(.regularMaterial)
                                        .clipShape(Circle())
                                        .foregroundColor(.primary)
                                        .shadow(radius: 3)
                                        .padding(10)
                                }
                            }
                        }
                        .padding(.horizontal).padding(.top)
                        .onChange(of: selectedPhotoItem) { oldValue, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    project.imageData = data
                                }
                            }
                        }
                        
                        // INFO TITLU & TIP
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 12) {
                                // Iconița mică lângă titlu (se actualizează automat)
                                Image(systemName: project.imageName)
                                    .font(.title)
                                    .foregroundColor(.primary)
                                    .frame(width: 40)
                                    .onTapGesture {
                                        if !isReadOnly { showIconPicker = true }
                                    }
                                
                                if isReadOnly {
                                    Text(project.title).font(.title2).bold()
                                } else {
                                    TextField("Project Title", text: $project.title).font(.title2).bold()
                                }
                            }
                            Divider()
                            
                            // MENIU TIP PROIECT
                            HStack {
                                Menu {
                                    Button("Personal") { withAnimation { project.type = .personal } }
                                    Button("Work") { withAnimation { project.type = .work } }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(project.type.rawValue.uppercased())
                                        if !isReadOnly {
                                            Image(systemName: "chevron.down").font(.caption2).opacity(0.6)
                                        }
                                    }
                                    .font(.caption).bold()
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                                    .foregroundColor(.primary)
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                }
                                .disabled(isReadOnly)
                                
                                if project.isFinished {
                                    Text("COMPLETED")
                                        .font(.caption).bold()
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                        .foregroundColor(.primary)
                                        .overlay(Capsule().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                                }
                            }
                            
                            // Success Definition
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text("Success Definition").font(.headline).fontDesign(.rounded)
                                    Spacer()
                                    if isEditingSuccess && !isReadOnly { Button("Done") { isEditingSuccess = false; isSuccessFocused = false }.font(.subheadline).bold().foregroundColor(.primary) }
                                }
                                ZStack(alignment: .topLeading) {
                                    if isEditingSuccess && !isReadOnly {
                                        TextEditor(text: $project.successCriteria).focused($isSuccessFocused).frame(minHeight: 60).padding(4).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                                    } else {
                                        Text(project.successCriteria.isEmpty ? "No definition provided." : project.successCriteria)
                                            .font(.subheadline).foregroundColor(project.successCriteria.isEmpty ? .gray : .primary).frame(maxWidth: .infinity, alignment: .leading).padding(10)
                                            .background(.ultraThinMaterial)
                                            .cornerRadius(12)
                                            .onTapGesture {
                                                if !isReadOnly { isEditingSuccess = true; isSuccessFocused = true }
                                            }
                                    }
                                }
                            }
                            
                            // Timeline Progress
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Timeline").font(.headline).fontDesign(.rounded)
                                    Spacer()
                                    Text(project.isFinished ? "100%" : "\(Int(project.timeProgress() * 100))%").font(.caption).bold().foregroundColor(.primary)
                                }
                                TimeProgressBar(progress: project.isFinished ? 1.0 : project.timeProgress(), color: .primary)
                                
                                HStack {
                                    if isReadOnly {
                                        Text(project.startDate.formatted(date: .abbreviated, time: .omitted)).font(.subheadline).foregroundColor(.gray)
                                        Spacer()
                                        Text(project.dueDate.formatted(date: .abbreviated, time: .omitted)).font(.subheadline).foregroundColor(.gray)
                                    } else {
                                        DatePicker("", selection: $project.startDate, displayedComponents: .date).labelsHidden().scaleEffect(0.8).tint(.primary)
                                        Spacer()
                                        DatePicker("", selection: $project.dueDate, displayedComponents: .date).labelsHidden().scaleEffect(0.8).tint(.primary)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
                
                // --- SECTION 2: ADD MILESTONE ---
                if !isReadOnly {
                    Section {
                        HStack {
                            Image(systemName: "plus").foregroundColor(.primary)
                            TextField("Add new milestone...", text: $newMilestoneTitle)
                            Button("Add") {
                                if !newMilestoneTitle.isEmpty {
                                    withAnimation { project.milestones.append(Milestone(title: newMilestoneTitle)) }
                                    newMilestoneTitle = ""
                                }
                            }
                            .disabled(newMilestoneTitle.isEmpty)
                            .foregroundColor(.primary)
                        }
                    }
                }
                
                // --- SECTION 3: MILESTONES (TO DO) ---
                let pendingTasks = project.milestones.filter { !$0.isCompleted }
                if !pendingTasks.isEmpty {
                    Section(header: Text("To Do")) {
                        ForEach($project.milestones) { $milestone in
                            if !milestone.isCompleted {
                                HStack {
                                    Image(systemName: "circle").foregroundColor(.gray)
                                        .onTapGesture {
                                            if !isReadOnly { withAnimation { milestone.isCompleted = true } }
                                        }
                                    
                                    if isReadOnly {
                                        Text(milestone.title)
                                    } else {
                                        TextField("Task", text: $milestone.title)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if !isReadOnly {
                                        Button(role: .destructive) { deleteSpecificMilestone(milestone) } label: { Label("Delete", systemImage: "trash") }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // --- SECTION 4: ACHIEVEMENTS ---
                let completedTasks = project.milestones.filter { $0.isCompleted }
                if !completedTasks.isEmpty {
                    Section(header: HStack { Text("Achievements"); Image(systemName: "trophy").foregroundColor(.primary) }) {
                        ForEach($project.milestones) { $milestone in
                            if milestone.isCompleted {
                                HStack {
                                    Image(systemName: "checkmark.circle").foregroundColor(.primary).font(.title3)
                                        .onTapGesture {
                                            if !isReadOnly { withAnimation { milestone.isCompleted = false } }
                                        }
                                    Text(milestone.title).foregroundColor(.primary).bold()
                                    Spacer()
                                }
                                .listRowBackground(Color.clear).background(.ultraThinMaterial)
                                .swipeActions(edge: .trailing) {
                                    if !isReadOnly {
                                        Button(role: .destructive) { deleteSpecificMilestone(milestone) } label: { Label("Delete", systemImage: "trash") }
                                    }
                                }
                            }
                        }
                    }
                }

                // --- SECTION 5: REFLECTIONS ---
                Section(header: HStack {
                    Text("Reflections & Notes")
                    Spacer()
                    if !isReadOnly {
                        Button { withAnimation { isAddingReflection.toggle() } } label: { Label(isAddingReflection ? "Close" : "Add Note", systemImage: isAddingReflection ? "xmark" : "plus.bubble").font(.caption).bold() }
                    }
                }) {
                    if isAddingReflection {
                        VStack(alignment: .leading) {
                            TextField("Write your reflection here...", text: $newReflectionText, axis: .vertical).lineLimit(3...6).padding(8).background(Color.gray.opacity(0.1)).cornerRadius(8)
                            Button("Save Reflection") {
                                let newRef = Reflection(date: Date(), text: newReflectionText)
                                withAnimation { project.reflections.insert(newRef, at: 0); newReflectionText = ""; isAddingReflection = false }
                            }.disabled(newReflectionText.isEmpty).buttonStyle(.borderedProminent).tint(.primary)
                        }
                    }
                    if project.reflections.isEmpty && !isAddingReflection { Text("No reflections yet.").font(.caption).foregroundColor(.gray).italic() } else {
                        ForEach($project.reflections) { $reflection in
                            HStack(alignment: .top, spacing: 15) {
                                VStack(alignment: .center, spacing: 0) {
                                    Text(reflection.date.formatted(.dateTime.day().month())).font(.caption2).bold().foregroundColor(.gray)
                                    Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 2).frame(maxHeight: .infinity).padding(.top, 4)
                                }.frame(width: 40)
                                VStack(alignment: .leading, spacing: 5) {
                                    if isReadOnly {
                                        Text(reflection.text).font(.subheadline).foregroundColor(.primary)
                                    } else {
                                        TextField("Note", text: $reflection.text, axis: .vertical).font(.subheadline).foregroundColor(.primary)
                                    }
                                    Text(reflection.date.formatted(date: .omitted, time: .shortened)).font(.caption2).foregroundColor(.gray.opacity(0.8))
                                }.padding(.bottom, 15)
                            }.listRowSeparator(.hidden)
                        }.onDelete { indexSet in project.reflections.remove(atOffsets: indexSet) }
                    }
                }
                
                if !isReadOnly && !project.isFinished { Color.clear.frame(height: 80).listRowSeparator(.hidden) }
                
            }
            .listStyle(.plain)
            
            // --- ICON PICKER SHEET (FOLOSEȘTE ACUM LISTA COMPLETĂ) ---
            .sheet(isPresented: $showIconPicker) {
                NavigationStack {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 20) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title)
                                    .frame(width: 50, height: 50)
                                    .background(project.imageName == icon ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                                    .foregroundColor(project.imageName == icon ? Color.blue : Color.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(project.imageName == icon ? Color.blue : Color.clear, lineWidth: 2))
                                    .onTapGesture {
                                        withAnimation { project.imageName = icon }
                                        showIconPicker = false
                                    }
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("Choose Icon")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Close") { showIconPicker = false } }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            
            // --- BUTONUL FLOTANT ---
            if !isReadOnly && !project.isFinished {
                VStack {
                    Spacer()
                    Button {
                        withAnimation { project.isFinished = true }
                        dismiss()
                    } label: {
                        HStack { Text("Finish Project").font(.headline).fontWeight(.medium); Image(systemName: "flag.checkered").font(.headline) }
                            .padding(.horizontal, 40).padding(.vertical, 16).background(.regularMaterial).clipShape(Capsule()).shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4).overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }.foregroundColor(.primary).padding(.bottom, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { onSave() }
    }
    
    func deleteSpecificMilestone(_ item: Milestone) {
        if let index = project.milestones.firstIndex(where: { $0.id == item.id }) { withAnimation { project.milestones.remove(at: index) } }
    }
}
#Preview {
    NavigationStack {
        ProjectDetailView(
            project: .constant(Project(
                title: "Exemplu Proiect",
                imageName: "star.fill",
                type: .personal,
                startDate: Date(),
                dueDate: Date().addingTimeInterval(86400 * 30), // +30 zile
                milestones: [
                    Milestone(title: "Pasul 1 - Finalizat", isCompleted: true),
                    Milestone(title: "Pasul 2 - Urgent", isCompleted: false, deadline: Date().addingTimeInterval(3600))
                ],
                reflections: [
                    Reflection(date: Date(), text: "Prima notiță despre acest proiect.")
                ]
            )),
            onSave: {
                print("Salvare simulată")
            }
        )
    }
}
