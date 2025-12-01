import SwiftUI

struct LeaderboardView: View {
    @ObservedObject private var store = LeaderboardStore.shared
    @State private var showAddEntry = false
    @State private var editingIndex: Int? = nil
    @State private var editingName = ""
    @State private var editingScore = ""
    
    var sortedEntries: [LeaderboardEntry] {
        store.entries.sorted { $0.score > $1.score }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if store.entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Entries")
                            .font(.headline)
                        Text("Add your first entry to get started")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    List {
                        ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                            LeaderboardRowView(
                                rank: index + 1,
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
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle("Leaderboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editingIndex = nil
                        editingName = ""
                        editingScore = ""
                        showAddEntry = true
                    }) {
                        Image(systemName: "plus")
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
            VStack(alignment: .center) {
                if rank <= 3 {
                    Image(systemName: medalIcon(for: rank))
                        .font(.system(size: 20))
                        .foregroundColor(medalColor(for: rank))
                } else {
                    Text("#\(rank)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(width: 24)
                }
            }
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(.body, design: .default))
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // Score
            Text(String(format: "%.1f", entry.score))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
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
    
    private func medalIcon(for rank: Int) -> String {
        switch rank {
        case 1: return "medal.fill"
        case 2: return "medal"
        case 3: return "medal"
        default: return ""
        }
    }
    
    private func medalColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .gray
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
                Section("Entry Details") {
                    TextField("Name", text: $name)
                    TextField("Score", text: $score)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        isPresented = false
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

#Preview {
    LeaderboardView()
}
