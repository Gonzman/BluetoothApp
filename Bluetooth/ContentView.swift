//
//  ContentView.swift
//  Bluetooth
//
//  Created by Yuki Schäfer on 12.07.24.
//

import CoreBluetooth
import Foundation
import SwiftUI
import SwiftUIJoystick

struct ContentView: View {
    @StateObject private var bluetoothService: Bluetooth = Bluetooth()
    @StateObject private var monitor = JoystickMonitor()
    @State private var isBluetoothListShown = false
    private let draggableDiameter: CGFloat = 150
    var body: some View {
        VStack {
            HStack {
                Button(
                    "Verbinden",
                    systemImage: "antenna.radiowaves.left.and.right"
                ) {
                    isBluetoothListShown.toggle()
                }.sheet(isPresented: $isBluetoothListShown) {
                    VStack {
                        PeripheralListView()
                            .environmentObject(bluetoothService)
                        Button(
                            "Dismiss",
                            action: { isBluetoothListShown.toggle() }
                        )
                    }
                }.padding(15)

                Spacer()

                Button("Trennen") {
                    bluetoothService.disconnect()
                }
                .buttonStyle(.bordered).disabled(
                    bluetoothService.peripheralStatus != .connected
                )
                .padding(15)
            }
            Spacer()
            //um 45 Grad nach Links verschoben 90Grad am Joystick sind 45 Grad als ausgabe wert
            Text("X: \(monitor.xyPoint.x)")
            Text("Y: \(monitor.xyPoint.y * -1)")

            HStack {
                Spacer()
                Joystick(
                    monitor: monitor,
                    width: 200,
                    shape: .circle,
                    xID: 0,
                    yID: 1
                ).padding(60)
                    .environmentObject(bluetoothService)
            }
        }
    }

    func didDismiss() {
        isBluetoothListShown.toggle()
    }
}

#Preview {
    ContentView()
}
