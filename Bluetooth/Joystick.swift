import SwiftUI
import SwiftUIJoystick

struct Joystick: View {
    @EnvironmentObject var bluetoothService: Bluetooth
    @ObservedObject public var monitor: JoystickMonitor
    
    private let shape: JoystickShape
    
    private let dragDiameter: CGFloat
    
    private let xID: UInt8
    private let yID: UInt8
    
    @State private var isBoostActive: Bool = false
    
    public var boostBinding: Binding<Bool> {
        Binding<Bool>(
            get: { self.isBoostActive },
            set: { self.isBoostActive = $0 }
        )
    }
    
    public func boost(_ active: Bool) {
        // Activate or deactivate boost. When active, outgoing values add +50 in startData()
        self.isBoostActive = active
    }
    
    public init(
        monitor: JoystickMonitor,
        width: CGFloat,
        shape: JoystickShape = .rect,
        xID: UInt8,
        yID: UInt8,
    ) {
        self.monitor = monitor
        self.dragDiameter = width
        self.shape = shape
        self.xID = xID
        self.yID = yID
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
            
            func sendMapped(_ id: inout UInt8, _ val: CGFloat) {
                // Clamp input to ±150, which represents full range of joystick
                let clamped = max(min(val, 150), -150)
                
                // Handle idle position (close to 0)
                if abs(clamped) < 1.0 {
                    let bits = Float(0.0).bitPattern
                    sendData(channel: &id, dataBits: bits)
                    return
                }
                
                // Apply boost if active (adds to positive values only)
                let boost = CGFloat(isBoostActive && clamped > 0 ? 50 : 0)
                let base = clamped + boost
                
                // Map from joystick range to output range
                // At rest (0): maps to 0. Full reverse (-150): maps to -150. Full forward (+150): maps to 191.25.
                // With boost: full forward (+200) maps to 255
                let mappedFloat = mapValue(
                    Double(base),
                    from: -150.0...200.0,
                    to: -150.0...255.0
                )
                // Transmit as 32-bit float bit pattern
                let bits = mappedFloat.bitPattern
                sendData(channel: &id, dataBits: bits)
            }

            var x = xID
            sendMapped(&x, monitor.xyPoint.x)
            
            var y = yID
            sendMapped(&y, monitor.xyPoint.y * -1)
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
