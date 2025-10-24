//
//  JoyStick.swift
//  Bluetooth
//
//  Created by Yuki Schäfer on 16.07.24.
//

import SwiftUI
import SwiftUIJoystick

struct Joystick: View {
    
    @EnvironmentObject var bluetoothService: Bluetooth
    
    @ObservedObject public var monitor: JoystickMonitor
    
    private let dragDiameter: CGFloat
    
    private let shape: JoystickShape
    
    private let xID: UInt8
    private let yID: UInt8
    
    
    public init(monitor: JoystickMonitor, width: CGFloat, shape: JoystickShape = .rect, xID: UInt8, yID: UInt8) {
        self.monitor = monitor
        self.dragDiameter = width
        self.shape = shape
        self.xID = xID
        self.yID = yID
    }
    
    public var body: some View {
        VStack{
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
                locksInPlace: false)
            .onChange(of: bluetoothService.peripheralStatus) {
                if bluetoothService.peripheralStatus == .connected {
                    Task{
                        try await Task.sleep(nanoseconds: 500000000)
                        startData()
                    }
                    
                }
            }
        }
    }
    
    func startData() {
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            if bluetoothService.peripheralStatus != .connected {
                timer.invalidate()
            }
            
            var channel: UInt8
            var data: UInt32
            
            channel = xID
            data = Float(monitor.xyPoint.x).bitPattern
            sendData(channel: &channel, data: data)
            
            channel = yID
            data = Float(monitor.xyPoint.y * -1).bitPattern
            sendData(channel: &channel, data: data)
        }
    }
    
    func sendData(channel: inout UInt8, data: UInt32){
        var packedData = Data()
        packedData.append(&channel, count: 1)       // 1 byte for channel
        packedData.append(withUnsafeBytes(of: data) { Data($0) })
        self.bluetoothService.conPeripheral?.writeValue(packedData, for: self.bluetoothService.conCharacteristics.last!, type: .withResponse)
        print(packedData as NSData)
    }
    
}
