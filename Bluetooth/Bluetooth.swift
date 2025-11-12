import CoreBluetooth
import SwiftUI

enum Status {
    case scanning
    case disconnected
    case connecting
    case error
    case connected
}

class Bluetooth: NSObject, ObservableObject {
    private let useUUID: Bool = false
    private let cbUUID: CBUUID = CBUUID(
        string: "68b696d7-320b-4402-a412-d9cee10fc6a3"
    )
    private var centralManger: CBCentralManager?

    @Published var peripherals: [CBPeripheral] = []
    @Published var peripheralNames: [String] = []
    @Published var peripheralStatus: Status = .disconnected
    @Published var conPeripheral: CBPeripheral?
    @Published var conPeripheralDescriptor: CBDescriptor?
    @Published var conServices: [CBService] = []
    @Published var conCharacteristics: [CBCharacteristic] = []

    override init() {
        super.init()
        self.centralManger = CBCentralManager(delegate: self, queue: .main)
    }
}

extension Bluetooth: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.scanForPeripherals()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        if !peripherals.contains(peripheral) {
            self.peripherals.append(peripheral)

            self.peripheralNames.append(
                peripheral.name
                    ?? "Nicht benanntes Gerät: \(peripheral.identifier)"
            )
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {

        self.conPeripheral = peripheral
        self.conPeripheral?.delegate = self  // Set the delegate here
        conPeripheral?.discoverServices(nil)

        self.peripheralStatus = .connected
        self.centralManger?.stopScan()
        print(centralManger?.isScanning as Any)
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        self.peripheralStatus = .error
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        self.peripheralStatus = .disconnected
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        guard let services = peripheral.services else { return }

        for service in services {
            self.conServices.append(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            conCharacteristics.append(characteristic)
            print(
                "\(String(describing: characteristic.service)) : \(characteristic)"
            )
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let e = error {
            print("ERROR didUpdateValue \(e)")
            return
        }
        guard let data = characteristic.value else { return }
        print("counter is \(data)")
    }
    
    func connect(peripheral: CBPeripheral) {
        self.peripheralStatus = .connecting
        self.centralManger?.connect(peripheral)
    }

    func getPeripheralName(peripheral: CBPeripheral) -> String {
        return peripheral.name
            ?? "Nicht benanntes Gerät: \(peripheral.identifier)"
    }

    func scanForPeripherals() {
        self.peripheralStatus = .scanning
        if useUUID {
            self.centralManger?.scanForPeripherals(withServices: [cbUUID])
        } else {
            self.centralManger?.scanForPeripherals(withServices: nil)
        }
    }

    func disconnect() {
        if self.peripheralStatus != .connected { return }
        self.centralManger?.cancelPeripheralConnection(conPeripheral!)
    }
}
