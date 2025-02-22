import Testing
@testable import mobilinkd

@Test func testAPRS() throws {
    let aprsMessage = "CALLSIGN>APRS,TCPIP*:Test message"
    let aprsData = decodeAPRSMessage(aprsMessage.utf8.map { UInt8($0) })

    #expect(aprsData != nil)
    guard aprsData != nil else { return }

    #expect(aprsData!.source == "CALLSIGN")
    #expect(aprsData!.destination == "APRS")
    #expect(aprsData!.message == "Test message")
    #expect(aprsData!.bulletin == nil)
    #expect(aprsData!.weatherReport == nil)
}

@Test func testFailedToParse() throws {
    let rawData: [UInt8] = [UInt8]([
        0x60, 0x64, 0x54, 0x55, 0x6F, 0x66, 0x6D, 0x6A, 0x2F, 0x60, 0x22, 0x34, 0x3F, 0x7D, 0x31,
        0x34, 0x36, 0x2E, 0x35, 0x32, 0x30, 0x4D, 0x48, 0x7A, 0x20, 0x4A, 0x65, 0x65, 0x70, 0x20,
        0x4D, 0x6F, 0x62, 0x69, 0x6C, 0x65, 0x5F, 0x25, 0x0D
    ])

    let aprsData = decodeAPRSMessage(rawData)
    #expect(aprsData == nil)
}
