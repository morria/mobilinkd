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
    #expect(positionPacket.comment == "")
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
    #expect(positionPacket.comment == "")
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
    #expect(positionPacket.comment == "")
}

@Test func testAPRSWeatherReport() throws {
    let packetString = "_2503011234c220s004g005t077r000p000P000h50b09900" 
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
        ("_2503011234c220s004g005t077r000p000P000h50b09900", APRSPacketType.weatherReport),
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

@Test func testEncodeBase91() throws {
    let values = [
        40000.0,
        70000.0,
        100000.0,
        10284.36311,
        12842.19420,
    ]

    for value in values {
        let encoded = encodeBase91(value)
        let decoded = decodeBase91(encoded)
        #expect(abs(value - decoded) < 0.002)
    }
}

@Test func testAPRSStrings() throws {
    let packetStrings = [
        "@092345z4903.50N/07201.75W-",
        "!4903.50N/07201.75W-",
        // "@092345z/5L!!<*e7>7P[",
        // "!/5L!!<*e7>7P[",
        ":BLN1CALL :Testing 123",
        ":BLN1     :Bulletin broadcast test",
        ":ANNOUNCE :Club meeting tonight at 7pm",
        "_2503011234c220s004g005t077r000p000P000h50b09900",
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

@Test func testPackets() throws {
    let packets = [
        "@184043h4044.46ND07337.89W&kd2edx@kd2edx.com",
        // "@184043z4404\"046M\\x3",
        // "@184043h4044.46ND07337.89W&kd2edx@kd2edx.com",
        // "@184043z4404\"046M\\x3",
        // "@011803z4113.46N/07404.15W#WX3in1Plus2.0 U=13.0V,Temp T=44.9F N2ACF Digi",
        // "@011803z44117246N&+0",
        // "@011803z4113.46N/07404.15W#WX3in1Plus2.0 U=13.0V,Temp T=44.9F N2ACF Digi",
        // "@011803z44117246N&+0",
        // "!4119.  N/07333.  W#PHG7530  fill-in digipeater www.weca.org",
        // "!11tA4N/M63",
        // "@011841z4037.21N/07405.42WriGate Grymes Hill Staten Island, NY 65.4F",
        // "@011841z4403%@21N1R0",
        // "@011841z4037.21N/07405.42WriGate Grymes Hill Staten Island, NY 65.4F",
        // "@011841z4403%@21N1R0",
        // "=4126.24N/07407.30W-PHG5230Beaver Dam Lake IGate",
        // "T#092,185,033,006,068,000,00000000",
        // "T#92,185.0,33.0,6.0,68.0,0.0,00000000",
        // "T#092,185,033,006,068,000,00000000",
        // "T#92,185.0,33.0,6.0,68.0,0.0,00000000",
        // "/184244h4047.56NS07415.09W#W2,NJ2 West Orange, NJ www.n2mh.net - 16",
        // "!3952.76N/07432.03W[005/000",
        // "!952'u36N/9w3",
        // "!4118.  N/07353.  W#PHG7300 fill-in digipeater www.weca.org",
        // "!11r:4N/M65",
        // "`eP1l!%[/`\"4<}At the QTH_0",
        // "@012022z4056.90N/07255.59W#Digi-Rocky Point,NY-----",
        // "@012022z4405$o90N\\l5",
        // "@012022z4056.90N/07255.59W#Digi-Rocky Point,NY-----",
        // "@012022z4405$o90N\\l5",
        // "=4019.39N/07438.29W+iGate",
        // "=4019.39N/07438.29W+iGate",
        // "`f[Aoz>/`\"4Z}_\"",
        // "!4024.59N/07413.10W&PHG2260/A=000065 IGate MODE",
        // "!024{r49N/iV1",
        // "`fM6l\"o-/`\"3s}_%",
        // "!3958.92N/07408.84W_wxTrak n2xp@arrl.net",
        // "!958'N32N/.m0",
        // "!3958.92N/07408.84W_wxTrak n2xp@arrl.net",
        // "!958'N32N/.m0",
        // "!4101.43NI07408.26W#Allendale WIDE1 solar digi & gate |+)\"]!s!!#j!e!!|",
        // "!101n#43NIU%0",
        // "}WLNK-1>APWLK,TCPIP,N2MH-15*::KC1G-7   :ack68",
        // "@012027z4056.90N/07255.59W#Digi-Rocky Point,NY-----",
        // "@012027z4405$o90N\\l5",
        // "@012027z4056.90N/07255.59W#Digi-Rocky Point,NY-----",
        // "@012027z4405$o90N\\l5",
        // "`fM6l\"o-/`\"3s}_%",
        // "T#107,193,080,018,064,000,00000000",
        // "T#107,193.0,80.0,18.0,64.0,0.0,00000000",
        // "}WLNK-1>APWLK,TCPIP,N2MH-15*::KC1G-7   :ack69",
        // "}WLNK-1>APWLK,TCPIP,N2MH-15*::KC1G-7   :ack69",
        // "'eVXl -/]AREA DIGIPEATER=",
        // "!4024.59N/07413.10W&PHG2260/A=000065 IGate MODE",
        // "!024{r49N/iV1",
        // "`fM6l\"o-/`\"3s}_%",
        // "!3952.86N/07431.96W[102/000",
        // "!952'u36N/9w3",
        // "}WLNK-1>APWLK,TCPIP,N2MH-15*::KC1G-7   :2) 03/01/2025 18:54:09 Re: Test Today 2/17/2025 816 bytes{8117",
        // "@011855z4025.26N/07433.92W_315/010g019t059r000p000P000b09984h44.weewx-5.1.0-Vantage",
        // "@011855z4402$E26NnY3",
        // "}WLNK-1>APWLK,TCPIP,N2MH-15*::KC1G-7   :ack71",
        // "@011856z4042.49N/07404.49W#WX3in1Plus2.0 igate@k2xap.radio",
        // "@011856z44049Y49N6P0",
        // "@011856z4042.49N/07404.49W#WX3in1Plus2.0 igate@k2xap.radio",
        // "@011856z44049Y49N6P0",
        // "@011821z4122.65N/07408.01W#ORANGE COUNTY ARES/RACES NY, Donated by KC2VTJ, U=13.7V,T=39.2F",
        // "@011821z44126z65OHR0",
        // "`eWxnq9*\`\"44}_ ",
        // "`eWxnq9*\`\"44}_ ",
        // "}WLNK-1>APWLK,TCPIP,N2MH-15*::KC1G-7   :2) 03/01/2025 18:54:09 Re: Test Today 2/17/2025 816 bytes{8117",
        // """=4040.75N/07320.15W>674/000/A=000010CSN iGate   4476min  3


        // """,
        // "=4009.20N/07458.32W-PHG5160XASTIR on a rPi - WINLINK monitored",
        // "}W2SRH>APX217,WIDE2-2:_03011859c285s016g024t058h34 ",
        // "!3952.85N/07431.88W[099/000",
        // "!952'u35N/u_3",
        // "`fM6l\"o-/`\"3s}_%",
        // "!4104.83N/07348.44W#PHG7550/W-R-T www.weca.org",
        // "!105Ts43N/T24",
        // "@011833z4113.46N/07404.15W#WX3in1Plus2.0 U=13.0V,Temp T=41.9F N2ACF Digi",
        // "@011833z44117246N&+0",
        // "!4119.  N/07333.  W#PHG7530  fill-in digipeater www.weca.org",
        // "!11tA4N/M63",
        // "=4126.24N/07407.30W-PHG5230Beaver Dam Lake IGate",
        // "`f-IlhZk/`\"4(}Listening _%",
        // "_03011525c062s005g009t051r000p003P000h58b09970tU2k",
        // "_c62s005g009t051r000p003P000h58b09970",
        // "!4155.41NS07310.35W#PHG9360/W2,CTn CSP A.R.C. W1SP",
        // "!156Ew41NS!&1",
        // "_03011950c272s003g007t047r000h59b09979weewx",
        // "_c272s003g007t047r000h59b09979",
        // "/195143h4133.29N/07238.38Wk111/042KB1BVF@GMAIL.COM or HF ALE, 52.525, 146.52, 446.00/A=000056!wXo!",
        // "`f_l^^>/`\"4]}I Beacon, therefor I am._1",
        // "T#128,193,085,020,069,000,00000000",
        // "T#128,193.0,85.0,20.0,69.0,0.0,00000000",
        // "`f^ m\y>/`\"53}I Beacon, therefor I am._1",
    ]

    for packetString in packets {
        guard let packet = APRSPacket(rawValue: packetString) else {
            #expect(Bool(false), "Failed to parse APRS packet from \(packetString).")
            return
        }
        #expect(packetString == packet.description)
    }
}