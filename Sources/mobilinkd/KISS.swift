import Foundation

public class KISSParser {
    private let FEND: UInt8 = 0xC0 // Frame End
    private let FESC: UInt8 = 0xDB // Frame Escape
    private let TFEND: UInt8 = 0xDC // Transposed FEND
    private let TFESC: UInt8 = 0xDD // Transposed FESC

    private var buffer: [UInt8] = []
    private var escaping = false

    public var onPacketReceived: (([UInt8]) -> Void)?

    public init() {}

    public func feed(_ data: [UInt8]) {
        for byte in data {
            if escaping {
                if byte == TFEND {
                    buffer.append(FEND)
                } else if byte == TFESC {
                    buffer.append(FESC)
                }
                escaping = false
            } else if byte == FESC {
                escaping = true
            } else if byte == FEND {
                processFrame()
            } else {
                buffer.append(byte)
            }
        }
    }

    private func processFrame() {
        guard buffer.count > 1 else { return } // Ignore empty frames

        let command = buffer[0] & 0x0F // Extract command
        let payload = Array(buffer.dropFirst()) // Remove command byte

        buffer.removeAll() // Clear for next frame

        if command == 0x00 { // Data frame (APRS)
            onPacketReceived?(payload)
        }
    }
}

public class APRSParser {
    public init() {}

    public func parseAPRSFrame(_ frame: [UInt8]) {
        guard frame.count > 16 else {
            print("Invalid APRS frame (too short)")
            return
        }

        // Find where the address field ends (last byte with bit 0x01 set)
        var addressEnd = 0
        for i in stride(from: 6, to: frame.count, by: 7) {
            if frame[i] & 0x01 == 1 {
                addressEnd = i + 1
                break
            }
        }

        guard addressEnd > 0, addressEnd + 2 < frame.count else {
            print("Invalid AX.25 address field")
            return
        }

        let source = extractCallsign(from: frame, start: 7)
        let destination = extractCallsign(from: frame, start: 0)

        // Ensure control and PID fields are correct
        if frame[addressEnd] != 0x03 || frame[addressEnd + 1] != 0xF0 {
            print("Not an APRS UI frame")
            return
        }

        let payloadStart = addressEnd + 2
        let payload = frame.dropFirst(payloadStart)

        if let aprsMessage = String(bytes: payload, encoding: .ascii) {
            print("Source: \(source) → Destination: \(destination)")
            print("APRS Payload: \(aprsMessage)")
        } else {
            print("Invalid ASCII payload: \(payload.map { String(format: "%02X", $0) }.joined(separator: " "))")
        }
    }

    private func extractCallsign(from frame: [UInt8], start: Int) -> String {
        let callsign = frame[start..<start+6].map { $0 >> 1 }.map { $0 == 0x20 ? " " : String(UnicodeScalar($0)) }.joined().trimmingCharacters(in: .whitespaces)
        let ssid = (frame[start+6] >> 1) & 0x0F
        return ssid > 0 ? "\(callsign)-\(ssid)" : callsign
    }
}

// // Usage:
// let kissParser = KISSParser()
// let aprsParser = APRSParser()

// kissParser.onPacketReceived = { frame in
//     aprsParser.parseAPRSFrame(frame)
// }

// // Simulated KISS APRS packet (Example AX.25 payload with callsign)
// let sampleKISSPacket: [UInt8] = [
//     0xC0, 0x00, 0x82, 0xA0, 0xA4, 0xB2, 0x40, 0x60, 0xAE, // Destination Callsign
//     0x9E, 0x9A, 0x62, 0x40, 0x63, 0x61, 0x03, 0xF0, // Source Callsign
//     0x3D, 0x37, 0x32, 0x34, 0x33, 0x2E, 0x35, 0x36, // Sample APRS Data (Position)
//     0x4E, 0x2F, 0x31, 0x32, 0x33, 0x2E, 0x34, 0x35, 0x57, 0x20, 0x00, 0xC0
// ]

// kissParser.feed(sampleKISSPacket)