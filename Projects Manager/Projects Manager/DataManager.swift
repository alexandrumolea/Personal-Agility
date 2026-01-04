import Foundation

class DataManager {
    static let shared = DataManager()
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // --- PROIECTE ---
    private func getProjectsURL() -> URL { getDocumentsDirectory().appendingPathComponent("SavedProjects.json") }
    
    func saveProjects(_ projects: [Project]) {
        do { try JSONEncoder().encode(projects).write(to: getProjectsURL()) } catch { print("Err projects: \(error)") }
    }
    
    func loadProjects() -> [Project] {
        guard let data = try? Data(contentsOf: getProjectsURL()) else { return [] }
        return (try? JSONDecoder().decode([Project].self, from: data)) ?? []
    }
    
    // --- CLIENȚI ---
    private func getClientsURL() -> URL { getDocumentsDirectory().appendingPathComponent("SavedClients.json") }
    
    func saveClients(_ clients: [Client]) {
        do { try JSONEncoder().encode(clients).write(to: getClientsURL()) } catch { print("Err clients: \(error)") }
    }
    
    func loadClients() -> [Client] {
        guard let data = try? Data(contentsOf: getClientsURL()) else { return [] }
        return (try? JSONDecoder().decode([Client].self, from: data)) ?? []
    }
    
    // --- OBIECTIVE ---
    private func getObjectivesURL() -> URL { getDocumentsDirectory().appendingPathComponent("SavedObjectives.json") }
    
    func saveObjectives(_ objectives: [Objective]) {
        do { try JSONEncoder().encode(objectives).write(to: getObjectivesURL()) } catch { print("Err objectives: \(error)") }
    }
    
    func loadObjectives() -> [Objective] {
        guard let data = try? Data(contentsOf: getObjectivesURL()) else { return [] }
        return (try? JSONDecoder().decode([Objective].self, from: data)) ?? []
    }
}
