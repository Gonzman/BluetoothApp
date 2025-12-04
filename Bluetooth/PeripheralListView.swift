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
        NavigationStack {
            VStack(spacing: 0) {
                if bluetoothService.peripherals.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Suche nach Geräten...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(bluetoothService.peripherals, id: \.self) { peripheral in
                        let bTN: String = bluetoothService.getPeripheralName(peripheral: peripheral)
                        
                        if !bTN.starts(with: "Nicht benanntes Gerät: ") && ((bTN.contains("FHS") || bTN.contains("BT05") || isExpert))
                        {
                            Button(action: {
                                bluetoothService.connect(peripheral: peripheral)
                            }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bluetoothService.getPeripheralName(peripheral: peripheral))
                                            .font(.body.weight(.medium))
                                            .foregroundColor(.primary)
                                        Text("Tippen zum Verbinden")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .disabled(isConnected)
                            .opacity(isConnected ? 0.5 : 1.0)
                        }
                    }
                    .listStyle(.insetGrouped)
                }

                if bluetoothService.peripheralStatus == .connected {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Verbunden mit \(bluetoothService.getPeripheralName(peripheral: bluetoothService.conPeripheral!))")
                            .font(.subheadline.weight(.medium))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                }
                
                HStack(spacing: 16) {
                    Button(action: {
                        isExpert.toggle()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isExpert ? "eye.slash" : "eye")
                            Text(isExpert ? "Alle ausblenden" : "Alle anzeigen")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.blue)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                    
                    Button(action: {
                        isSheetPresented.toggle()
                    }) {
                        Text("Abbrechen")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Gerät verbinden")
            .navigationBarTitleDisplayMode(.inline)
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
