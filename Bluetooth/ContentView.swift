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
    @State private var isBoosting = false
    
    @State private var isStopwatchRunning = false
    @State private var stopwatchStartDate: Date? = nil
    @State private var elapsedTime: TimeInterval = 0
    @State private var hasReceivedFirstJoystickInput = false
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    private let nitroMax: CGFloat = 150

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Stopwatch Top-Center
            HStack {
                Spacer()
                VStack(spacing: 6) {
                    Text(formattedElapsed(elapsedTime))
                        .font(.system(size: 28, weight: .semibold, design: .monospaced))
                        .accessibilityLabel("Stopwatch time")
                }
                Spacer()
            }
            .padding(.top, 8)
            .onReceive(timer) { _ in
                guard isStopwatchRunning, let start = stopwatchStartDate else { return }
                elapsedTime = Date().timeIntervalSince(start)
            }
            
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
                        Label("Einstellungen", systemImage: "gearshape.fill")
                            .font(.body)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                    }
                    .sheet(isPresented: $showSettings) {
                        SettingsView(isDebug: $isDebug, onReset: {
                            resetStopwatch()
                        })
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
                        .simultaneousGesture(DragGesture(minimumDistance: 0)
                            .onChanged { _ in isBoosting = true }
                            .onEnded { _ in isBoosting = false })
                    
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
                    .onChange(of: isBoosting) { oldValue, newValue in
                        // Activate boost while button is pressed
                        // Add +50 in Joystick's startData via isBoostActive
                        Joystick(monitor: monitor, width: 300, shape: .circle, xID: 0, yID: 1).boost(newValue)
                    }
                    .onChange(of: monitor.xyPoint) { oldPoint, newPoint in
                        // Start stopwatch on first joystick input
                        if !hasReceivedFirstJoystickInput {
                            hasReceivedFirstJoystickInput = true
                            startStopwatch()
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
            .padding(.bottom, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formattedElapsed(_ interval: TimeInterval) -> String {
        let totalMilliseconds = Int((interval * 1000).rounded())
        let minutes = totalMilliseconds / 60000
        let seconds = (totalMilliseconds % 60000) / 1000
        let milliseconds = (totalMilliseconds % 1000) / 10 // two digits
        return String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
    }

    private func startStopwatch() {
        if !isStopwatchRunning {
            stopwatchStartDate = Date().addingTimeInterval(-elapsedTime)
            isStopwatchRunning = true
        }
    }

    private func stopStopwatch() {
        isStopwatchRunning = false
    }

    private func resetStopwatch() {
        stopStopwatch()
        elapsedTime = 0
        stopwatchStartDate = nil
        hasReceivedFirstJoystickInput = false
    }
}
