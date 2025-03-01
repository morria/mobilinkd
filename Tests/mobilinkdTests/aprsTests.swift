import Testing
import Foundation
@testable import mobilinkd

@Test func testAPRSMessage() throws {
    let packetString = ":W2ASM :Hello, this is a test message!"

    guard let packet = APRSPacket(rawValue: packetString),
     case .message(let messagePacket) = packet else {
        #expect(Bool(false), "Failed to parse APRS packet or packet is not of type MessagePacket.")
        return
    }

    #expect(messagePacket.type == APRSPacketType.message)
    #expect(messagePacket.fromCallsign == nil)
    #expect(messagePacket.toCallsign == "W2ASM")
    #expect(messagePacket.messageText == "Hello, this is a test message!")
}

@Test func testAPRSBulletin() throws {
    let packetString = ":BLN1     :Bulletin broadcast test"
    guard let packet = APRSPacket(rawValue: packetString),
    case .message(let messagePacket) = packet else {
        #expect(Bool(false), "Failed to parse APRS packet.")
        return
    }
    #expect(messagePacket.type == APRSPacketType.message)
    #expect(messagePacket.fromCallsign == nil)
    #expect(messagePacket.toCallsign == "BLN1")
    #expect(messagePacket.messageText == "Bulletin broadcast test")
}

@Test func testAPRSAnnounce() throws {
    let packetString = ":ANNOUNCE :Club meeting tonight at 7pm"
    guard let packet = APRSPacket(rawValue: packetString),
    case .message(let messagePacket) = packet else {
        #expect(Bool(false), "Failed to parse APRS packet.")
        return
    }
    #expect(messagePacket.type == APRSPacketType.message)
    #expect(messagePacket.fromCallsign == nil)
    #expect(messagePacket.toCallsign == "ANNOUNCE")
    #expect(messagePacket.messageText == "Club meeting tonight at 7pm")
}

@Test func testAPRSPositionCompressedWithTimestamp() throws {
    let packetString = "@092345z/5L!!<*e7>7P["
    guard let packet = APRSPacket(rawValue: packetString),
     case .positionWithTimestamp(let positionPacket) = packet else {
        #expect(Bool(false), "Failed to parse APRS packet.")
        return
    }
    #expect(positionPacket.type == APRSPacketType.positionWithTimestamp)
    #expect(abs(positionPacket.latitude - 13794.68304) < 0.0001)
    #expect(abs(positionPacket.longitude - 14362.8397) < 0.0001)
    let timestamp = DateFormatter()
    timestamp.dateFormat = "HHmmss"
    guard let date = timestamp.date(from: "092345") else {
        #expect(Bool(false), "Failed to parse timestamp.")
        return
    }
    #expect(positionPacket.timestamp == date)
    #expect(positionPacket.timestamp == date)
    #expect(positionPacket.symbolTable == "/")
    #expect(positionPacket.symbolCode == "[")
    #expect(positionPacket.comment == nil)
}

@Test func testAPRSPositionUncompressedWithTimestamp() throws {
    let packetString = "@092345z4903.50N/07201.75W-"
    guard let packet = APRSPacket(rawValue: packetString),
     case .positionWithTimestamp(let positionPacket) = packet else {
        #expect(Bool(false), "Failed to parse APRS packet.")
        return
    }
    #expect(positionPacket.type == APRSPacketType.positionWithTimestamp)
    #expect(abs(positionPacket.latitude - 4903.5) < 0.0001)
    #expect(abs(positionPacket.longitude - -7201.75) < 0.0001)
    let timestamp = DateFormatter()
    timestamp.dateFormat = "HHmmss"
    guard let date = timestamp.date(from: "092345") else {
        #expect(Bool(false), "Failed to parse timestamp.")
        return
    }
    #expect(positionPacket.timestamp == date)
    #expect(positionPacket.timestamp == date)
    #expect(positionPacket.symbolTable == "/")
    #expect(positionPacket.symbolCode == "-")
    #expect(positionPacket.comment == nil)
}

@Test func testAPRSPositionCompressedNoTimestamp() throws {
    let packetString = "!/5L!!<*e7>7P["
    guard let packet = APRSPacket(rawValue: packetString),
     case .positionNoTimestamp(let positionPacket) = packet else {
        #expect(Bool(false), "Failed to parse APRS packet.")
        return
    }
    #expect(positionPacket.type == APRSPacketType.positionNoTimestamp)
    #expect(abs(positionPacket.latitude - 10284.36311) < 0.0001)
    #expect(abs(positionPacket.longitude - 12842.19420) < 0.0001)
    #expect(positionPacket.symbolTable == "/")
    #expect(positionPacket.symbolCode == "[")
    #expect(positionPacket.comment == nil)
}

