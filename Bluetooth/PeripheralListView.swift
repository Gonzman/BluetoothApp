import CoreBluetooth
import SwiftUI

struct PeripheralListView: View {
    @EnvironmentObject private var bluetoothService: Bluetooth
    @Binding public var isExpert: Bool

    var isConnected: Bool {
        return bluetoothService.peripheralStatus == .connecting
            || bluetoothService.peripheralStatus == .connected
    }

    var body: some View {
        List(bluetoothService.peripherals, id: \.self) { peripheral in
            let bTN: String = bluetoothService.getPeripheralName(peripheral: peripheral)
            
            if !bTN.starts(with: "Nicht benanntes Gerät: ") && (bTN.contains("Yuki") || isExpert)
            {
                    Button(
                        bluetoothService.getPeripheralName(peripheral: peripheral)
                    ) {
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
            Text(
                bluetoothService.getPeripheralName(
                    peripheral: bluetoothService.conPeripheral!
                )
            )

        }
    }
}
