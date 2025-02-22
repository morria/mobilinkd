import Foundation
import CoreBluetooth
import mobilinkd

class TNC: KissTncBleManagerDelegate {
    private var hasConnected = false
    private var currentPeripheral: CBPeripheral?
    private let kissManager: KissTncBleManager
    private let kissParser = KISSParser()

    public init() throws {
        kissManager = KissTncBleManager()
        kissManager.delegate = self

        kissParser.onPacketReceived = { frame in
            do {
                print("Received AX.25 frame:")
                print(frame.map { String(format: "%02X", $0) }.joined(separator: " "))
                let ax25Packet = try decodeAX25Frame(frame)
                print("APRS message:")
                print(ax25Packet.info.map { String(format: "%02X", $0) }.joined(separator: " "))
                let aprsData = decodeAPRSMessage(ax25Packet.info)
                guard aprsData != nil else {
                    print("Failed to decode APRS message")
                    return
                }
                print("\(String(describing:aprsData?.source))")
            } catch {
                print("Failed to decode AX.25 frame: \(error)")
            }
        }
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
        kissParser.feed([UInt8](data))
    }
    
    func bluetoothUnavailable(reason: String) {
        print("Bluetooth unavailable: \(reason)")
        exit(1)
    }
}

do {
    let tnc = try TNC()
    print("Waiting for Bluetooth to power on...")
    RunLoop.main.run() // Keeps the program running until BLE events fire.
} catch {
    print("Failed to initialize TNC: \(error)")
    exit(1)
}