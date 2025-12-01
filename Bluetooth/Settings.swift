import SwiftUI

struct SettingsView: View {
    var onReset: (() -> Void)? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink(destination: LeaderboardView()) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            Text("View Leaderboard")
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text("Leaderboard")
                        .textCase(.uppercase)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: {
                        onReset?()
                        print("Reset RC-Car")
                    }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            Text("Reset RC-Car")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Danger Zone")
                        .textCase(.uppercase)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                } footer: {
                    Text("This will reset the RC-Car and stop any running timers.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
