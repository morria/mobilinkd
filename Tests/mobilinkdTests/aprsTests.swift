import Testing
@testable import mobilinkd

@Test func testAPRSMessage() throws {
    let packetString = ":W2ASM :Hello, this is a test message!"
    let packet = decodeAPRS(packetString)

    #expect(packet.type == .message)
    #expect(packet.sender == nil)
    #expect(packet.receiver == "W2ASM")
    #expect(packet.content == "Hello, this is a test message!")
}

@Test func testAPRSPositionComppressedWithTimestamp() throws {
    let packetString = "@092345z/5L!!<*e7>7P["
    let packet = decodeAPRS(packetString)
    #expect(packet.type == .positionWithTimestamp)
    #expect(packet.sender == nil)
    #expect(packet.receiver == nil)
    #expect(packet.content == "092345z/5L!!<*e7>7P[")
    #expect(packet.symbolTable == "/")
    #expect(packet.symbol == "[")
}

@Test func testAPRSPositionUncompressedWithTimestamp() throws {
    let packetString = "@092345z4903.50N/07201.75W-"
    let packet = decodeAPRS(packetString)
    #expect(packet.type == .positionWithTimestamp)
    #expect(packet.sender == nil)
    #expect(packet.receiver == nil)
    #expect(packet.content == "092345z4903.50N/07201.75W-")
    #expect(packet.symbolTable == "/")
    #expect(packet.symbol == "-")
}

@Test func testAPRSPositionCompressedNoTimestamp() throws {
    let packetString = "!/5L!!<*e7>7P["
    let packet = decodeAPRS(packetString)
    #expect(packet.type == .positionNoTimestamp)
    #expect(packet.sender == nil)
    #expect(packet.receiver == nil)
    #expect(packet.content == "/5L!!<*e7>7P[")
    #expect(packet.symbolTable == "/")
    #expect(packet.symbol == "[")
}

@Test func testAPRSPositionUncompressedNoTimestamp() throws {
    let packetString = "!4903.50N/07201.75W-"
    let packet = decodeAPRS(packetString)
    #expect(packet.type == .positionNoTimestamp)
    #expect(packet.sender == nil)
    #expect(packet.receiver == nil)
    #expect(packet.content == "4903.50N/07201.75W-")
    #expect(packet.symbolTable == "/")
    #expect(packet.symbol == "-")
}

@Test func testAPRSFormats() throws {
    let formats = [
        ("@092345z4903.50N/07201.75W-", APRSMessageType.positionWithTimestamp),
        ("!4903.50N/07201.75W-", APRSMessageType.positionNoTimestamp),
        ("@092345z/5L!!<*e7>7P[", APRSMessageType.positionWithTimestamp),
        ("!/5L!!<*e7>7P[", APRSMessageType.positionNoTimestamp),
        (":BLN1CALL :Testing 123", APRSMessageType.message),
        (":BLN1     :Bulletin broadcast test", APRSMessageType.message),
        (":ANNOUNCE :Club meeting tonight at 7pm", APRSMessageType.message),
        ("_10090556c220s004g005t077r000p000P000h50b09900", APRSMessageType.weatherReport),
        ("T#123,456,789,123,456,789,01101001", APRSMessageType.telemetry),
        (";Field Day*092345z4903.50N/07201.75W-", APRSMessageType.object),
        (")Station1!4903.50N/07201.75W-", APRSMessageType.item),
        ("?APRS?", .query),
        (">Testing status message", .status)
    ]

    for (packet, expectedType) in formats {
        let decoded = decodeAPRS(packet)
        #expect(decoded.type == expectedType, "Failed for packet: \(packet)")
    }
}