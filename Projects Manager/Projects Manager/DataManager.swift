import Foundation

class DataManager {
    static let shared = DataManager()
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // --- PROIECTE ---
    private func getProjectsURL() -> URL { getDocumentsDirectory().appendingPathComponent("SavedProjects.json") }
    
    func saveProjects(_ projects: [LegacyProject]) {
        do { try JSONEncoder().encode(projects).write(to: getProjectsURL()) } catch { print("Err projects: \(error)") }
    }
    
    func loadProjects() -> [LegacyProject] {
        guard let data = try? Data(contentsOf: getProjectsURL()) else { return [] }
        return (try? JSONDecoder().decode([LegacyProject].self, from: data)) ?? []
    }
    
    // --- CLIENȚI ---
    private func getClientsURL() -> URL { getDocumentsDirectory().appendingPathComponent("SavedClients.json") }
    
    func saveClients(_ clients: [LegacyClient]) {
        do { try JSONEncoder().encode(clients).write(to: getClientsURL()) } catch { print("Err clients: \(error)") }
    }
    
    func loadClients() -> [LegacyClient] {
        guard let data = try? Data(contentsOf: getClientsURL()) else { return [] }
        return (try? JSONDecoder().decode([LegacyClient].self, from: data)) ?? []
    }
    
    // --- OBIECTIVE ---
    private func getObjectivesURL() -> URL { getDocumentsDirectory().appendingPathComponent("SavedObjectives.json") }
    
    func saveObjectives(_ objectives: [LegacyObjective]) {
        do { try JSONEncoder().encode(objectives).write(to: getObjectivesURL()) } catch { print("Err objectives: \(error)") }
    }
    
    func loadObjectives() -> [LegacyObjective] {
        guard let data = try? Data(contentsOf: getObjectivesURL()) else { return [] }
        return (try? JSONDecoder().decode([LegacyObjective].self, from: data)) ?? []
    }
    
    // --- WINS ---
    private func getWinsURL() -> URL { getDocumentsDirectory().appendingPathComponent("SavedWins.json") }
    
    func saveWins(_ wins: [LegacyWin]) {
        do { try JSONEncoder().encode(wins).write(to: getWinsURL()) } catch { print("Err wins: \(error)") }
    }
    
    func loadWins() -> [LegacyWin] {
        guard let data = try? Data(contentsOf: getWinsURL()) else { return [] }
        return (try? JSONDecoder().decode([LegacyWin].self, from: data)) ?? []
    }
}
