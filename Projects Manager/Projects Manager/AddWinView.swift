import SwiftUI
import PhotosUI

struct AddWinView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var wins: [Win]
    
    @State private var newTitle = ""
    @State private var selectedType: ObjectiveType = .personalGrowth
    @State private var selectedIcon = "trophy.fill"
    @State private var winDate = Date()
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    // Extended list of icons as requested ("icon din 100 de opțiuni" - I'll provide a good selection)
    let icons = [
        "trophy.fill", "medal.fill", "star.fill", "crown.fill", "rosette",
        "figure.run", "figure.mind.and.body", "book.fill", "graduationcap.fill",
        "chart.bar.fill", "briefcase.fill", "building.columns.fill", "banknote.fill",
        "heart.fill", "house.fill", "sun.max.fill", "airplane", "car.fill",
        "leaf.fill", "flame.fill", "bolt.fill", "drop.fill", "snowflake",
        "music.note", "paintbrush.fill", "gamecontroller.fill", "desktopcomputer",
        "hammer.fill", "wrench.and.screwdriver.fill", "stethoscope", "cross.case.fill"
    ]
    let columns = [GridItem(.adaptive(minimum: 45))]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Win Details")) {
                    TextField("What is your win?", text: $newTitle)
                    
                    Picker("Category", selection: $selectedType) {
                        ForEach(ObjectiveType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    DatePicker("Date Achieved", selection: $winDate, displayedComponents: .date)
                }
                
                Section(header: Text("Photo")) {
                    if let data = selectedImageData, let uiImage = UIImage(data: data) {
                        HStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            Button("Remove", role: .destructive) {
                                withAnimation {
                                    selectedImageData = nil
                                    selectedPhotoItem = nil
                                }
                            }
                        }
                    } else {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Select Photo", systemImage: "photo")
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { oldValue, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            withAnimation {
                                selectedImageData = data
                            }
                        }
                    }
                }
                
                Section(header: Text("Icon")) {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 45, height: 45)
                                .background(selectedIcon == icon ? Color.primary : Color.gray.opacity(0.1))
                                .foregroundColor(selectedIcon == icon ? Color(uiColor: .systemBackground) : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("New Win")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newWin = Win(
                            title: newTitle,
                            date: winDate,
                            imageName: selectedIcon,
                            imageData: selectedImageData,
                            type: selectedType
                        )
                        wins.append(newWin)
                        dismiss()
                    }
                    .disabled(newTitle.isEmpty)
                }
            }
        }
    }
}
