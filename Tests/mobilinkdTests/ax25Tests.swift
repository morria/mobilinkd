import Testing
@testable import mobilinkd

@Test func testAX25() async throws {
    let rawData: [UInt8] = [
        0x9C, 0x94, 0x6E, 0xA0, 0x40, 0x40, 0xE0, 0x9C, 0x6E, 0x98, 0x8A, 0x9A, 0x40, 0x61, 0x03, 0xF0,
        0x54, 0x68, 0x65, 0x20, 0x71, 0x75, 0x69, 0x63, 0x6B, 0x20, 0x62, 0x72, 0x6F, 0x77, 0x6E, 0x20,
        0x66, 0x6F, 0x78, 0x20, 0x6A, 0x75, 0x6D, 0x70, 0x73, 0x20, 0x6F, 0x76, 0x65, 0x72, 0x20, 0x74,
        0x68, 0x65, 0x20, 0x6C, 0x61, 0x7A, 0x79, 0x20, 0x64, 0x6F, 0x67
    ]

    let frame = try decodeAX25Frame(rawData)

    #expect(frame.destination.callSign == "NJ7P")
    #expect(frame.source.callSign == "N7LEM")
    #expect(frame.destination.ssid == 0)
    #expect(frame.source.ssid == 0)
    #expect(frame.digipeaters.count == 0)
    #expect(frame.control == 0x03)
    #expect(frame.pid == 0xF0)
    #expect(frame.info == [UInt8]("The quick brown fox jumps over the lazy dog".utf8))
}

@Test func testRealPacket() async throws {
    let rawData: [UInt8] = [
        0x82, 0xA0, 0x9C, 0x66, 0x70, 0x66, 0x60, 0xAE, 0x64, 0xAC, 0x8A, 0xA4, 0x40, 0x7E, 0x96, 0x86,
        0x64, 0x9E, 0xAA, 0xA4, 0xE6, 0xAE, 0x84, 0x64, 0xB4, 0x92, 0x92, 0xE0, 0x96, 0x86, 0x64, 0x9A,
        0x88, 0x9C, 0xE4, 0xAE, 0x92, 0x88, 0x8A, 0x64, 0x40, 0xE1, 0x03, 0xF0, 0x21, 0x34, 0x31, 0x31,
        0x30, 0x2E, 0x30, 0x30, 0x4E, 0x53, 0x30, 0x37, 0x34, 0x33, 0x30, 0x2E, 0x31, 0x30, 0x57, 0x23,
        0x50, 0x48, 0x47, 0x34, 0x35, 0x32, 0x30, 0x20, 0x57, 0x33, 0x2C, 0x53, 0x53, 0x6E, 0x2D, 0x4E,
        0x20, 0x56, 0x52, 0x41, 0x43, 0x45, 0x53, 0x20, 0x56, 0x65, 0x72, 0x6E, 0x6F, 0x6E, 0x2C, 0x4E,
        0x4A, 0x0D
    ]

    let frame = try decodeAX25Frame(rawData)

    #expect(frame.destination.callSign == "APN383")
    #expect(frame.source.callSign == "W2VER")
    #expect(frame.destination.ssid == 0)
    #expect(frame.source.ssid == 15)
    #expect(frame.digipeaters.count == 4)
    #expect(frame.digipeaters[0].callSign == "KC2OUR")
    #expect(frame.digipeaters[1].callSign == "WB2ZII")
    #expect(frame.digipeaters[2].callSign == "KC2MDN")
    #expect(frame.digipeaters[3].callSign == "WIDE2")
    #expect(frame.control == 0x03)
    #expect(frame.pid == 0xF0)
    #expect(String(bytes: frame.info, encoding: .utf8) == "!4110.00NS07430.10W#PHG45")
}