@Test func testAPRSPositionUncompressedNoTimestamp() throws {
    let packetString = "!4903.50N/07201.75W-"
    guard let packet = APRSPacket(rawValue: packetString),
     case .positionNoTimestamp(let positionPacket) = packet else {
        #expect(Bool(false), "Failed to parse APRS packet.")
        return
    }
    #expect(positionPacket.type == APRSPacketType.positionNoTimestamp)
    #expect(abs(positionPacket.latitude - 4903.50) < 0.0001)
    #expect(abs(positionPacket.longitude - -7201.75) < 0.0001)
    #expect(positionPacket.symbolTable == "/")
    #expect(positionPacket.symbolCode == "-")
    #expect(positionPacket.comment == nil)
}

@Test func testAPRSWeatherReport() throws {
    let packetString = "_10090556c220s004g005t077r000p000P000h50b09900" 
    guard let packet = APRSPacket(rawValue: packetString),
     case .weather(let weatherPacket) = packet else {
        #expect(Bool(false), "Failed to parse APRS packet.")
        return
    }
    #expect(weatherPacket.type == APRSPacketType.weatherReport)

    #expect(weatherPacket.latitude == nil)
    #expect(weatherPacket.longitude == nil)
    #expect(weatherPacket.windDirection == 220)
    #expect(weatherPacket.windSpeed == 4)
    #expect(weatherPacket.windGust == 5)
    #expect(weatherPacket.temperatureF == 77)
    #expect(weatherPacket.rainfallLastHour == 0.0)
    #expect(weatherPacket.rainfallLast24h == 0.0)
    #expect(weatherPacket.rainfallSinceMidnight == 0.0)
    #expect(weatherPacket.humidity == 50)
    #expect(weatherPacket.pressure == 9900.0)
    #expect(weatherPacket.comment == nil)

}

@Test func testAPRSTelemetry() throws {
    let packetString = "T#123,456,789,123,456,789,01101001"
    guard let packet = APRSPacket(rawValue: packetString),
     case .telemetry(let telemetryPacket) = packet else {
        #expect(Bool(false), "Failed to parse APRS packet.")
        return
    }
    #expect(telemetryPacket.type == APRSPacketType.telemetry)
    #expect(telemetryPacket.sequenceNumber == 123)
    #expect(telemetryPacket.analogValues == [456, 789, 123, 456, 789])
    #expect(telemetryPacket.digitalValues == [false, true, true, false, true, false, false, true])
    #expect(telemetryPacket.comment == nil)
}

@Test func testAPRSObject() throws {
    // ";Field Day*092345z4903.50N/07201.75W-"
}

@Test func testAPRSItem() throws {
    // ")Station1!4903.50N/07201.75W-"
}

@Test func testAPRSQuery() throws {
    // "?APRS?"
}

@Test func testAPRSStatus() throws {
    // ">Testing status message"
}

@Test func testAPRSFormats() throws {
    let formats = [
        ("@092345z4903.50N/07201.75W-", APRSPacketType.positionWithTimestamp),
        ("!4903.50N/07201.75W-", APRSPacketType.positionNoTimestamp),
        ("@092345z/5L!!<*e7>7P[", APRSPacketType.positionWithTimestamp),
        ("!/5L!!<*e7>7P[", APRSPacketType.positionNoTimestamp),
        (":BLN1CALL :Testing 123", APRSPacketType.message),
        (":BLN1     :Bulletin broadcast test", APRSPacketType.message),
        (":ANNOUNCE :Club meeting tonight at 7pm", APRSPacketType.message),
        ("_10090556c220s004g005t077r000p000P000h50b09900", APRSPacketType.weatherReport),
        ("T#123,456,789,123,456,789,01101001", APRSPacketType.telemetry),
        // (";Field Day*092345z4903.50N/07201.75W-", APRSPacketType.object),
        // (")Station1!4903.50N/07201.75W-", APRSPacketType.item),
        // ("?APRS?", .query),
        // (">Testing status message", .status)
    ]

    for (packetString, expectedType) in formats {
        guard let packet = APRSPacket(rawValue: packetString) else {
            #expect(Bool(false), "Failed to parse APRS packet from \(packetString).")
            return
        }
        #expect(packet.type == expectedType, "Failed for packet: \(packet)")
    }
}

@Test func testAPRSStrings() throws {
    let packetStrings = [
        "@092345z4903.50N/07201.75W-",
        "!4903.50N/07201.75W-",
        // "@092345z/5L!!<*e7>7P[",
        // "!/5L!!<*e7>7P[",
        // ":BLN1CALL :Testing 123",
        // ":BLN1     :Bulletin broadcast test",
        // ":ANNOUNCE :Club meeting tonight at 7pm",
        // "_10090556c220s004g005t077r000p000P000h50b09900",
        // "T#123,456,789,123,456,789,01101001",
        // ";Field Day*092345z4903.50N/07201.75W-",
        // ")Station1!4903.50N/07201.75W-",
        // "?APRS?",
        // ">Testing status message",
    ]

    for packetString in packetStrings {
        guard let packet = APRSPacket(rawValue: packetString) else {
            #expect(Bool(false), "Failed to parse APRS packet from \(packetString).")
            return
        }
        #expect(packetString == packet.description)
    }

}