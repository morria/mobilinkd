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

        // let packet = parseKISSToAPRSPacket([UInt8](data))
        // print("Parsed packet: \(packet)")
        let ax25packet = parseAX25UIFrame([UInt8](data))

        guard ax25packet != nil else {
            print("Failed to parse AX.25 packet.")
            return
        }
        print("AX25: \(ax25packet!)")

        let parsedPacket = APRSParser.parse(frame: ax25packet!)

        switch parsedPacket {
        case .message(let from, let to, let text):
            print("Message from \(from) to \(to): \(text)")
        case .bulletin(let text):
            print("Bulletin: \(text)")
        case .weather(let weather):
            print("Weather: \(weather)")
        case .telemetry(let data):
            print("Telemetry: \(data)")
        case .unknown(let raw):
            print("Unknown payload: \(raw)")
        }
    }
    
    func bluetoothUnavailable(reason: String) {
        print("Bluetooth unavailable: \(reason)")
        exit(1)
    }
}

let tnc = TNC()

print("Waiting for Bluetooth to power on...")
RunLoop.main.run() // Keeps the program running until BLE events fire.

