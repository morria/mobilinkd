import Testing
@testable import mobilinkd

@Test func testAPRS() async throws {
    // let aprsParser = APRSParser()

    // Corrected APRS frame with valid AX.25 encoding
    // let rawPacket: [UInt8] = [
    //     0x82, 0xA0, 0xA4, 0xB2, 0x40, 0x60, 0xAE, // Destination Callsign: N2DEF (shifted left)
    //     0x9E, 0x9A, 0x62, 0x40, 0x63, 0x61, 0xE1, // Source Callsign: N1ABC (LSB set in last byte)
    //     0x03, // Control Field (UI frame)
    //     0xF0, // PID (No Layer 3 protocol)
    //     0x3D, 0x34, 0x33, 0x32, 0x34, 0x2E, 0x33, 0x36, // Latitude: 4324.36N
    //     0x4E, 0x2F, 0x31, 0x32, 0x33, 0x2E, 0x34, 0x35, // Longitude: 123.45W
    //     0x57, // West indicator
    //     0x00  // Checksum byte (example, not used for parsing)
    // ]

    // // let rawPacket = [UInt8]("CALLSIGN-1,APRS,Hello World!".data(using: .utf8)!)
    // let rawPacket: [UInt8] = Array("CALLSIGN-1>APRS:UI Hello World!".utf8)

    // let packet = aprsParser.parseAPRSFrame(rawPacket)

    // print(packet)
    // print("\(packet?.source)")
    // print(packet?.destination)
    // print(packet?.payload)

    // #expect(packet?.source == "N1ABC")
    // #expect(packet?.destination == "N2DEF")
    // #expect(packet?.payload == "4324.36N/123.45W")
}
