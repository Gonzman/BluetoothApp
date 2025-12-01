import SwiftUI

struct SettingsView: View {
    @Binding var isDebug: Bool
    var onReset: (() -> Void)? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink(destination: LeaderboardView()) {
                        Label("View Leaderboard", systemImage: "chart.bar.fill")
                    }
                } header: {
                    Text("Leaderboard")
                }
                
                Section {
                    Toggle("Debug", isOn: $isDebug)
                } header: {
                    Text("App")
                }
                
                Section {
                    Button("Reset", role: .destructive) {
                        onReset?()
                        print("Reset RC-Car")
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This will reset the RC-Car settings")
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}
