import SwiftUI
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


struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = LeaderboardStore.shared
    @State private var showAddEntry = false
    @State private var editingIndex: Int? = nil
    @State private var editingName = ""
    @State private var editingScore = ""
    
    var sortedEntries: [LeaderboardEntry] {
        store.entries.sorted { $0.score > $1.score }
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
                            Text("No Entries Yet")
                                .font(.title3.weight(.semibold))
                            Text("Complete a race to add your first entry")
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
                                                editingScore = String(entry.score)
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
                            store.entries[index].score = Double(editingScore) ?? 0
                        } else {
                            store.entries.append(LeaderboardEntry(name: editingName, score: Double(editingScore) ?? 0))
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
                            
                            Text(String(format: "%.1f", topThree[1].score))
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
                            
                            Text(String(format: "%.1f", topThree[0].score))
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
                            
                            Text(String(format: "%.1f", topThree[2].score))
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
            
            // Score
            Text(String(format: "%.1f", entry.score))
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
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
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
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !score.isEmpty && Double(score) != nil
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
                        TextField("Score", text: $score)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Entry Details")
                } footer: {
                    Text("Enter a name and score for the leaderboard entry.")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
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
