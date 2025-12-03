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
    
    var onReceiveStart: (() -> Void)?
    var onReceiveStop: (() -> Void)?

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
        print("Bluetooth.centralManager.didConnect: connected to -> \(getPeripheralName(peripheral: peripheral))")
        self.centralManger?.stopScan()
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        // treat a failed connection as a disconnect so UI resets and we clear state
        print("Bluetooth.centralManager.didFailToConnect: failed to connect -> \(getPeripheralName(peripheral: peripheral)), error: \(String(describing: error))")
        self.peripheralStatus = .disconnected
        self.conPeripheral = nil
        self.conServices = []
        self.conCharacteristics = []
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        self.peripheralStatus = .disconnected
        print("Bluetooth.centralManager.didDisconnect: disconnected -> \(getPeripheralName(peripheral: peripheral))")
        self.conPeripheral = nil
        self.conServices = []
        self.conCharacteristics = []
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
            peripheral.setNotifyValue(true, for: characteristic)
            print("Found", peripheral.name!)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: (any Error)?) {
        
        if let e = error {
            print("ERROR didUpdateValue \(e)")
            return
        }
        
        guard let data = characteristic.value else { return }
        
        if data.count == 1 {
            let byte = data[data.startIndex]
            print("One byte received: \(byte)")
            
            // Handle commands based on received byte
            switch byte {
            case 0x00:
                print("Received 0x00 (Start byte)")
                onReceiveStart?()
            case 0x01:
                print("Received 0x01 (Stop byte)")
                onReceiveStop?()
            default:
                print("Received unknown byte: \(byte)")
            }
        } else {
            // print("Received data (\(data.count) bytes): \(data as NSData)")
        }
    }

    
    func connect(peripheral: CBPeripheral) {
        // keep a reference to the peripheral immediately so we can cancel while connecting
        self.conPeripheral = peripheral
        self.peripheralStatus = .connecting
        print("Bluetooth.connect: initiating connection to -> \(getPeripheralName(peripheral: peripheral))")
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
        if self.peripheralStatus == .disconnected { return }
        guard let peripheral = conPeripheral else { return }
        print("Bluetooth.disconnect: cancelling connection to -> \(getPeripheralName(peripheral: peripheral))")
        self.centralManger?.cancelPeripheralConnection(peripheral)
    }
}
