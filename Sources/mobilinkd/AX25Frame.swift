import Foundation

/// Represents a single parsed AX.25 address (callsign + SSID).
public struct AX25Address {
    let callsign: String
    let ssid: Int
    /// AX.25 encodes a “repeated” flag in digipeater paths. Not always needed for APRS,
    /// but included here in case you want to track it.
    let hasBeenRepeated: Bool
}

/// Represents a parsed AX.25 frame (focusing on UI frames).
public struct AX25Frame {
    let destination: AX25Address
    let source: AX25Address
    let digipeaters: [AX25Address]
    let control: UInt8
    let pid: UInt8
    let info: [UInt8]  // For APRS, this is the main payload (e.g. position/status).
}

public extension AX25Address {
    /// Decode a 7-byte block into callsign/SSID. The AX.25 address has
    /// each character left-shifted by 1 bit, plus an SSID nibble.
    init(from bytes: [UInt8]) {
        precondition(bytes.count == 7, "AX25Address requires exactly 7 bytes")

        // Each of the first 6 bytes holds a shifted ASCII char.
        // The 7th byte contains SSID + extension flags.
        let shiftedChars = bytes[0..<6].map { ($0 >> 1) & 0x7F }
        let rawCallsign = shiftedChars
            .map { $0 == 0x40 ? UInt8(0x20) : $0 } // Some TNCs store blank as 0x40<<1
            .map { Character(Unicode.Scalar($0)) }
            .map { String($0) }
            .joined()
            .trimmingCharacters(in: .whitespaces)
        
        let ssid = Int((bytes[6] >> 1) & 0x0F)
        // let hBit = ((bytes[6] >> 7) & 0x01) == 1  // extension bit
        let hasBeenRepeated = ((bytes[6] >> 5) & 0x01) == 1
        
        self.callsign = rawCallsign
        self.ssid = ssid
        self.hasBeenRepeated = hasBeenRepeated
        // hBit (extension bit) indicates whether more address bytes follow in the frame.
    }

    /// Encode the AX.25 address back into a 7-byte block.
    func encode() -> [UInt8] {
        let callsignBytes = callsign.uppercased().utf8.map { UInt8($0) << 1 }
        let ssidByte = UInt8(ssid << 1)
        let hBit: UInt8 = hasBeenRepeated ? 0x20 : 0x00
        let lastByte = ssidByte | hBit | 0x01  // Set extension bit for last address byte
        return callsignBytes + [lastByte]
    }

    /// String representation of the address (callsign-SSID).
    var description: String {
        return ssid > 0 ? "\(callsign)-\(ssid)" : callsign
    }
    
}

/// Main parser that extracts one AX.25 UI frame from a TNC-supplied buffer.
/// Assumes the buffer starts at the first address byte (no leading 0x7E flag).
public func parseAX25UIFrame(_ data: [UInt8]) -> AX25Frame? {
    // At minimum, we need:
    // - 7 bytes for destination
    // - 7 bytes for source
    // - Possibly 0..(n*7) for digipeaters
    // - 1 byte control
    // - 1 byte PID
    // - 1..n bytes info
    guard data.count >= (7 + 7 + 2) else { return nil }

    var index = 0
    
    // Parse destination
    let destBytes = Array(data[index..<(index+7)])
    let destination = AX25Address(from: destBytes)
    index += 7
    
    // Parse source
    let sourceBytes = Array(data[index..<(index+7)])
    let source = AX25Address(from: sourceBytes)
    index += 7
    
    // Collect digipeaters until we find a byte with the extension bit = 1,
    // which indicates the last address block in the chain.
    var digipeaters: [AX25Address] = []
    while true {
        // Check extension bit of the last byte in the previous block
        let extBit = (data[index - 1] & 0x01) // 1 => last in address field
        if extBit == 1 { break }
        guard data.count >= index + 7 else { break }
        
        let digiBytes = Array(data[index..<(index+7)])
        digipeaters.append(AX25Address(from: digiBytes))
        index += 7
    }
    
    // Next should be 1 byte control + 1 byte PID
    guard data.count >= index + 2 else { return nil }
    let control = data[index]
    let pid = data[index+1]
    index += 2
    
    // Remaining bytes are the info field
    let infoBytes = Array(data[index..<data.count])
    
    return AX25Frame(
        destination: destination,
        source: source,
        digipeaters: digipeaters,
        control: control,
        pid: pid,
        info: infoBytes
    )
}