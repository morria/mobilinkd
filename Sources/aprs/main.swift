import Foundation
import CoreBluetooth
import mobilinkd

class TNC: KissTncBleManagerDelegate {
    private var hasConnected = false
    private var currentPeripheral: CBPeripheral?
    private let kissManager: KissTncBleManager

    public init() {
        kissManager = KissTncBleManager()
        kissManager.delegate = self
    }

    func didDiscoverPeripheral(_ peripheral: CBPeripheral, rssi: NSNumber) {
        guard !hasConnected else { return }
        hasConnected = true
        print("Attempting to connect to \(peripheral.name ?? "Unnamed")...")
        currentPeripheral = peripheral
        kissManager.connect(currentPeripheral!)
    }
    
    func didConnectToPeripheral(_ peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unnamed").")
    }
    
    func didDisconnectFromPeripheral(_ peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "Unnamed"): \(error?.localizedDescription ?? "no error")")
        exit(0) // Exit or handle gracefully.
    }
    
    func didReceiveData(_ data: Data) {
        print("Received data: \(data as NSData)")

        let kissParser = KISSParser()
        let aprsParser = APRSParser()
        kissParser.onPacketReceived = { frame in
            aprsParser.parseAPRSFrame(frame)
        }
        kissParser.feed([UInt8](data))
    }
    
    func bluetoothUnavailable(reason: String) {
        print("Bluetooth unavailable: \(reason)")
        exit(1)
    }
}

let tnc = TNC()

print("Waiting for Bluetooth to power on...")
RunLoop.main.run() // Keeps the program running until BLE events fire.

