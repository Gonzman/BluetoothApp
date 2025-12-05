import SwiftUI
import Foundation

struct LeaderboardEntry: Identifiable, Codable {
    var id = UUID()
    var name: String
    var score: String
    
    enum CodingKeys: String, CodingKey {
        case name, score
    }
    
    init(name: String, score: String) {
        self.id = UUID()
        self.name = name
        self.score = score
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        // Handle null score by defaulting to "00:00:00"
        self.score = try container.decodeIfPresent(String.self, forKey: .score) ?? "00:00:00"
    }
}

// Helper function to format time as mm:ss:ms from seconds
func formatTime(_ totalSeconds: Double) -> String {
    let minutes = Int(totalSeconds) / 60
    let seconds = Int(totalSeconds) % 60
    let milliseconds = Int((totalSeconds.truncatingRemainder(dividingBy: 1)) * 100)
    return String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
}

// Helper function to parse time string mm:ss:ms to total seconds for sorting
func parseTimeToSeconds(_ timeString: String) -> Double {
    let components = timeString.split(separator: ":").compactMap { Int($0) }
    guard components.count == 3 else { return 0 }
    let minutes = components[0]
    let seconds = components[1]
    let centiseconds = components[2]
    return Double(minutes * 60) + Double(seconds) + Double(centiseconds) / 100.0
}

class LeaderboardStore: ObservableObject {
    static let shared = LeaderboardStore()
    
    @Published var entries: [LeaderboardEntry] = []
    
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


struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = LeaderboardStore.shared
    @State private var showAddEntry = false
    @State private var editingIndex: Int? = nil
    @State private var editingName = ""
    @State private var editingScore = ""
    
    var sortedEntries: [LeaderboardEntry] {
        store.entries.sorted { parseTimeToSeconds($0.score) < parseTimeToSeconds($1.score) }
    }
    
    var topThree: [LeaderboardEntry] {
        Array(sortedEntries.prefix(3))
    }
    
    var remainingEntries: [LeaderboardEntry] {
        Array(sortedEntries.dropFirst(3))
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Text("Leaderboard")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.6))
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(Color(.systemGray5))
                            )
                    }
                    .padding(.trailing, 4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                if store.entries.isEmpty {
                    VStack(spacing: 20) {
                        ZStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 56))
                                .foregroundColor(.blue.opacity(0.2))
                                .blur(radius: 10)
                            
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 52))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.6), .blue.opacity(0.3)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        
                        VStack(spacing: 8) {
                            Text("Noch keine Einträge")
                                .font(.title3.weight(.semibold))
                            Text("Beende ein Rennen, um deinen ersten Eintrag hinzuzufügen")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Winners Stand
                            if !topThree.isEmpty {
                                WinnersStandView(topThree: topThree)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                            }
                            
                            // Remaining entries
                            if !remainingEntries.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(Array(remainingEntries.enumerated()), id: \.element.id) { index, entry in
                                        LeaderboardRowView(
                                            rank: index + 4,
                                            entry: entry,
                                            onEdit: {
                                                editingIndex = store.entries.firstIndex { $0.id == entry.id } ?? index
                                                editingName = entry.name
                                                editingScore = entry.score
                                                showAddEntry = true
                                            },
                                            onDelete: {
                                                if let idx = store.entries.firstIndex(where: { $0.id == entry.id }) {
                                                    store.entries.remove(at: idx)
                                                }
                                            }
                                        )
                                        
                                        if index < remainingEntries.count - 1 {
                                            Divider()
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            
            .sheet(isPresented: $showAddEntry) {
                AddEditEntryView(
                    isPresented: $showAddEntry,
                    name: $editingName,
                    score: $editingScore,
                    onSave: {
                        if let index = editingIndex {
                            store.entries[index].name = editingName
                            store.entries[index].score = editingScore
                        } else {
                            store.entries.append(LeaderboardEntry(name: editingName, score: editingScore))
                        }
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

struct WinnersStandView: View {
    let topThree: [LeaderboardEntry]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("🏆 TOP PERFORMERS")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
                .tracking(0.5)
            
            HStack(alignment: .bottom, spacing: 12) {
                // 2nd place (left)
                if topThree.count >= 2 {
                    VStack(spacing: 8) {
                        Image(systemName: "medal")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.78))
                        
                        VStack(spacing: 4) {
                            Text(topThree[1].name)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            
                            Text(topThree[1].score)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.75, green: 0.75, blue: 0.78).opacity(0.08))
                    )
                }
                
                // 1st place (center, tallest)
                if topThree.count >= 1 {
                    VStack(spacing: 8) {
                        Image(systemName: "medal.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        
                        VStack(spacing: 4) {
                            Text(topThree[0].name)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                                .lineLimit(1)
                            
                            Text(topThree[0].score)
                                .font(.system(.caption2, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.12))
                    )
                }
                
                // 3rd place (right)
                if topThree.count >= 3 {
                    VStack(spacing: 8) {
                        Image(systemName: "medal")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 0.8, green: 0.5, blue: 0.2))
                        
                        VStack(spacing: 4) {
                            Text(topThree[2].name)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            
                            Text(topThree[2].score)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.08))
                    )
                }
            }
        }
    }
}

struct LeaderboardRowView: View {
    let rank: Int
    let entry: LeaderboardEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            Text("\(rank)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 28)
            
            // Name
            Text(entry.name)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            // Zeit
            Text(entry.score)
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Löschen", systemImage: "trash")
            }
            
            Button {
                onEdit()
            } label: {
                Label("Bearbeiten", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

struct AddEditEntryView: View {
    @Binding var isPresented: Bool
    @Binding var name: String
    @Binding var score: String
    let onSave: () -> Void
    
    var isValid: Bool {
        // Validate name is not empty
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        // Validate time format mm:ss:ms
        let components = score.split(separator: ":").compactMap { Int($0) }
        return components.count == 3 && components.allSatisfy { $0 >= 0 && $0 < 100 }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        TextField("Name", text: $name)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "timer")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        TextField("Zeit (mm:ss:ms)", text: $score)
                            .keyboardType(.numbersAndPunctuation)
                    }
                } header: {
                    Text("Eintragsdetails")
                } footer: {
                    Text("Gib einen Namen und die Zeit im Format mm:ss:ms (z.B. 01:23:45) für den Eintrag in der Bestenliste ein.")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Eintrag hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        onSave()
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }
}

#Preview {
    LeaderboardView()
}
