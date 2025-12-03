import SwiftUI

@main
struct BluetoothApp: App {
    @State private var colorScheme: String = "dark"
    
    private var selectedColorScheme: ColorScheme {
        switch colorScheme {
        case "light": return .light
        default: return .dark
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(colorScheme: $colorScheme)
                .preferredColorScheme(selectedColorScheme)
        }
    }
}
