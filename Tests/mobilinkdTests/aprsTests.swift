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

@Test func testAPRSPosition() throws {
    let packetString = "!4000.00N/10500.00W>Test"
    let packet = decodeAPRS(packetString)

    #expect(packet.type == .positionNoTimestamp)
    #expect(packet.sender == nil)
    #expect(packet.receiver == nil)
    #expect(packet.content == "4000.00N/10500.00W>Test")
}