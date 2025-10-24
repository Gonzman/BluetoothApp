//
//  PerepharieList.swift
//  Bluetooth
//
//  Created by Yuki Schäfer on 15.07.24.
//

import SwiftUI
import CoreBluetooth

struct PeripheralListView: View {
    @EnvironmentObject private var bluetoothService:Bluetooth
    @State private var expert: Bool = false
    
    var isConnected: Bool{
        return bluetoothService.peripheralStatus == .connecting || bluetoothService.peripheralStatus == .connected
    }
    
    var body: some View {
        List(bluetoothService.peripherals, id: \.self) { peripheral in
            if(!bluetoothService.getPeripheralName(peripheral: peripheral).starts(with: "Nicht benanntes Gerät: ") || expert ){
                Button(bluetoothService.getPeripheralName(peripheral: peripheral)) {
                bluetoothService.connect(peripheral: peripheral)
                }
                .listStyle(.plain)
                .disabled(isConnected)
                .strikethrough(isConnected)
            }
        }
        .navigationTitle("Bluetooth")
        .navigationBarTitleDisplayMode(.automatic)
        
        // Conditional rendering based on peripheralStatus
        if bluetoothService.peripheralStatus == .connected {
            Text(bluetoothService.getPeripheralName(peripheral: bluetoothService.conPeripheral!))
            
        }
    }
}

#Preview {
    PeripheralListView()
}
