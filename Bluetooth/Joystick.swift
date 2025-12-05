import SwiftUI
import SwiftUIJoystick

struct Joystick: View {
    @EnvironmentObject var bluetoothService: Bluetooth
    @ObservedObject public var monitor: JoystickMonitor

    private let shape: JoystickShape

    private let dragDiameter: CGFloat

    private let xID: UInt8
    private let yID: UInt8

    @Binding var isBoosting: Bool

    public init(
        monitor: JoystickMonitor,
        width: CGFloat,
        shape: JoystickShape = .rect,
        xID: UInt8,
        yID: UInt8,
        isBoosting: Binding<Bool>
    ) {
        self.monitor = monitor
        self.dragDiameter = width
        self.shape = shape
        self.xID = xID
        self.yID = yID
        self._isBoosting = isBoosting
    }

    public var body: some View {
        VStack {
            JoystickBuilder(
                monitor: self.monitor,
                width: self.dragDiameter,
                shape: .circle,
                background: {

                    Circle().fill(Color.red.opacity(0.7))
                },
                foreground: {

                    Circle().fill(Color.blue)
                },
                locksInPlace: false
            )
            .onChange(of: bluetoothService.peripheralStatus) {
                if bluetoothService.peripheralStatus == .connected {
                    Task {
                        try await Task.sleep(nanoseconds: 500_000_000)
                        startData()
                    }

                }
            }
        }
    }

    func mapValue(
        _ value: Double,
        from: ClosedRange<Double>,
        to: ClosedRange<Double>
    ) -> Float {
        guard from.upperBound != from.lowerBound else {
            return Float(to.lowerBound)
        }
        let scaled =
            (value - from.lowerBound) / (from.upperBound - from.lowerBound)
        let mapped = to.lowerBound + scaled * (to.upperBound - to.lowerBound)
        let clamped = min(max(mapped, to.lowerBound), to.upperBound)
        return Float(clamped)
    }

    func startData() {
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            guard bluetoothService.peripheralStatus == .connected else {
                timer.invalidate()
                return
            }

            func sendMapped(
                _ id: inout UInt8,
                _ val: CGFloat,
                inputRange: ClosedRange<Double>,
                outputRange: ClosedRange<Double>,
                applyBoost: Bool = false
            ) {

                let clamped = max(min(val, 150), -150)

                if abs(clamped) < 1.0 {
                    let bits = Float(0.0).bitPattern
                    sendData(channel: &id, dataBits: bits)
                    return
                }

                let boost = CGFloat(
                    applyBoost && isBoosting && clamped > 0 ? 50 : 0
                )
                let base = clamped + boost

                let mappedFloat = mapValue(
                    Double(base),
                    from: inputRange,
                    to: outputRange
                )

                let bits = mappedFloat.bitPattern
                sendData(channel: &id, dataBits: bits)
            }

            var x = xID
            // Apply cubic smoothing - gradual near center, full range at extremes
            let normalizedX = monitor.xyPoint.x / 150.0  // Normalize to -1...1
            let sign = normalizedX >= 0 ? 1.0 : -1.0
            let smoothedX = sign * pow(abs(normalizedX), 3.0) * 150.0
            sendMapped(
                &x,
                smoothedX,
                inputRange: -150.0...150.0,
                outputRange: -200.0...200.0
            )

            var y = yID
            let yValue = monitor.xyPoint.y * -1

            let adjustedY = yValue < 0 ? yValue * 0.5 : yValue
            sendMapped(
                &y,
                adjustedY,
                inputRange: -150.0...200.0,
                outputRange: -150.0...255.0,
                applyBoost: true
            )
        }
    }

    func sendData(channel: inout UInt8, dataBits: UInt32) {
        var packedData = Data()
        packedData.append(&channel, count: 1)
        var bitsLE = dataBits
        withUnsafeBytes(of: &bitsLE) { rawBuf in
            packedData.append(rawBuf.bindMemory(to: UInt8.self))
        }
        self.bluetoothService.conPeripheral?.writeValue(
            packedData,
            for: self.bluetoothService.conCharacteristics.last!,
            type: .withResponse
        )
    }
}
