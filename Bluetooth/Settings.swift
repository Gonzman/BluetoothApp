import SwiftUI

struct SettingsView: View {
    @ObservedObject var bluetoothService: Bluetooth
    @Binding var isConnected: Bool
    @Binding var isBluetoothListShown: Bool
    @Binding var isExpert: Bool
    @Binding var colorScheme: String
    
    var onReset: (() -> Void)? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        print("SettingsView: connect button tapped (isConnected: \(isConnected))")
                        if isConnected {
                            print("SettingsView: calling bluetoothService.disconnect()")
                            bluetoothService.disconnect()
                        } else {
                            isBluetoothListShown.toggle()
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill((isConnected ? Color.green : Color.blue).opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(isConnected ? .green : .blue)
                            }
                            Text(isConnected ? "Trennen" : "Verbinden")
                                .foregroundColor(isConnected ? .green : .blue)
                        }
                    }
                    .sheet(isPresented: $isBluetoothListShown) {
                        PeripheralListView(isExpert: $isExpert, isSheetPresented: $isBluetoothListShown)
                            .environmentObject(bluetoothService)
                    }
                } header: {
                    Text("Bluetooth")
                        .textCase(.uppercase)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Picker("Farbschema", selection: $colorScheme) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                            Text("Hell")
                        }.tag("light")
                        HStack {
                            Image(systemName: "moon.fill")
                            Text("Dunkel")
                        }.tag("dark")
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Appearance")
                        .textCase(.uppercase)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: {
                        bluetoothService.disconnect()
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
                            Text("Zurücksetzen")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Danger Zone")
                        .textCase(.uppercase)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                } footer: {
                    Text("Setzt das RC-Car zurück und stoppt alle laufenden Timer.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
