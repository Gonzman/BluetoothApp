import SwiftUI

struct ThrottleBar: View {
    @EnvironmentObject var bluetoothService: Bluetooth
    
    @State private var throttleValue: CGFloat = 0  // -1 (backward) to 1 (forward)
    @Binding var isBoosting: Bool
    @Binding var currentSpeed: CGFloat
    
    private let yID: UInt8 = 1  // Throttle channel
    
    var body: some View {
        // Vertical throttle bar (forward/backward)
        DraggableBar(
            label: "Throttle",
            orientation: .vertical,
            value: $throttleValue,
            color: Color.green,
            trackWidth: 100,
            trackHeight: 350
        )
        .onChange(of: bluetoothService.peripheralStatus) {
            if bluetoothService.peripheralStatus == .connected {
                Task {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    startThrottleData()
                }
            }
        }
        .onChange(of: throttleValue) {
            updateCurrentSpeed()
        }
        .onChange(of: isBoosting) {
            updateCurrentSpeed()
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
    
    func startThrottleData() {
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            guard bluetoothService.peripheralStatus == .connected else {
                timer.invalidate()
                return
            }
            
            var y = yID
            var outputValue: CGFloat = 0.0
            
            if throttleValue > 0.01 {
                outputValue = throttleValue * 200.0
                if isBoosting {
                    outputValue = outputValue + 55.0
                }
            } else if throttleValue < -0.01 {
                outputValue = throttleValue * 50.0
            }
            
            let bits = Float(outputValue).bitPattern
            sendData(channel: &y, dataBits: bits)
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
    
    private func updateCurrentSpeed() {
        var outputValue: CGFloat
        if throttleValue > 0 {
            outputValue = throttleValue * 200.0
            if isBoosting {
                outputValue = outputValue + 55.0
            }
        } else {
            outputValue = throttleValue * 50.0
        }
        currentSpeed = abs(outputValue)
    }
}

struct RCControlBars: View {
    @EnvironmentObject var bluetoothService: Bluetooth
    
    @State private var steeringValue: CGFloat = 0
    
    @Binding var isBoosting: Bool
    @Binding var currentSpeed: CGFloat
    
    private let xID: UInt8 = 0
    
    var body: some View {
        DraggableBar(
            label: "Steering",
            orientation: .horizontal,
            value: $steeringValue,
            color: Color.blue,
            trackWidth: 350,
            trackHeight: 100
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
    
    func startData() {
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            guard bluetoothService.peripheralStatus == .connected else {
                timer.invalidate()
                return
            }
            
            var x = xID
            
            if abs(steeringValue) < 0.01 {
                let bits = Float(0.0).bitPattern
                sendData(channel: &x, dataBits: bits)
                return
            }
            
            let outputValue = steeringValue * 200.0
            let bits = Float(outputValue).bitPattern
            sendData(channel: &x, dataBits: bits)
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

