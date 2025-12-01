import Foundation

struct LeaderboardEntry: Identifiable {
    var id = UUID()
    var name: String
    var score: Double
}
