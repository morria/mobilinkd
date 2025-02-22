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