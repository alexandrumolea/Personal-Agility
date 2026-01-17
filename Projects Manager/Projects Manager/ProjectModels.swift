import Foundation
import SwiftUI
import SwiftData

// --- ENUMS ---
enum ProjectType: String, Codable, CaseIterable {
    case personal = "Personal"
    case work = "Work"
}

enum ObjectiveType: String, Codable, CaseIterable {
    case personalGrowth = "Personal Growth"
    case professional = "Professional"
    case longevity = "Longevity"
}

enum CheckInFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Every 2 Weeks"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case none = "No Schedule"
    
    var days: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .none: return 0
        }
    }

}

enum ClientStatus: String, Codable, CaseIterable {
    case active = "Client"
    case coaching = "Coaching Client"
    case prospect = "Prospect"
}

// --- SUB-STRUCTURI (Shared between Legacy and New) ---
struct Milestone: Identifiable, Hashable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var deadline: Date? = nil
}

struct Meeting: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var conclusion: String
    var imageData: Data? = nil
}

struct Reflection: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var text: String
}

// --- LEGACY STRUCTS (For Migration) ---
struct LegacyProject: Identifiable, Codable {
    var id = UUID()
    var title: String
    var successCriteria: String = ""
    var imageName: String
    var imageData: Data? = nil
    var type: ProjectType = .personal
    var isFinished: Bool = false
    var startDate: Date
    var dueDate: Date
    var milestones: [Milestone]
    var reflections: [Reflection] = []
}

struct LegacyClient: Identifiable, Codable {
    var id = UUID()
    var name: String
    var role: String = ""
    var frequency: CheckInFrequency = .monthly
    var meetings: [Meeting] = []
}

struct LegacyObjective: Identifiable, Codable {
    var id = UUID()
    var title: String
    var successCriteria: String = ""
    var imageName: String = "target"
    var imageData: Data? = nil
    var type: ObjectiveType = .personalGrowth
    var isFinished: Bool = false
    var startDate: Date
    var dueDate: Date
    var milestones: [Milestone]
    var reflections: [Reflection] = []
}

struct LegacyWin: Identifiable, Codable {
    var id = UUID()
    var title: String
    var date: Date
    var imageName: String = "trophy.fill"
    var imageData: Data? = nil
    var type: ObjectiveType = .personalGrowth
    var whatDidYouDo: String = ""
    var uncontrollableFactors: String = ""
    var learnAccomplishing: String = ""
    var learnAboutSelf: String = ""
    var useLessonsElsewhere: String = ""
    var helpBiggerObjectives: String = ""
    var celebration: String = ""
    var notes: String = ""
}

// --- SWIFTDATA MODELS ---

@Model
class Project {
    var id: UUID = UUID()
    var title: String = ""
    var successCriteria: String = ""
    var imageName: String = "folder"
    @Attribute(.externalStorage) var imageData: Data? = nil
    var typeRaw: String = ProjectType.personal.rawValue
    var isFinished: Bool = false
    var startDate: Date = Date()
    var dueDate: Date = Date()
    var milestones: [Milestone] = []
    var reflections: [Reflection] = []
    
    var type: ProjectType {
        get { ProjectType(rawValue: typeRaw) ?? .personal }
        set { typeRaw = newValue.rawValue }
    }
    
    init(title: String, startDate: Date, dueDate: Date, type: ProjectType, imageName: String) {
        self.title = title
        self.startDate = startDate
        self.dueDate = dueDate
        self.typeRaw = type.rawValue
        self.imageName = imageName
    }
    
    // Logică pentru deadline
    var nextDeadline: Date {
        let activeMilestonesWithDeadlines = milestones
            .filter { !$0.isCompleted }
            .compactMap { $0.deadline }
            .sorted()
        return activeMilestonesWithDeadlines.first ?? dueDate
    }
    
    var timeProgress: Double {
        let totalDuration = dueDate.timeIntervalSince(startDate)
        let timePassed = Date().timeIntervalSince(startDate)
        if timePassed < 0 { return 0.0 }
        if totalDuration <= 0 { return 0.0 }
        return min(timePassed / totalDuration, 1.0)
    }
}

@Model
class Client {
    var id: UUID = UUID()
    var name: String = ""
    var role: String = ""
    var frequencyRaw: String = CheckInFrequency.monthly.rawValue
    var statusRaw: String = ClientStatus.active.rawValue
    var meetings: [Meeting] = []
    var reflections: [Reflection] = []
    
    var frequency: CheckInFrequency {
        get { CheckInFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }
    
    var status: ClientStatus {
        get { ClientStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }
    
    init(name: String, role: String, status: ClientStatus = .active) {
        self.name = name
        self.role = role
        self.statusRaw = status.rawValue
    }
    
    var lastCheckInDate: Date? { meetings.sorted(by: { $0.date > $1.date }).first?.date }
    var nextCheckInDate: Date? {
        guard let last = lastCheckInDate, frequency != .none else { return nil }
        return Calendar.current.date(byAdding: .day, value: frequency.days, to: last)
    }
    var isOverdue: Bool {
        guard let next = nextCheckInDate else { return false }
        return Date() > next
    }
}

@Model
class Objective {
    var id: UUID = UUID()
    var title: String = ""
    var successCriteria: String = ""
    var imageName: String = "target"
    @Attribute(.externalStorage) var imageData: Data? = nil
    var typeRaw: String = ObjectiveType.personalGrowth.rawValue
    var isFinished: Bool = false
    var startDate: Date = Date()
    var dueDate: Date = Date()
    var milestones: [Milestone] = []
    var reflections: [Reflection] = []
    
    var type: ObjectiveType {
        get { ObjectiveType(rawValue: typeRaw) ?? .personalGrowth }
        set { typeRaw = newValue.rawValue }
    }
    
    init(title: String, startDate: Date, dueDate: Date, type: ObjectiveType) {
        self.title = title
        self.startDate = startDate
        self.dueDate = dueDate
        self.typeRaw = type.rawValue
    }
    
    var timeProgress: Double {
        let totalDuration = dueDate.timeIntervalSince(startDate)
        let timePassed = Date().timeIntervalSince(startDate)
        if timePassed < 0 { return 0.0 }
        if totalDuration <= 0 { return 0.0 }
        return min(timePassed / totalDuration, 1.0)
    }
}

@Model
class Win {
    var id: UUID = UUID()
    var title: String = ""
    var date: Date = Date()
    var imageName: String = "trophy.fill"
    @Attribute(.externalStorage) var imageData: Data? = nil
    var typeRaw: String = ObjectiveType.personalGrowth.rawValue
    
    // Questionnaire
    var whatDidYouDo: String = ""
    var uncontrollableFactors: String = ""
    var learnAccomplishing: String = ""
    var learnAboutSelf: String = ""
    var useLessonsElsewhere: String = ""
    var helpBiggerObjectives: String = ""
    var celebration: String = ""
    var notes: String = ""
    
    var type: ObjectiveType {
        get { ObjectiveType(rawValue: typeRaw) ?? .personalGrowth }
        set { typeRaw = newValue.rawValue }
    }
    
    init(title: String, date: Date, imageName: String = "trophy.fill", imageData: Data? = nil, type: ObjectiveType = .personalGrowth) {
        self.title = title
        self.date = date
        self.imageName = imageName
        self.imageData = imageData
        self.typeRaw = type.rawValue
    }
}
