import SwiftUI

struct SettingsView: View {
    @Binding var isDebug: Bool
    var onReset: (() -> Void)? = nil
    
    var body: some View {
        Form {
            Toggle("Debug", isOn: $isDebug)
            Button("Reset", role: .destructive) {
                onReset?()
            }
        }
        .padding()
        .navigationTitle("Einstellungen")
    }
}
