public struct APRSData {
    public let source: String
    public let destination: String
    public let message: String?
    public let bulletin: String?
    public let weatherReport: String?
}

public func decodeAPRSMessage(_ message: [UInt8]) -> APRSData? {
    guard message.count > 16 else {
        print("Invalid APRS frame (too short)")
        return nil
    }

    // Find where the address field ends (last byte with bit 0x01 set)
    var addressEnd = 0
    for i in stride(from: 6, to: message.count, by: 7) {
        if message[i] & 0x01 == 1 {
            addressEnd = i + 1
            break
        }
    }

    guard addressEnd > 0, addressEnd + 2 < message.count else {
        print("Invalid AX.25 address field")
        return nil
    }

    let source = extractCallsign(from: message, start: 7)
    let destination = extractCallsign(from: message, start: 0)

    // Ensure control and PID fields are correct
    if message[addressEnd] != 0x03 || message[addressEnd + 1] != 0xF0 {
        print("Not an APRS UI frame")
        return nil
    }

    let payloadStart = addressEnd + 2
    let payload = message.dropFirst(payloadStart)

    guard let aprsMessage = String(bytes: payload, encoding: .ascii) else {
        print("Invalid ASCII payload: \(payload.map { String(format: "%02X", $0) }.joined(separator: " "))")
        return nil
    }

    var message: String? = nil
    var bulletin: String? = nil
    var weatherReport: String? = nil

    if aprsMessage.hasPrefix(":") {
        message = aprsMessage
    } else if aprsMessage.hasPrefix("@") {
        bulletin = aprsMessage
    } else if aprsMessage.hasPrefix("!") || aprsMessage.hasPrefix("=") {
        weatherReport = aprsMessage
    }

    return APRSData(source: source, destination: destination, message: message, bulletin: bulletin, weatherReport: weatherReport)
}

private func extractCallsign(from frame: [UInt8], start: Int) -> String {
    let callsign = frame[start..<start+6].map { $0 >> 1 }.map { $0 == 0x20 ? " " : String(UnicodeScalar($0)) }.joined().trimmingCharacters(in: .whitespaces)
    let ssid = (frame[start+6] >> 1) & 0x0F
    return ssid > 0 ? "\(callsign)-\(ssid)" : callsign
}