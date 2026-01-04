import Foundation
import SwiftUI

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

// --- SUB-STRUCTURI ---
struct Milestone: Identifiable, Hashable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var deadline: Date? = nil // NOU: Deadline opțional pentru fiecare pas
}

struct Meeting: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var conclusion: String
}

struct Reflection: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var text: String
}

// --- STRUCTURI PRINCIPALE ---

// PROJECT
struct Project: Identifiable, Codable, Equatable {
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
    
    // NOU: Logică inteligentă de sortare
    // Returnează data celui mai urgent milestone nefinalizat.
    // Dacă nu există, returnează data finală a proiectului.
    var nextDeadline: Date {
        let activeMilestonesWithDeadlines = milestones
            .filter { !$0.isCompleted }
            .compactMap { $0.deadline }
            .sorted()
        
        return activeMilestonesWithDeadlines.first ?? dueDate
    }
    
    func timeProgress() -> Double {
        let totalDuration = dueDate.timeIntervalSince(startDate)
        let timePassed = Date().timeIntervalSince(startDate)
        if timePassed < 0 { return 0.0 }
        if totalDuration <= 0 { return 0.0 }
        return min(timePassed / totalDuration, 1.0)
    }
    
    static func == (lhs: Project, rhs: Project) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.milestones == rhs.milestones && lhs.successCriteria == rhs.successCriteria && lhs.imageData == rhs.imageData && lhs.startDate == rhs.startDate && lhs.dueDate == rhs.dueDate && lhs.type == rhs.type && lhs.isFinished == rhs.isFinished && lhs.reflections == rhs.reflections
    }
}

// CLIENT
struct Client: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var role: String = ""
    var frequency: CheckInFrequency = .monthly
    var meetings: [Meeting] = []
    
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

// OBJECTIVE
struct Objective: Identifiable, Codable, Equatable {
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
    
    func timeProgress() -> Double {
        let totalDuration = dueDate.timeIntervalSince(startDate)
        let timePassed = Date().timeIntervalSince(startDate)
        if timePassed < 0 { return 0.0 }
        if totalDuration <= 0 { return 0.0 }
        return min(timePassed / totalDuration, 1.0)
    }
    
    static func == (lhs: Objective, rhs: Objective) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.successCriteria == rhs.successCriteria &&
               lhs.imageName == rhs.imageName &&
               lhs.imageData == rhs.imageData &&
               lhs.type == rhs.type &&
               lhs.isFinished == rhs.isFinished &&
               lhs.startDate == rhs.startDate &&
               lhs.dueDate == rhs.dueDate &&
               lhs.milestones == rhs.milestones &&
               lhs.reflections == rhs.reflections
    }
}
