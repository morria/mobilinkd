public struct APRSFrame {
    public let source: String
    public let destination: String
    public let payload: String
}

public class APRSParser {
    public init() {}

    public func parseAPRSFrame(_ frame: [UInt8]) -> APRSFrame? {
        guard frame.count > 16 else {
            print("Invalid APRS frame (too short)")
            return nil
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
            return nil
        }

        let source = extractCallsign(from: frame, start: 7)
        let destination = extractCallsign(from: frame, start: 0)

        // Ensure control and PID fields are correct
        if frame[addressEnd] != 0x03 || frame[addressEnd + 1] != 0xF0 {
            print("Not an APRS UI frame")
            return nil
        }

        let payloadStart = addressEnd + 2
        let payload = frame.dropFirst(payloadStart)

        if let aprsMessage = String(bytes: payload, encoding: .ascii) {
            return APRSFrame(source: source, destination: destination, payload: aprsMessage)
        } else {
            print("Invalid ASCII payload: \(payload.map { String(format: "%02X", $0) }.joined(separator: " "))")
        }

        return nil
    }

    private func extractCallsign(from frame: [UInt8], start: Int) -> String {
        let callsign = frame[start..<start+6].map { $0 >> 1 }.map { $0 == 0x20 ? " " : String(UnicodeScalar($0)) }.joined().trimmingCharacters(in: .whitespaces)
        let ssid = (frame[start+6] >> 1) & 0x0F
        return ssid > 0 ? "\(callsign)-\(ssid)" : callsign
    }
}
