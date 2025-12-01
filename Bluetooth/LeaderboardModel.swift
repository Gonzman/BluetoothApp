import Foundation

struct LeaderboardEntry: Identifiable, Codable {
    var id = UUID()
    var name: String
    var score: Double
    
    enum CodingKeys: String, CodingKey {
        case name, score
    }
    
    init(name: String, score: Double) {
        self.id = UUID()
        self.name = name
        self.score = score
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        // Handle null score by defaulting to 0
        self.score = try container.decodeIfPresent(Double.self, forKey: .score) ?? 0
    }
}

class LeaderboardStore: ObservableObject {
    static let shared = LeaderboardStore()
    
    @Published var entries: [LeaderboardEntry] = [
        LeaderboardEntry(name: "Alex", score: 245.5),
        LeaderboardEntry(name: "Jordan", score: 189.3),
        LeaderboardEntry(name: "Taylor", score: 312.8),
        LeaderboardEntry(name: "Casey", score: 156.2),
        LeaderboardEntry(name: "Morgan", score: 278.1),
    ]
    
    private init() {}
    
    func replaceEntries(with newEntries: [LeaderboardEntry]) {
        DispatchQueue.main.async {
            self.entries = newEntries
        }
    }
    
    func mergeEntries(with newEntries: [LeaderboardEntry]) {
        DispatchQueue.main.async {
            for newEntry in newEntries {
                // Check if entry with same name already exists
                if let existingIndex = self.entries.firstIndex(where: { $0.name == newEntry.name }) {
                    // Update score if different
                    if self.entries[existingIndex].score != newEntry.score {
                        self.entries[existingIndex].score = newEntry.score
                    }
                } else {
                    // Add new entry
                    self.entries.append(newEntry)
                }
            }
            // Remove entries that no longer exist in the server data
            self.entries.removeAll { entry in
                !newEntries.contains { $0.name == entry.name }
            }
        }
    }
}
