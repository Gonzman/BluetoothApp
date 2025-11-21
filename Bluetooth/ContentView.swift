import CoreBluetooth
import SwiftUI
import SwiftUIJoystick

var isConnectedGlobal: Bool = false

struct ContentView: View {
    @StateObject private var bluetoothService = Bluetooth()
    @StateObject private var monitor = JoystickMonitor()
    
    @State private var isBluetoothListShown = false
    @State private var isExpert = false
    @State private var isConnected = true
    @State private var showSettings = false
    @State private var isDebug = false
    @State private var isBoosting = false
    
    @State private var isStopwatchRunning = false
    @State private var stopwatchStartDate: Date? = nil
    @State private var elapsedTime: TimeInterval = 0
    @State private var hasReceivedFirstJoystickInput = false
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    @State private var nitroLevel: CGFloat = 150
    private let nitroMax: CGFloat = 150
    private let joystickMax: CGFloat = 300

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Top Bar
            HStack {
                // Left: Connect/Disconnect Toggle Button (kept inside its own HStack)
                HStack(spacing: 0) {
                    Button {
                        if isConnected {
                            // Disconnect when connected
                            bluetoothService.disconnect()
                            isConnected = false
                            isConnectedGlobal = false
                        } else {
                            // Show peripheral list to connect when disconnected
                            isBluetoothListShown.toggle()
                        }
                    } label: {
                        Label(isConnected ? "Trennen" : "Verbinden", systemImage: "antenna.radiowaves.left.and.right")
                            .labelStyle(.titleAndIcon)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.25))
                            )
                    }
                    .sheet(isPresented: $isBluetoothListShown) {
                        VStack {
                            PeripheralListView(isExpert: $isExpert)
                                .environmentObject(bluetoothService)
                            Button("Alle Anzeigen") { isExpert.toggle() }
                            Button("Abbrechen") { isBluetoothListShown.toggle() }
                        }
                        .padding()
                    }
                }

                Spacer()

                // Right: Settings Button (icon only, no HStack wrapper)
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.body)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(isDebug: $isDebug, onReset: {
                        reset()
                    })
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            
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
            
            GaugeViewXKRepresentable(
                goToValue: .constant(Double(max((monitor.xyPoint.y * -1) + (isBoosting ? 50 : 0), -50))),
                gaugeValues: .range(start: -50, end: joystickMax + 50, parts: 10),
                gaugeColor: .gradient([.green, .yellow, .red]),
                        gaugeWidth: 20
                    )
                    .frame(width: 250, height: 250)
                    .padding()
            
            Spacer()
            
            
            
            // MARK: Main Control Area
            HStack(alignment: .bottom, spacing: 0) {
                // Left bottom corner: Nitro + Boost
                VStack() {
                    HStack {
                        VerticalBar(
                            label: "Nitro",
                            fillHeight: nitroLevel,
                            color: .blue
                        )
                    }
                    .frame(width: 200, height: nitroMax, alignment: .center)

                    BoostButton(boostLevel: $nitroLevel, enabled: isStopwatchRunning, maxLevel: nitroMax)
                        .frame(width: 200, height: 200)
                        .simultaneousGesture(DragGesture(minimumDistance: 0)
                            .onChanged { _ in isBoosting = true }
                            .onEnded { _ in isBoosting = false })
                }
                .padding([.leading, .bottom], 24)

                Spacer(minLength: 0)

                // Right bottom corner: Joystick
                VStack {
                    Joystick(
                        monitor: monitor,
                        width: joystickMax,
                        shape: .circle,
                        xID: 0,
                        yID: 1
                    )
                    .environmentObject(bluetoothService)
                    .onChange(of: isBoosting) { oldValue, newValue in
                        Joystick(monitor: monitor, width: 300, shape: .circle, xID: 0, yID: 1).boost(newValue)
                    }
                    .onChange(of: monitor.xyPoint) { oldPoint, newPoint in
                        // Start stopwatch on first joystick input
                        if !hasReceivedFirstJoystickInput {
                            hasReceivedFirstJoystickInput = true
                            startStopwatch()
                        }
                    }
                }
                .padding([.trailing, .bottom], 24)
            }

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

    private func reset() {
        // Reset Stopwatch
        stopStopwatch()
        elapsedTime = 0
        stopwatchStartDate = nil
        hasReceivedFirstJoystickInput = false
        
        // Reset Nitro
        nitroLevel = 150
    }
}

