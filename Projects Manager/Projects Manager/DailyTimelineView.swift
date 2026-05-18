import SwiftUI
import SwiftData
import PhotosUI

struct DailyTimelineView: View {
    let projects: [Project]
    let onClientTap: (Client) -> Void
    let onProjectTap: (Project) -> Void
    
    @Query private var clients: [Client]
    @Query private var dailyPlans: [DailyPlan]
    @Environment(\.modelContext) private var modelContext
    @State private var isExpanded = false
    
    private var today: Date { Calendar.current.startOfDay(for: Date()) }
    private var tomorrow: Date { Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today }
    
    private var todayPlans: [DailyPlan] {
        dailyPlans
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.id.uuidString < $1.id.uuidString }
    }
    
    private var todaysPlan: DailyPlan? {
        todayPlans.first
    }
    
    private var contactsDueToday: [Client] {
        clients
            .filter { client in
                guard let nextCheckInDate = client.nextCheckInDate else { return false }
                return nextCheckInDate < tomorrow
            }
            .sorted {
                ($0.nextCheckInDate ?? .distantFuture) < ($1.nextCheckInDate ?? .distantFuture)
            }
    }
    
    private var projectActionsDueToday: [ProjectActionItem] {
        projects.flatMap { project in
            project.milestones
                .filter { milestone in
                    guard !project.isFinished, !milestone.isCompleted, let executionDate = milestone.executionDate else { return false }
                    return Calendar.current.isDate(executionDate, inSameDayAs: today)
                }
                .map { ProjectActionItem(project: project, milestone: $0) }
        }
        .sorted { $0.project.title < $1.project.title }
    }
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: isExpanded ? 16 : 0) {
                header
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            isExpanded.toggle()
                        }
                    }
                
                if isExpanded {
                    Divider()
                    
                    if contactsDueToday.isEmpty && projectActionsDueToday.isEmpty {
                        CompactEmptyRow(icon: "sparkle", title: "No extracted items for today", subtitle: "Contacts and project actions will appear here when they are due.")
                    } else {
                        if !contactsDueToday.isEmpty {
                            contactsSection
                        }
                        
                        if !projectActionsDueToday.isEmpty {
                            projectActionsSection
                        }
                    }
                    
                    if let todaysPlan {
                        DailyPlanControls(dailyPlan: todaysPlan)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: .primary.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
        .onAppear(perform: ensureSingleTodayPlan)
        .onChange(of: dailyPlans.count) { _, _ in
            ensureSingleTodayPlan()
        }
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "sun.max.fill")
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 44, height: 44)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Today")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(todaySummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption.bold())
                .foregroundColor(.secondary)
        }
    }
    
    private var todaySummary: String {
        let contacts = contactsDueToday.count
        let actions = projectActionsDueToday.count
        
        if contacts == 0 && actions == 0 {
            return Date().formatted(.dateTime.weekday(.wide).day().month(.wide))
        }
        
        var parts: [String] = []
        if contacts > 0 {
            parts.append("\(contacts) contact\(contacts == 1 ? "" : "s")")
        }
        if actions > 0 {
            parts.append("\(actions) action\(actions == 1 ? "" : "s")")
        }
        return parts.joined(separator: " • ")
    }
    
    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(icon: "person.crop.circle.badge.exclamationmark", title: "People to contact")
            
            ForEach(contactsDueToday) { client in
                Button {
                    onClientTap(client)
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(client.isOverdue ? Color.red.opacity(0.16) : Color.blue.opacity(0.16))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Image(systemName: client.isOverdue ? "exclamationmark" : "person.fill")
                                    .font(.caption.bold())
                                    .foregroundColor(client.isOverdue ? .red : .blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(client.name)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Text(contactSubtitle(for: client))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var projectActionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(icon: "checklist.checked", title: "Project actions")
            
            ForEach(projectActionsDueToday) { item in
                HStack(alignment: .top, spacing: 10) {
                    Button {
                        markActionComplete(item)
                    } label: {
                        Image(systemName: "circle")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        onProjectTap(item.project)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.milestone.title)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Text(item.project.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.top, 3)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func ensureSingleTodayPlan() {
        if todayPlans.isEmpty {
            modelContext.insert(DailyPlan(date: today))
            try? modelContext.save()
            return
        }
        
        guard let canonicalPlan = todayPlans.first, todayPlans.count > 1 else { return }
        
        let duplicatePlans = Array(todayPlans.dropFirst())
        var didMutate = false
        
        // Keep meaningful values from duplicates before deleting them.
        for duplicate in duplicatePlans {
            if canonicalPlan.gymStatus == .undecided && duplicate.gymStatus != .undecided {
                canonicalPlan.gymStatus = duplicate.gymStatus
                didMutate = true
            }
            if canonicalPlan.gymIntention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !duplicate.gymIntention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                canonicalPlan.gymIntention = duplicate.gymIntention
                didMutate = true
            }
            if canonicalPlan.foodIntention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !duplicate.foodIntention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                canonicalPlan.foodIntention = duplicate.foodIntention
                didMutate = true
            }
            
            for photo in (duplicate.syncedMealPhotos ?? []) {
                if !(canonicalPlan.syncedMealPhotos ?? []).contains(where: { $0.id == photo.id }) {
                    if canonicalPlan.syncedMealPhotos == nil {
                        canonicalPlan.syncedMealPhotos = []
                    }
                    canonicalPlan.syncedMealPhotos?.append(photo)
                    didMutate = true
                }
            }
            
            for legacyPhoto in duplicate.mealPhotos {
                if !canonicalPlan.mealPhotos.contains(where: { $0.id == legacyPhoto.id }) {
                    canonicalPlan.mealPhotos.append(legacyPhoto)
                    didMutate = true
                }
            }
            
            modelContext.delete(duplicate)
            didMutate = true
        }
        
        if didMutate {
            try? modelContext.save()
        }
    }
    
    private func contactSubtitle(for client: Client) -> String {
        guard let nextCheckInDate = client.nextCheckInDate else { return "No schedule" }
        if Calendar.current.isDate(nextCheckInDate, inSameDayAs: today) {
            return "Due today"
        }
        if nextCheckInDate < today {
            return "Overdue since \(nextCheckInDate.formatted(date: .abbreviated, time: .omitted))"
        }
        return "Next: \(nextCheckInDate.formatted(date: .abbreviated, time: .omitted))"
    }
    
    private func markActionComplete(_ item: ProjectActionItem) {
        guard let index = item.project.milestones.firstIndex(where: { $0.id == item.milestone.id }) else { return }
        withAnimation {
            item.project.milestones[index].isCompleted = true
        }
    }
}

private struct ProjectActionItem: Identifiable {
    let project: Project
    let milestone: Milestone
    
    var id: String {
        "\(project.id.uuidString)-\(milestone.id.uuidString)"
    }
}

private struct SectionTitle: View {
    let icon: String
    let title: String
    
    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.bold())
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}

private struct CompactEmptyRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 34, height: 34)
                .background(Color.secondary.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct DailyPlanControls: View {
    @Bindable var dailyPlan: DailyPlan
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @FocusState private var focusedIntent: IntentField?
    
    private enum IntentField {
        case gym
        case food
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle(icon: "figure.strengthtraining.traditional", title: "Gym")
                
                Picker("Gym", selection: $dailyPlan.gymStatus) {
                    ForEach(GymStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.segmented)
                
                TextField("Intention for training", text: $dailyPlan.gymIntention, axis: .vertical)
                    .lineLimit(1...3)
                    .focused($focusedIntent, equals: .gym)
                    .submitLabel(.done)
                    .padding(10)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SectionTitle(icon: "fork.knife", title: "Food plan")
                    Spacer()
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Add", systemImage: "camera.fill")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.borderless)
                }
                
                TextField("Intention for food", text: $dailyPlan.foodIntention, axis: .vertical)
                    .lineLimit(1...3)
                    .focused($focusedIntent, equals: .food)
                    .submitLabel(.done)
                    .padding(10)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if (dailyPlan.syncedMealPhotos ?? []).isEmpty {
                    Text("Add photos for what you plan to eat today.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach((dailyPlan.syncedMealPhotos ?? []).sorted(by: { $0.createdAt < $1.createdAt })) { photo in
                                if let data = photo.imageData, let uiImage = UIImage(data: data) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 138, height: 138)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        Button {
                                            removeMealPhoto(photo)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.headline)
                                                .foregroundStyle(.white, .black.opacity(0.55))
                                                .padding(5)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedIntent = nil
                }
                .fontWeight(.semibold)
            }
        }
        .onChange(of: selectedPhotoItem) { oldValue, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                // Compress the image data to reduce its size for quick iCloud sync
                let compressedData = compressImageData(data) ?? data
                
                await MainActor.run {
                    withAnimation {
                        let photo = DailyMealPhotoRecord(imageData: compressedData)
                        modelContext.insert(photo)
                        if dailyPlan.syncedMealPhotos == nil {
                            dailyPlan.syncedMealPhotos = []
                        }
                        dailyPlan.syncedMealPhotos?.append(photo)
                        try? modelContext.save()
                        selectedPhotoItem = nil
                    }
                }
            }
        }
        .onChange(of: dailyPlan.gymStatus) { _, _ in try? modelContext.save() }
        .onChange(of: dailyPlan.gymIntention) { _, _ in try? modelContext.save() }
        .onChange(of: dailyPlan.foodIntention) { _, _ in try? modelContext.save() }
        .onAppear {
            migrateLegacyMealPhotosIfNeeded()
        }
    }
    
    private func removeMealPhoto(_ photo: DailyMealPhotoRecord) {
        guard let index = (dailyPlan.syncedMealPhotos ?? []).firstIndex(where: { $0.id == photo.id }) else { return }
        withAnimation {
            _ = dailyPlan.syncedMealPhotos?.remove(at: index)
            modelContext.delete(photo)
            try? modelContext.save()
        }
    }
    
    private func migrateLegacyMealPhotosIfNeeded() {
        guard (dailyPlan.syncedMealPhotos ?? []).isEmpty, !dailyPlan.mealPhotos.isEmpty else { return }
        
        withAnimation {
            for legacyPhoto in dailyPlan.mealPhotos {
                let photo = DailyMealPhotoRecord(imageData: legacyPhoto.imageData, note: legacyPhoto.note)
                modelContext.insert(photo)
                if dailyPlan.syncedMealPhotos == nil {
                    dailyPlan.syncedMealPhotos = []
                }
                dailyPlan.syncedMealPhotos?.append(photo)
            }
            dailyPlan.mealPhotos.removeAll()
            try? modelContext.save()
        }
    }
    
    private func compressImageData(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        
        let maxDimension: CGFloat = 1200
        let size = image.size
        guard size.width > 0, size.height > 0, size.width.isFinite, size.height.isFinite else { return nil }
        
        var newSize = size
        if size.width > maxDimension || size.height > maxDimension {
            if size.width > size.height {
                newSize = CGSize(width: maxDimension, height: size.height * (maxDimension / size.width))
            } else {
                newSize = CGSize(width: size.width * (maxDimension / size.height), height: maxDimension)
            }
        }
        
        // Final sanity check for non-finite dimensions
        guard newSize.width > 0, newSize.height > 0, newSize.width.isFinite, newSize.height.isFinite else { return nil }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage.jpegData(compressionQuality: 0.7)
    }
}
