import CoreBluetooth
import SwiftUI
import SwiftUIJoystick

var isConnectedGlobal: Bool = false

struct ContentView: View {
    @StateObject private var bluetoothService = Bluetooth()
    @StateObject private var monitor = JoystickMonitor()
    
    @State private var isBluetoothListShown = false
    @State private var isExpert = false
    @State private var boostLevel: CGFloat = 150
    @State private var isConnected = true
    @State private var showSettings = false
    @State private var isDebug = false
    
    private let nitroMax: CGFloat = 150

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Top Bar
            HStack {
                Button {
                    if !isConnected {
                        isBluetoothListShown.toggle()
                    }
                } label: {
                    Label(
                        isConnected ? "" : "Verbinden",
                        systemImage: "antenna.radiowaves.left.and.right"
                    )
                    .labelStyle(.titleAndIcon)
                    .opacity(isConnected ? 0.5 : 1)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                }
                .disabled(isConnected)
                .sheet(isPresented: $isBluetoothListShown) {
                    VStack {
                        PeripheralListView(isExpert: $isExpert)
                            .environmentObject(bluetoothService)
                        Button("Alle Anzeigen") { isExpert.toggle() }
                        Button("Abbrechen") { isBluetoothListShown.toggle() }
                    }
                    .padding()
                }

                Spacer()

                // MARK: Disconnect + Settings Section
                HStack(spacing: 0) {
                    // Disconnect Button
                    Button {
                        if isConnected {
                            bluetoothService.disconnect()
                            isConnected = false
                            isConnectedGlobal = false
                        }
                    } label: {
                        Label(
                            isConnected ? "Trennen" : "",
                            systemImage: "power"
                        )
                        .labelStyle(.titleAndIcon)
                        .opacity(isConnected ? 1 : 0.5)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                    }
                    .disabled(!isConnected)

                    Divider().frame(height: 28).padding(.horizontal, 6)

                    // Settings Button
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                            .font(.body)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                    }
                    .sheet(isPresented: $showSettings) {
                        SettingsView(isDebug: $isDebug)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10).stroke(
                        Color.gray.opacity(0.25)
                    )
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)

            Spacer()

            // MARK: Main Control Area
            HStack(alignment: .bottom, spacing: 20) {
                // MARK: Left Controls (Nitro, Boost, Y Bar)
                VStack(spacing: 18) {
                    VerticalBar(
                        label: "Nitro",
                        fillHeight: boostLevel,
                        maxHeight: nitroMax,
                        color: .blue
                    )
                    BoostButton(boostLevel: $boostLevel, maxLevel: nitroMax)
                        .frame(width: 110, height: 52)
                    YVerticalBar(
                        label: "Y",
                        yValue: monitor.xyPoint.y,
                        maxHeight: nitroMax,
                        color: .orange
                    )
                }
                .padding(.leading, 28)

                // MARK: X Bar
                HorizontalMover(value: monitor.xyPoint.x, rectWidth: 48)
                    .frame(height: 36)
                    .padding(.horizontal, 24)

                // MARK: Joystick (Right Corner)
                VStack {
                    Spacer()
                    Joystick(
                        monitor: monitor,
                        width: 300,
                        shape: .circle,
                        xID: 0,
                        yID: 1
                    )
                    .environmentObject(bluetoothService)
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
            .padding(.bottom, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { startNitroRecharge() }
    }

    // MARK: Nitro Recharge Logic
    func startNitroRecharge() {
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            if boostLevel < nitroMax {
                withAnimation(.linear(duration: 0.08)) {
                    boostLevel = min(nitroMax, boostLevel + 0.6)
                }
            } else {
                boostLevel = nitroMax
            }
        }
    }
}
