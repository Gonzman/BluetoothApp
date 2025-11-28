import SwiftUI

struct SettingsView: View {
    @Binding var isDebug: Bool
    var onReset: (() -> Void)? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Leaderboard") {
                    NavigationLink(destination: LeaderboardView()) {
                        Label("View Leaderboard", systemImage: "chart.bar.fill")
                    }
                }
                
                Section("App") {
                    Toggle("Debug", isOn: $isDebug)
                }
                
                Section("Danger Zone", footer: Text("This will reset the RC-Car settings")) {
                    Button("Reset", role: .destructive) {
                        onReset?()
                        print("Reset RC-Car")
                    }
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}
