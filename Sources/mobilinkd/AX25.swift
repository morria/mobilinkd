import Foundation

public struct AX25Address {
    public let callSign: String
    public let ssid: UInt8
}

public struct AX25Frame {
    public let destination: AX25Address
    public let source: AX25Address
    public let digipeaters: [AX25Address]
    public let control: UInt8
    public let pid: UInt8
    public let info: [UInt8]
}

public func decodeAX25Frame(_ bytes: [UInt8]) throws -> AX25Frame {
    // Typically skip HDLC flags (0x7E) and FCS at ends; adjust indices as needed.
    var idx = 0

    func parseAddress() throws -> AX25Address {
        guard idx + 7 <= bytes.count else { throw NSError(domain: "AX25", code: 1) }
        let raw = Array(bytes[idx..<idx+7])
        idx += 7

        // Each call sign char is shifted left by 1 bit. Right-shift them and trim trailing spaces.
        let callsignChars = raw[0..<6].map { c -> Character in
            let shifted = c >> 1
            return shifted == 0 ? " " : Character(UnicodeScalar(shifted))
        }
        let callSign = String(callsignChars).trimmingCharacters(in: .whitespaces)

        // SSID in upper bits of the 7th byte (bits 7..4). The low bit indicates extension.
        let ssid = (raw[6] >> 1) & 0x0F

        return AX25Address(callSign: callSign, ssid: ssid)
    }

    let dest = try parseAddress()
    let src = try parseAddress()

    // Collect digipeaters until "extension" bit set (lowest bit == 1).
    var digis = [AX25Address]()
    while idx + 7 <= bytes.count {
        // If extension bit is set, we stop after parsing.
        if bytes[idx+6] & 0x01 == 0x01 { 
            digis.append(try parseAddress())
            break
        }
        digis.append(try parseAddress())
    }

    // Next bytes: control (1 byte), PID (1 byte).
    guard idx + 2 <= bytes.count else { throw NSError(domain: "AX25", code: 2) }
    let control = bytes[idx]
    let pid = bytes[idx+1]
    idx += 2

    // Remaining are info bytes (APRS payload).
    let info = Array(bytes[idx..<bytes.count])

    return AX25Frame(
        destination: dest,
        source: src,
        digipeaters: digis,
        control: control,
        pid: pid,
        info: info
    )
}