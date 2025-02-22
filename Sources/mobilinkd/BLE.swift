import Foundation
import CoreBluetooth

public enum BLE {
    static let serviceUUIDString  = "00000001-ba2a-46c9-ae49-01b0961f68bb"
    static let txUUIDString       = "00000002-ba2a-46c9-ae49-01b0961f68bb"
    static let rxUUIDString       = "00000003-ba2a-46c9-ae49-01b0961f68bb"

    public static var serviceUUID: CBUUID {
        CBUUID(string: serviceUUIDString)
    }
    public static var txCharacteristicUUID: CBUUID {
        CBUUID(string: txUUIDString)
    }
    public static var rxCharacteristicUUID: CBUUID {
        CBUUID(string: rxUUIDString)
    }
}

public protocol KissTncBleManagerDelegate: AnyObject {
    func didDiscoverPeripheral(_ peripheral: CBPeripheral, rssi: NSNumber)
    func didConnectToPeripheral(_ peripheral: CBPeripheral)
    func didDisconnectFromPeripheral(_ peripheral: CBPeripheral, error: Error?)
    func didReceiveData(_ data: Data)
    func bluetoothUnavailable(reason: String)
}

public class KissTncBleManager: NSObject {
    public weak var delegate: KissTncBleManagerDelegate?

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var txCharacteristic: CBCharacteristic?
    private var rxCharacteristic: CBCharacteristic?

    public override init() {
        super.init()
        // The delegate (self) will get centralManagerDidUpdateState(_:) calls.
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    /// Start scanning (if Bluetooth is actually powered on).
    public func startScan() {
        guard centralManager.state == .poweredOn else {
            print("Central not powered on; ignoring scan request.")
            return
        }
        centralManager.scanForPeripherals(
            withServices: [BLE.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    public func stopScan() {
        centralManager.stopScan()
    }

    public func connect(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }

    public func disconnect() {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        }
    }

    public func sendData(_ data: Data) {
        guard let peripheral = connectedPeripheral,
              let tx = txCharacteristic else { return }
        peripheral.writeValue(data, for: tx, type: .withoutResponse)
    }
}

// MARK: - CBCentralManagerDelegate
extension KissTncBleManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unauthorized:
            delegate?.bluetoothUnavailable(reason: "Unauthorized for BLE.")
        case .poweredOff:
            delegate?.bluetoothUnavailable(reason: "Bluetooth powered off.")
        case .poweredOn:
            // Auto-scan now that Bluetooth is on.
            startScan()
        default:
            print("Unknown Bluetooth state: \(central.state.rawValue)")
        }
    }

    public func centralManager(_ central: CBCentralManager,
                               didDiscover peripheral: CBPeripheral,
                               advertisementData: [String : Any],
                               rssi RSSI: NSNumber) {
        delegate?.didDiscoverPeripheral(peripheral, rssi: RSSI)
    }

    public func centralManager(_ central: CBCentralManager,
                               didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([BLE.serviceUUID])
        delegate?.didConnectToPeripheral(peripheral)
    }

    public func centralManager(_ central: CBCentralManager,
                               didFailToConnect peripheral: CBPeripheral,
                               error: Error?) {
        delegate?.didDisconnectFromPeripheral(peripheral, error: error)
    }

    public func centralManager(_ central: CBCentralManager,
                               didDisconnectPeripheral peripheral: CBPeripheral,
                               error: Error?) {
        delegate?.didDisconnectFromPeripheral(peripheral, error: error)
        if connectedPeripheral == peripheral {
            connectedPeripheral = nil
        }
    }
}

// MARK: - CBPeripheralDelegate
extension KissTncBleManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverCharacteristicsFor service: CBService,
                           error: Error?) {
        guard error == nil, let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            if characteristic.uuid == BLE.rxCharacteristicUUID {
                rxCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == BLE.txCharacteristicUUID {
                txCharacteristic = characteristic
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        guard error == nil,
              characteristic.uuid == BLE.rxCharacteristicUUID,
              let data = characteristic.value else { return }

        delegate?.didReceiveData(data)
    }
}

