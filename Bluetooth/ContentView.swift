import CoreBluetooth
import SwiftUI

var isConnectedGlobal: Bool = false

struct ContentView: View {
    @Binding var colorScheme: String
    
    @StateObject private var bluetoothService = Bluetooth()
    
    private let backend = Backend(host: "auto.offen.schaefer.jp", port: 443)
    
    @State private var isBluetoothListShown = false
    @State private var isExpert = false
    @State private var isConnected = false
    @State private var showSettings = false
    @State private var showLeaderboard = false
    @State private var isBoosting = false
    
    @State private var isStopwatchRunning = false
    @State private var stopwatchStartDate: Date? = nil
    @State private var elapsedTime: TimeInterval = 0
    @State private var hasReceivedBluetoothStart = false
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State private var leaderboardRefreshTimer: Timer? = nil
    
    @State private var showNameEntry = false
    @State private var playerName = ""
    @State private var pendingScore: Double = 0
    
    @State private var nitroLevel: CGFloat = 150
    private let nitroMax: CGFloat = 150
    
    @State private var currentSpeed: CGFloat = 0
    
    private var isBoostButtonEnabled: Bool {
        isStopwatchRunning && nitroLevel > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Top Bar
            HStack {
                
                Button {
                    showLeaderboard = true
                } label: {
                    Label("Leaderboard", systemImage: "chart.bar.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.medium))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.25), lineWidth: 1)
                        )
                }
                .foregroundColor(.blue)

                Spacer()

                
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                        )
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(
                        bluetoothService: bluetoothService,
                        isConnected: $isConnected,
                        isBluetoothListShown: $isBluetoothListShown,
                        isExpert: $isExpert,
                        colorScheme: $colorScheme,
                        onReset: {
                            reset()
                        }
                    )
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)
            
            // MARK: Stopwatch Top-Center
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Text(formattedElapsed(elapsedTime))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(isStopwatchRunning ? .primary : .secondary)
                        .accessibilityLabel("Stopwatch time")
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground).opacity(0.8))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                Spacer()
            }
            .padding(.top, 12)
            .onReceive(timer) { _ in
                guard isStopwatchRunning, let start = stopwatchStartDate else { return }
                elapsedTime = Date().timeIntervalSince(start)
            }
            
            GaugeViewXKRepresentable(
                goToValue: .constant(Double(currentSpeed)),
                gaugeValues: .range(start: 0, end: 250, parts: 10),
                gaugeColor: .gradient([.green, .yellow, .red]),
                gaugeWidth: 22
            )
            .frame(width: 240, height: 240)
            .padding(.top, 8)
            
            Spacer()
            
            // MARK: Main Control Area
            HStack(alignment: .bottom, spacing: 0) {
                
                HStack(alignment: .bottom, spacing: 24) {
                    ThrottleBar(
                        isBoosting: Binding(
                            get: { isBoosting && isBoostButtonEnabled },
                            set: { _ in }
                        ),
                        currentSpeed: $currentSpeed
                    )
                    .environmentObject(bluetoothService)
                    
                    VStack(spacing: 16) {
                        VerticalBar(
                            label: "Nitro",
                            fillHeight: nitroLevel,
                            color: Color(red: 0.2, green: 0.5, blue: 1.0)
                        )
                        .frame(width: 100, height: nitroMax, alignment: .center)
                        
                        BoostButton(
                            boostLevel: $nitroLevel,
                            isBoosting: $isBoosting,
                            enabled: isBoostButtonEnabled,
                            maxLevel: nitroMax
                        )
                        .frame(width: 100, height: 100)
                    }
                }
                .padding(.leading, 32)
                .padding(.bottom, 32)

                Spacer(minLength: 0)

                
                VStack {
                    RCControlBars(
                        isBoosting: Binding(
                            get: { isBoosting && isBoostButtonEnabled },
                            set: { _ in }
                        ),
                        currentSpeed: $currentSpeed
                    )
                    .environmentObject(bluetoothService)
                }
                .padding(.trailing, 32)
                .padding(.bottom, 32)
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
                
                isConnected = false
                isConnectedGlobal = false
                isBluetoothListShown = false
                reset()
            default:
                break
            }
        }
        .onAppear {
            
            bluetoothService.onReceiveStart = {
                self.start()
            }
            bluetoothService.onReceiveStop = {
                self.stopStopwatch()
            }
        }
        .sheet(isPresented: $showNameEntry) {
            NameEntryView(
                isPresented: $showNameEntry,
                playerName: $playerName,
                score: formattedElapsed(pendingScore),
                onSubmit: {
                    submitPlayerScore()
                }
            )
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
        if !hasReceivedBluetoothStart {
            hasReceivedBluetoothStart = true
        }
        showLeaderboard = false
        startStopwatch()
    }

    private func startStopwatch() {
        if !isStopwatchRunning {
            stopwatchStartDate = Date().addingTimeInterval(-elapsedTime)
            isStopwatchRunning = true
        }
    }

    private func stopStopwatch() {
        guard isStopwatchRunning else { return }
        isStopwatchRunning = false
        
        
        pendingScore = elapsedTime
        playerName = ""
        showNameEntry = true
        
        
        elapsedTime = 0
        stopwatchStartDate = nil
        
        
        nitroLevel = nitroMax
    }
    
    private func resetStopwatch() {
        isStopwatchRunning = false
        elapsedTime = 0
        stopwatchStartDate = nil
        hasReceivedBluetoothStart = false
    }
    
    private func submitPlayerScore() {
        let name = playerName.trimmingCharacters(in: .whitespaces).isEmpty ? "Player" : playerName
        let formattedScore = formattedElapsed(pendingScore) // Already in mm:ss:ms format
        
        
        let newEntry = LeaderboardEntry(name: name, score: formattedScore)
        LeaderboardStore.shared.entries.append(newEntry)
        
        
        showNameEntry = false
        
        
        backend.post(endpoint: "player", queryParams: ["name": name, "score": formattedScore]) { data, error in
            if let error = error {
                print("Error posting player: \(error)")
            }
            
            
            self.fetchLeaderboard {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
        
        resetStopwatch()
        
        
        nitroLevel = 150
    }
}

struct NameEntryView: View {
    @Binding var isPresented: Bool
    @Binding var playerName: String
    let score: String
    let onSubmit: () -> Void
    
    var isValid: Bool {
        !playerName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                
                
                ZStack {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.yellow.opacity(0.3))
                        .blur(radius: 20)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                
                VStack(spacing: 6) {
                    Text("Your Time")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                    Text(score)
                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Dein Name")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                    TextField("Name", text: $playerName)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(playerName.isEmpty ? 0 : 0.5), lineWidth: 2)
                        )
                        .font(.title3)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 48)
                
                Spacer()
                
                
                Button(action: {
                    onSubmit()
                }) {
                    Text("Absenden")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isValid ? Color.blue : Color.gray.opacity(0.5))
                        )
                        .shadow(color: isValid ? Color.blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                }
                .disabled(!isValid)
                .padding(.horizontal, 48)
                .padding(.bottom, 48)
            }
            .navigationTitle("Rennen Beendet!")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }
}

