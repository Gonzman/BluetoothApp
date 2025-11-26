import CoreBluetooth
import SwiftUI

struct PeripheralListView: View {
    @EnvironmentObject private var bluetoothService: Bluetooth
    @Binding public var isExpert: Bool
    @Binding public var isSheetPresented: Bool

    var isConnected: Bool {
        return bluetoothService.peripheralStatus == .connecting
            || bluetoothService.peripheralStatus == .connected
    }

    var body: some View {
        VStack {
            List(bluetoothService.peripherals, id: \.self) { peripheral in
                let bTN: String = bluetoothService.getPeripheralName(peripheral: peripheral)
                
                if !bTN.starts(with: "Nicht benanntes Gerät: ") && ((bTN.contains("FHS") || bTN.contains("BT05") || isExpert))
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

            if bluetoothService.peripheralStatus == .connected {
                Text(
                    bluetoothService.getPeripheralName(
                        peripheral: bluetoothService.conPeripheral!
                    )
                )
            }
            
            HStack(spacing: 12) {
                Button(isExpert ? "Verbergen" : "Alle Anzeigen") {
                    isExpert.toggle()
                }
                .frame(maxWidth: .infinity)
                
                Button("Abbrechen") {
                    isSheetPresented.toggle()
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .onChange(of: bluetoothService.peripheralStatus) { oldStatus, newStatus in
            if newStatus == .connected {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSheetPresented = false
                }
            }
        }
    }
}
