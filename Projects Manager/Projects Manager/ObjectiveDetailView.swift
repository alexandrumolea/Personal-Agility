import SwiftUI
import PhotosUI

struct ObjectiveDetailView: View {
    @Binding var objective: Objective
    var onSave: () -> Void
    var isReadOnly: Bool = false
    
    @Environment(\.dismiss) var dismiss
    @State private var newMilestoneTitle = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isEditingSuccess = false
    @FocusState private var isSuccessFocused: Bool
    @State private var newReflectionText = ""
    @State private var isAddingReflection = false

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                // --- SECTION 1: FOTO (IZOLATĂ) ---
                // Separăm poza de restul conținutului pentru a izola PhotosPicker-ul
                Section {
                    ZStack(alignment: .bottomTrailing) {
                        if let data = objective.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFill().frame(height: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        } else {
                            Rectangle().fill(.ultraThinMaterial).frame(height: 200)
                                .overlay(VStack{
                                    Image(systemName: "target").font(.largeTitle).foregroundColor(.gray)
                                    Text("No photo").font(.caption).foregroundColor(.gray)
                                })
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                        
                        if !isReadOnly {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Image(systemName: "camera")
                                    .fontWeight(.medium).padding(8)
                                    .background(.regularMaterial).clipShape(Circle())
                                    .foregroundColor(.primary).shadow(radius: 3).padding(10)
                            }
                            .buttonStyle(.plain) // Stil explicit pentru a nu captura tot rândul
                        }
                    }
                    .padding(.horizontal).padding(.top)
                    .onChange(of: selectedPhotoItem) { oldValue, newItem in
                        Task { if let data = try? await newItem?.loadTransferable(type: Data.self) { objective.imageData = data } }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                
                // --- SECTION 2: INFO & TIMELINE (SEPARATĂ FIZIC) ---
                // Aici utilizatorul poate atinge oriunde fără să declanșeze camera
                Section {
                    VStack(alignment: .leading, spacing: 15) {
                        // Titlu și Icon
                        HStack(spacing: 12) {
                            Image(systemName: objective.imageName).font(.title).foregroundColor(.primary).frame(width: 40) .padding(.top, 4)
                            if isReadOnly { Text(objective.title).font(.title2).bold() } else { TextField("Objective Title", text: $objective.title, axis: .vertical).font(.title2).bold() }
                        }
                        Divider()
                        
                        // --- TAG OBIECTIV (MENU) ---
                        HStack {
                            Menu {
                                ForEach(ObjectiveType.allCases, id: \.self) { type in
                                    Button {
                                        withAnimation(.snappy) { objective.type = type }
                                    } label: { Text(type.rawValue) }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(objective.type.rawValue.uppercased())
                                        .id(objective.type)
                                        .contentTransition(.numericText(value: 0.25))
                                    
                                    if !isReadOnly {
                                        Image(systemName: "chevron.down").font(.caption2).opacity(0.6)
                                    }
                                }
                                .font(.caption).bold()
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(.ultraThinMaterial).clipShape(Capsule())
                                .foregroundColor(.primary)
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                            .disabled(isReadOnly)
                            .animation(.snappy, value: objective.type)
                            
                            if objective.isFinished {
                                Text("COMPLETED")
                                    .font(.caption).bold()
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(.ultraThinMaterial).clipShape(Capsule())
                                    .foregroundColor(.primary)
                                    .overlay(Capsule().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                            }
                        }
                        
                        // Success Definition
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("How do you define success?").font(.headline).fontDesign(.rounded)
                                Spacer()
                                if isEditingSuccess && !isReadOnly { Button("Done") { isEditingSuccess = false; isSuccessFocused = false }.font(.subheadline).bold().foregroundColor(.primary) }
                            }
                            ZStack(alignment: .topLeading) {
                                if isEditingSuccess && !isReadOnly {
                                    TextEditor(text: $objective.successCriteria).focused($isSuccessFocused).frame(minHeight: 60).padding(4).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                                } else {
                                    Text(objective.successCriteria.isEmpty ? "Define your 'Why'..." : objective.successCriteria)
                                        .font(.subheadline).foregroundColor(objective.successCriteria.isEmpty ? .gray : .primary).frame(maxWidth: .infinity, alignment: .leading).padding(10).background(.ultraThinMaterial).cornerRadius(12)
                                        .onTapGesture { if !isReadOnly { isEditingSuccess = true; isSuccessFocused = true } }
                                }
                            }
                        }
                        
                        // Timeline
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Timeline").font(.headline).fontDesign(.rounded)
                                Spacer()
                                Text(objective.isFinished ? "100%" : "\(Int(objective.timeProgress() * 100))%").font(.caption).bold().foregroundColor(.primary)
                            }
                            TimeProgressBar(progress: objective.isFinished ? 1.0 : objective.timeProgress(), color: .primary)
                            HStack {
                                if isReadOnly {
                                    Text(objective.startDate.formatted(date: .abbreviated, time: .omitted)).font(.subheadline).foregroundColor(.gray)
                                    Spacer()
                                    Text(objective.dueDate.formatted(date: .abbreviated, time: .omitted)).font(.subheadline).foregroundColor(.gray)
                                } else {
                                    DatePicker("", selection: $objective.startDate, displayedComponents: .date).labelsHidden().scaleEffect(0.8).tint(.primary)
                                    Spacer()
                                    DatePicker("", selection: $objective.dueDate, displayedComponents: .date).labelsHidden().scaleEffect(0.8).tint(.primary)
                                }
                            }
                        }
                    }
                    .padding() // Padding necesar pentru că am scos insets-urile rândului
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
                
                // --- SECTION 3: ADD MILESTONE ---
                if !isReadOnly {
                    Section {
                        HStack {
                            Image(systemName: "plus").foregroundColor(.primary)
                            TextField("Add new milestone...", text: $newMilestoneTitle)
                            Button("Add") {
                                if !newMilestoneTitle.isEmpty { withAnimation { objective.milestones.append(Milestone(title: newMilestoneTitle)) }; newMilestoneTitle = "" }
                            }
                            .disabled(newMilestoneTitle.isEmpty).foregroundColor(.primary)
                        }
                    }
                }
                
                // --- SECTION 4: MILESTONES (TO DO) ---
                let pendingTasks = objective.milestones.filter { !$0.isCompleted }
                if !pendingTasks.isEmpty {
                    Section(header: Text("Key Results / Milestones")) {
                        ForEach($objective.milestones) { $milestone in
                            if !milestone.isCompleted {
                                HStack {
                                    Image(systemName: "circle").foregroundColor(.gray).onTapGesture { if !isReadOnly { withAnimation { milestone.isCompleted = true } } }
                                    if isReadOnly { Text(milestone.title) } else { TextField("Task", text: $milestone.title) }
                                }
                                .swipeActions(edge: .trailing) {
                                    if !isReadOnly { Button(role: .destructive) { deleteSpecificMilestone(milestone) } label: { Label("Delete", systemImage: "trash") } }
                                }
                            }
                        }
                    }
                }
                
                // --- SECTION 5: ACHIEVEMENTS ---
                let completedTasks = objective.milestones.filter { $0.isCompleted }
                if !completedTasks.isEmpty {
                    Section(header: HStack { Text("Wins"); Image(systemName: "trophy").foregroundColor(.primary) }) {
                        ForEach($objective.milestones) { $milestone in
                            if milestone.isCompleted {
                                HStack {
                                    Image(systemName: "checkmark.circle").foregroundColor(.primary).font(.title3).onTapGesture { if !isReadOnly { withAnimation { milestone.isCompleted = false } } }
                                    Text(milestone.title).foregroundColor(.primary).bold()
                                    Spacer()
                                }
                                .listRowBackground(Color.clear).background(.ultraThinMaterial)
                                .swipeActions(edge: .trailing) {
                                    if !isReadOnly { Button(role: .destructive) { deleteSpecificMilestone(milestone) } label: { Label("Delete", systemImage: "trash") } }
                                }
                            }
                        }
                    }
                }
                
                // --- SECTION 6: REFLECTIONS ---
                Section(header: HStack {
                    Text("Journal & Progress")
                    Spacer()
                    if !isReadOnly {
                        Button { withAnimation { isAddingReflection.toggle() } } label: { Label(isAddingReflection ? "Close" : "Add Note", systemImage: isAddingReflection ? "xmark" : "plus.bubble").font(.caption).bold() }
                    }
                }) {
                    if isAddingReflection {
                        VStack(alignment: .leading) {
                            TextField("Thoughts...", text: $newReflectionText, axis: .vertical).lineLimit(3...6).padding(8).background(Color.gray.opacity(0.1)).cornerRadius(8)
                            Button("Save") {
                                let newRef = Reflection(date: Date(), text: newReflectionText)
                                withAnimation { objective.reflections.insert(newRef, at: 0); newReflectionText = ""; isAddingReflection = false }
                            }.disabled(newReflectionText.isEmpty).buttonStyle(.borderedProminent).tint(.primary)
                        }
                    }
                    if objective.reflections.isEmpty && !isAddingReflection { Text("No notes yet.").font(.caption).foregroundColor(.gray).italic() } else {
                        ForEach($objective.reflections) { $reflection in
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
                        }.onDelete { indexSet in objective.reflections.remove(atOffsets: indexSet) }
                    }
                }
                if !isReadOnly && !objective.isFinished { Color.clear.frame(height: 80).listRowSeparator(.hidden) }
            }
            .listStyle(.plain)
            
            // --- BUTON FLOTANT ---
            if !isReadOnly && !objective.isFinished {
                VStack {
                    Spacer()
                    Button { withAnimation { objective.isFinished = true }; dismiss() } label: {
                        HStack { Text("Complete Objective").font(.headline).fontWeight(.medium); Image(systemName: "flag.checkered").font(.headline) }
                            .padding(.horizontal, 40).padding(.vertical, 16).background(.regularMaterial).clipShape(Capsule()).shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4).overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }.foregroundColor(.primary).padding(.bottom, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { onSave() }
    }
    
    func deleteSpecificMilestone(_ item: Milestone) {
        if let index = objective.milestones.firstIndex(where: { $0.id == item.id }) { withAnimation { objective.milestones.remove(at: index) } }
    }
}

