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
    
    func mapValue(_ value: UInt32, from: ClosedRange<UInt32>, to: ClosedRange<Double>) -> UInt32 {
        let scaled = Double(value - from.lowerBound) / Double(from.upperBound - from.lowerBound)
        return UInt32(to.lowerBound + scaled * (to.upperBound - to.lowerBound))
    }

    func startData() {
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            guard bluetoothService.peripheralStatus == .connected else {
                timer.invalidate()
                return
            }
            
            func sendMapped(_ id: inout UInt8, _ val: CGFloat) {
                let data = Float(min(val, 150) + CGFloat(isBoostActive ? 50 : 0)).bitPattern
                let mapped = mapValue(data, from: 0...UInt32.max, to: 0...200)
                sendData(channel: &id, data: mapped)
            }

            var x = xID
            sendMapped(&x, monitor.xyPoint.x)
            
            var y = yID
            sendMapped(&y, monitor.xyPoint.y * -1)
        }
    }

    func sendData(channel: inout UInt8, data: UInt32) {
        var packedData = Data()
        packedData.append(&channel, count: 1)  // 1 byte for channel
        packedData.append(withUnsafeBytes(of: data) { Data($0) })
        self.bluetoothService.conPeripheral?.writeValue(
            packedData,
            for: self.bluetoothService.conCharacteristics.last!,
            type: .withResponse
        )
        print(packedData as NSData)
    }
}
