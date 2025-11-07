import SwiftUI

struct SettingsView: View {
    @Binding var isDebug: Bool
    
    var body: some View {
        Form {
            Toggle("Debug", isOn: $isDebug)
        }
        .padding()
        .navigationTitle("Einstellungen")
    }
}
