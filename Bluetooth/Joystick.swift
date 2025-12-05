import SwiftUI
import SwiftUIJoystick

struct Joystick: View {
    @EnvironmentObject var bluetoothService: Bluetooth
    @ObservedObject public var monitor: JoystickMonitor
    
    private let shape: JoystickShape
    
    private let dragDiameter: CGFloat
    
    private let xID: UInt8
    private let yID: UInt8
    
    private let isBoosting: Bool
    
    public init(
        monitor: JoystickMonitor,
        width: CGFloat,
        shape: JoystickShape = .rect,
        xID: UInt8,
        yID: UInt8,
        isBoosting: Bool = false
    ) {
        self.monitor = monitor
        self.dragDiameter = width
        self.shape = shape
        self.xID = xID
        self.yID = yID
        self.isBoosting = isBoosting
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
    
    /// Maps a value from one range to another safely using Double math, returning a Float.
    /// The result is clamped to the destination range to avoid out-of-range conversions.
    func mapValue(_ value: Double, from: ClosedRange<Double>, to: ClosedRange<Double>) -> Float {
        guard from.upperBound != from.lowerBound else { return Float(to.lowerBound) }
        let scaled = (value - from.lowerBound) / (from.upperBound - from.lowerBound)
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
            
            func sendMapped(_ id: inout UInt8, _ val: CGFloat, inputRange: ClosedRange<Double>, outputRange: ClosedRange<Double>, applyBoost: Bool = false) {
                // Clamp input to ±150, which represents full range of joystick
                let clamped = max(min(val, 150), -150)
                
                // Handle idle position (close to 0)
                if abs(clamped) < 1.0 {
                    let bits = Float(0.0).bitPattern
                    sendData(channel: &id, dataBits: bits)
                    return
                }
                
                // Apply boost if active (adds to positive values only)
                let boost = CGFloat(applyBoost && isBoosting && clamped > 0 ? 50 : 0)
                let base = clamped + boost
                
                // Map from input range to output range
                let mappedFloat = mapValue(
                    Double(base),
                    from: inputRange,
                    to: outputRange
                )
                // Transmit as 32-bit float bit pattern
                let bits = mappedFloat.bitPattern
                sendData(channel: &id, dataBits: bits)
            }

            var x = xID
            sendMapped(&x, monitor.xyPoint.x, inputRange: -150.0...150.0, outputRange: -200.0...200.0)
            
            var y = yID
            let yValue = monitor.xyPoint.y * -1
            // Apply half value when moving backwards (negative value)
            let adjustedY = yValue < 0 ? yValue * 0.5 : yValue
            sendMapped(&y, adjustedY, inputRange: -150.0...200.0, outputRange: -150.0...255.0, applyBoost: true)
        }
    }

    func sendData(channel: inout UInt8, dataBits: UInt32) {
        var packedData = Data()
        packedData.append(&channel, count: 1)  // 1 byte for channel
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
