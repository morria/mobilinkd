import Testing
@testable import mobilinkd

@Test func testKiss() async throws {
    let kissParser = KISSParser()

    // Simulated KISS APRS packet (Example AX.25 payload with callsign)
    let sampleKISSPacket: [UInt8] = [
        0xC0, 0x00, 0x82, 0xA0, 0xA4, 0xB2, 0x40, 0x60, 0xAE, // Destination Callsign
        0x9E, 0x9A, 0x62, 0x40, 0x63, 0x61, 0x03, 0xF0, // Source Callsign
        0x3D, 0x37, 0x32, 0x34, 0x33, 0x2E, 0x35, 0x36, // Sample APRS Data (Position)
        0x4E, 0x2F, 0x31, 0x32, 0x33, 0x2E, 0x34, 0x35,
        0x57, 0x20, 0x00, 0xC0
    ]

    kissParser.onPacketReceived = { frame in
        #expect(frame == [UInt8](sampleKISSPacket[2..<sampleKISSPacket.count-1]))
    }

    kissParser.feed(sampleKISSPacket)
}
