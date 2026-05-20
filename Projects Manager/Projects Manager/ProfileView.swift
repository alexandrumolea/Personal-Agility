import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(
        filter: #Predicate<ProfileSettings> { $0.singletonKey == "default" }
    ) private var allSettings: [ProfileSettings]
    @Environment(\.modelContext) private var modelContext
    
    private let granularityOptions = [2, 5, 10, 15, 20]
    private let goalOptions = [10, 20, 30, 45, 60, 90, 120]
    
    private var settings: ProfileSettings? {
        allSettings.first
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Meditation")) {
                    Picker("Minute step", selection: Binding(
                        get: { settings?.meditationGranularityMinutes ?? 5 },
                        set: { newValue in
                            settings?.meditationGranularityMinutes = newValue
                            settings?.updatedAt = Date()
                            try? modelContext.save()
                        }
                    )) {
                        ForEach(granularityOptions, id: \.self) { option in
                            Text("\(option) minutes").tag(option)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    Picker("Battery full at", selection: Binding(
                        get: { settings?.meditationGoalMinutes ?? 30 },
                        set: { newValue in
                            settings?.meditationGoalMinutes = newValue
                            settings?.updatedAt = Date()
                            try? modelContext.save()
                        }
                    )) {
                        ForEach(goalOptions, id: \.self) { option in
                            Text("\(option) minutes").tag(option)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            .navigationTitle("Profile")
            .onAppear(perform: ensureSingleSettingsRecord)
        }
    }
    
    private func ensureSingleSettingsRecord() {
        if allSettings.isEmpty {
            modelContext.insert(ProfileSettings(singletonKey: ProfileSettings.defaultKey))
            try? modelContext.save()
            return
        }
        
        guard allSettings.count > 1 else { return }
        let sortedByFreshness = allSettings.sorted { $0.updatedAt > $1.updatedAt }
        guard !sortedByFreshness.isEmpty else { return }
        let duplicates = sortedByFreshness.dropFirst()
        var didMutate = false
        
        for duplicate in duplicates {
            modelContext.delete(duplicate)
            didMutate = true
        }
        
        if didMutate {
            try? modelContext.save()
        }
    }
}
