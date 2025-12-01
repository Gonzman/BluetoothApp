import CoreBluetooth
import SwiftUI
import SwiftUIJoystick

var isConnectedGlobal: Bool = false

struct ContentView: View {
    @StateObject private var bluetoothService = Bluetooth()
    @StateObject private var monitor = JoystickMonitor()
    
    private let backend = Backend(host: "localhost", port: 3000)
    
    @State private var isBluetoothListShown = false
    @State private var isExpert = false
    @State private var isConnected = false
    @State private var showSettings = false
    @State private var showLeaderboard = false
    @State private var isDebug = false
    @State private var isBoosting = false
    
    @State private var isStopwatchRunning = false
    @State private var stopwatchStartDate: Date? = nil
    @State private var elapsedTime: TimeInterval = 0
    @State private var hasReceivedFirstJoystickInput = false
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State private var leaderboardRefreshTimer: Timer? = nil
    
    @State private var nitroLevel: CGFloat = 150
    private let nitroMax: CGFloat = 150
    private let joystickMax: CGFloat = 300
    
    private var isBoostButtonEnabled: Bool {
        isStopwatchRunning && nitroLevel > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Top Bar
            HStack {
                HStack(spacing: 0) {
                    Button {
                        print("ContentView: connect button tapped (isConnected: \(isConnected))")
                        if isConnected {
                            print("ContentView: calling bluetoothService.disconnect()")
                            bluetoothService.disconnect()
                        } else {
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
                        PeripheralListView(isExpert: $isExpert, isSheetPresented: $isBluetoothListShown)
                            .environmentObject(bluetoothService)
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
                goToValue: .constant(Double(abs((monitor.xyPoint.y * -1) + ((isBoostButtonEnabled && isBoosting) ? 50 : 0)))),
                gaugeValues: .range(start: 0, end: joystickMax + 50, parts: 10),
                gaugeColor: .gradient([.green, .yellow, .red]),
                        gaugeWidth: 20
                    )
                    .frame(width: 250, height: 250)
                    .padding()
            
            Spacer()
            
            
            
            // MARK: Main Control Area
            HStack(alignment: .bottom, spacing: 0) {
                VStack() {
                    HStack {
                        VerticalBar(
                            label: "Nitro",
                            fillHeight: nitroLevel,
                            color: .blue
                        )
                    }
                    .frame(width: 200, height: nitroMax, alignment: .center)

                    BoostButton(boostLevel: $nitroLevel, isBoosting: $isBoosting, enabled: isBoostButtonEnabled, maxLevel: nitroMax)
                        .frame(width: 200, height: 200)
                }
                .padding([.leading, .bottom], 24)

                Spacer(minLength: 0)

                VStack {
                    Joystick(
                        monitor: monitor,
                        width: joystickMax,
                        shape: .circle,
                        xID: 0,
                        yID: 1
                    )
                    .environmentObject(bluetoothService)
                    .onChange(of: monitor.xyPoint) { oldPoint, newPoint in
                        if !hasReceivedFirstJoystickInput {
                            start()
                        }
                    }
                }
                .padding([.trailing, .bottom], 24)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: bluetoothService.peripheralStatus) { oldStatus, newStatus in
            print("ContentView: peripheralStatus changed from \(oldStatus) to \(newStatus)")
            switch newStatus {
            case .connected:
                isConnected = true
                isConnectedGlobal = true
                isBluetoothListShown = false
            case .connecting:
                isConnected = true
            case .disconnected:
                isConnected = false
                isConnectedGlobal = false
                reset()
            case .error:
                // treat error like disconnected so UI resets
                isConnected = false
                isConnectedGlobal = false
                isBluetoothListShown = false
                reset()
            default:
                break
            }
        }
        .onAppear {
            // Set up bluetooth command listeners
            bluetoothService.onReceiveStart = {
                self.start()
            }
            bluetoothService.onReceiveStop = {
                self.stopStopwatch()
            }
        }
        .sheet(isPresented: $showLeaderboard, onDismiss: {
            stopLeaderboardRefresh()
        }) {
            LeaderboardView()
                .onAppear {
                    startLeaderboardRefresh()
                }
        }
    }
    
    private func startLeaderboardRefresh() {
        leaderboardRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            fetchLeaderboard()
        }
    }
    
    private func stopLeaderboardRefresh() {
        leaderboardRefreshTimer?.invalidate()
        leaderboardRefreshTimer = nil
    }
    
    private func formattedElapsed(_ interval: TimeInterval) -> String {
        let totalMilliseconds = Int((interval * 1000).rounded())
        let minutes = totalMilliseconds / 60000
        let seconds = (totalMilliseconds % 60000) / 1000
        let milliseconds = (totalMilliseconds % 1000) / 10 // two digits
        return String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
    }

    private func start() {
        if !hasReceivedFirstJoystickInput {
            hasReceivedFirstJoystickInput = true
        }
        startStopwatch()
    }

    private func startStopwatch() {
        if !isStopwatchRunning {
            stopwatchStartDate = Date().addingTimeInterval(-elapsedTime)
            isStopwatchRunning = true
        }
    }

    private func stopStopwatch() {
        isStopwatchRunning = false
        
        // Generate random score and post dummy player data
        let randomScore = Int.random(in: 50...500)
        backend.post(endpoint: "player", queryParams: ["name": "Player1", "score": String(randomScore)]) { data, error in
            if let error = error {
                print("Error posting player: \(error)")
                return
            }
            
            // After posting, fetch the leaderboard and open it
            self.fetchLeaderboard {
                DispatchQueue.main.async {
                    self.showLeaderboard = true
                }
            }
        }
    }
    
    private func fetchLeaderboard(completion: (() -> Void)? = nil) {
        backend.get(endpoint: "leaderboard") { data, error in
            if let error = error {
                print("Error fetching leaderboard: \(error)")
                completion?()
                return
            }
            
            guard let data = data else {
                print("No data received from leaderboard")
                completion?()
                return
            }
            
            do {
                let entries = try JSONDecoder().decode([LeaderboardEntry].self, from: data)
                LeaderboardStore.shared.mergeEntries(with: entries)
            } catch {
                print("Error decoding leaderboard: \(error)")
            }
            completion?()
        }
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

