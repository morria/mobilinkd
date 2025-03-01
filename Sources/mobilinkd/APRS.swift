import Foundation

// MARK: - Message
public struct MessagePacket {
    // TODO: Cannot be nil?
    public let fromCallsign: String?
    public let toCallsign: String
    public let messageText: String
    public let acknowledgment: String?

    public let type: APRSPacketType = .message
    public var description: String {
        return """
        \(self.type.rawValue)\
        \(self.toCallsign.padding(toLength: 9, withPad: " ", startingAt: 0)):\
        \(self.messageText)
        """
    }

    public init?(rawValue: String) {
        let parts = rawValue.split(
            separator: ":", 
            maxSplits: 2, 
            omittingEmptySubsequences: true
        )
        
        guard parts.count == 2 else {
            return nil
        }

        self.fromCallsign = nil
        self.toCallsign = parts[0].trimmingCharacters(in: .whitespaces)
        self.messageText = String(parts[1])
        self.acknowledgment = nil
    }

}

// MARK: - Position (No Timestamp)
public struct PositionNoTimestampPacket : CustomStringConvertible {
    public let latitude: Double
    public let longitude: Double
    public let symbolTable: Character?
    public let symbolCode: Character?
    public let comment: String?

    public var isCompressed: Bool = false
    public var type: APRSPacketType = .positionNoTimestamp
    public var description: String {
        return isCompressed ? """
        \(self.type.rawValue)\
        \(encodeBase91(Double(latitude)))\
        \(symbolTable ?? " ")\
        \(encodeBase91(Double(longitude)))\
        \(symbolCode ?? " ")\
        \(comment ?? "")
        """ : """
        \(self.type.rawValue)\
        \(String(format: "%07.2f", abs(latitude)))\
        \(latitude > 0 ? "N" : "S")\
        \(symbolTable ?? " ")\
        \(String(format: "%08.2f", abs(longitude)))\
        \(longitude > 0 ? "E" : "W")\
        \(symbolCode ?? " ")\
        \(comment ?? "")
        """
    }

    public init(latitude: Double, longitude: Double, symbolTable: Character?, symbolCode: Character?, comment: String?, isCompressed: Bool = false) {
        self.latitude = latitude
        self.longitude = longitude
        self.symbolTable = symbolTable
        self.symbolCode = symbolCode
        self.comment = comment
        self.isCompressed = isCompressed
    }

    public init?(rawValue: String) {
        if Self.isCompressed(rawValue) {
            guard let result = Self.fromCompressed(rawValue: rawValue) else { return nil }
            self = result
        } else {
            guard let result = Self.fromUncompressed(rawValue: rawValue) else { return nil }
            self = result
        }
    }

    private static func isCompressed(_ rawValue: String) -> Bool {
        // Check if the packet string contains latitude and longitude in degrees and minutes format
        let pattern = #"([0-9]{4}\.[0-9]{2}[NS].[0-9]{5}\.[0-9]{2}[EW])"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: rawValue.count - 1)
        let match = regex.firstMatch(in: rawValue, options: [], range: range)
        return match == nil
    }

    /**
     * Decode an APRS position (compressed) with no timestamp.
     * Example: "!/5L!!<*e7>7P["
     */
    private static func fromCompressed(rawValue: String) -> Self? {
        // Compressed position with no timestamp format: !/5L!!<*e7>7P[
        let symbolTable = rawValue[rawValue.index(rawValue.startIndex, offsetBy: 0)]
        let encodedLat = rawValue[rawValue.index(rawValue.startIndex, offsetBy: 1)...rawValue.index(rawValue.startIndex, offsetBy: 5)]
        let encodedLon = rawValue[rawValue.index(rawValue.startIndex, offsetBy: 6)...rawValue.index(rawValue.startIndex, offsetBy: 10)]
        let symbolCode = rawValue[rawValue.index(rawValue.startIndex, offsetBy: 12)]
        let comment = String(rawValue[rawValue.index(rawValue.startIndex, offsetBy: 13)...])

        let latitude = decodeBase91(String(encodedLat))
        let longitude = decodeBase91(String(encodedLon))

        return PositionNoTimestampPacket(
            latitude: latitude,
            longitude: longitude,
            symbolTable: symbolTable,
            symbolCode: symbolCode,
            comment: comment,
            isCompressed: Bool(true)
        )
    }

    /**
     * Decode an APRS position (compressed) with no timestamp.
     * Example: "!4903.50N/07201.75W-"
     */
    private static func fromUncompressed(rawValue: String) -> Self?{
        let capturePattern = #"^([0-9]{4}\.[0-9]{2}[NS])(.)([0-9]{5}\.[0-9]{2}[EW])(.)(.*)$"#
        let matches = regexMatch(string: rawValue, pattern: capturePattern)

        guard var latitude = Double(matches[0].dropLast()) else {
            return nil
        }
        if matches[0].last == "S" {
            latitude = -latitude
        }

        guard var longitude = Double(matches[2].dropLast()) else {
            return nil
        }
        if matches[2].last == "W" {
            longitude = -longitude
        }

        let symbolTable = matches[1].first
        let symbolCode = matches[3].first

        let comment = matches[4]

        return PositionNoTimestampPacket(
            latitude: latitude,
            longitude: longitude,
            symbolTable: symbolTable,
            symbolCode: symbolCode,
            comment: comment,
            isCompressed: Bool(false)
        )
    }

}

// MARK: - Position (With Timestamp)
public struct PositionWithTimestampPacket {
    public let latitude: Double
    public let longitude: Double
    public let timestamp: Date
    public let symbolTable: Character?
    public let symbolCode: Character?
    public let comment: String?

    public var isCompressed: Bool = false
    public var timeMode: Character
    public var type: APRSPacketType = .positionWithTimestamp
    public var description: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmmss"
        let timestampString = formatter.string(from: timestamp)

        return isCompressed ? """
        \(self.type.rawValue)\
        \(timestampString)\
        \(timeMode)\
        \(symbolTable ?? " ")\
        \(encodeBase91(Double(latitude)))\
        \(encodeBase91(Double(longitude)))\
        \(symbolCode ?? " ")\
        \(comment ?? "")
        """ : """
        \(self.type.rawValue)\
        \(timestampString)\
        \(timeMode)\
        \(String(format: "%07.2f", abs(latitude)))\
        \(latitude > 0 ? "N" : "S")\
        \(symbolTable ?? " ")\
        \(String(format: "%08.2f", abs(longitude)))\
        \(longitude > 0 ? "E" : "W")\
        \(symbolCode ?? " ")\
        \(comment ?? "")
        """
    }

    public init(latitude: Double, longitude: Double, timestamp: Date, symbolTable: Character?, symbolCode: Character?, comment: String?, isCompressed: Bool = false, timeMode: Character) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.symbolTable = symbolTable
        self.symbolCode = symbolCode
        self.comment = comment
        self.isCompressed = isCompressed
        self.timeMode = timeMode
    }

    public init?(rawValue: String) {
        if Self.isCompressed(rawValue) {
            guard let result = Self.fromCompressed(rawValue: rawValue) else { return nil }
            self = result
        } else {
            guard let result = Self.fromUncompressed(rawValue: rawValue) else { return nil }
            self = result
        }
    }

    private static func isCompressed(_ rawValue: String) -> Bool {
        let pattern = #"([0-9]{4}\.[0-9]{2}[NS].[0-9]{5}\.[0-9]{2}[EW])"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 1, length: rawValue.count - 1)
        return regex.firstMatch(in: rawValue, options: [], range: range) == nil
    }

    /**
     * Decode an APRS position (compressed) with no timestamp.
     * Example: "@092345z/5L!!<*e7>7P["
     */
    private static func fromCompressed(rawValue: String) -> Self? {
        // Compressed position with timestamp format: @HHMMSSz/5L!!<*e7>7P[
        let timestamp = String(rawValue.prefix(6))
        let symbolTable = rawValue[rawValue.index(rawValue.startIndex, offsetBy: 7)]
        let encodedLat = rawValue[rawValue.index(rawValue.startIndex, offsetBy: 7)...rawValue.index(rawValue.startIndex, offsetBy: 11)]
        let encodedLon = rawValue[rawValue.index(rawValue.startIndex, offsetBy: 12)...rawValue.index(rawValue.startIndex, offsetBy: 16)]
        let symbolCode = rawValue[rawValue.index(rawValue.startIndex, offsetBy: 19)]
        let latitude = decodeBase91(String(encodedLat))
        let longitude = decodeBase91(String(encodedLon))

        let timeMode = rawValue[rawValue.index(rawValue.startIndex, offsetBy: 6)]

        guard let timestamp = Self.parseTimestamp(timestamp, timeMode: timeMode) else {
            return nil
        }

        return PositionWithTimestampPacket(
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            symbolTable: symbolTable,
            symbolCode: symbolCode,
            comment: nil,
            isCompressed: Bool(true),
            timeMode: timeMode
        )
    }

    /**
     * Decode an APRS position (uncompressed) with a timestamp.
     * Exmaple: "@092345z4903.50N/07201.75W-"
     */
    private static func fromUncompressed(rawValue: String) -> Self? {

        // Position with timestamp format: @HHMMSSzDDMM.mmN/DDDMM.mmW/S
        let capturePattern = #"^([0-9]{6})(.)([0-9]{4}\.[0-9]{2}[NS])(.)([0-9]{5}\.[0-9]{2}[EW])(.)(.*)$"#
        let matches = regexMatch(string: rawValue, pattern: capturePattern)

        let timestamp = matches[0]
        let timeMode = matches[1].first!
        guard let timestamp = Self.parseTimestamp(timestamp, timeMode: timeMode) else {
            return nil
        }

        guard var latitude = Double(matches[2].dropLast()) else {
            return nil
        }
        if matches[2].last == "S" {
            latitude = -latitude
        }

        let symbolTable = matches[3].first
        guard var longitude = Double(matches[4].dropLast()) else {
            return nil
        }
        if matches[4].last == "W" {
            longitude = -longitude
        }
        guard let symbolCode = matches[5].first else {
            return nil
        }

        let comment = matches[6]

        return PositionWithTimestampPacket(
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            symbolTable: symbolTable,
            symbolCode: symbolCode,
            // TODO: This isn't correct.
            comment: comment,
            isCompressed: Bool(false),
            timeMode: timeMode
        )

    }

    private static func parseTimestamp(_ timestamp: String, timeMode: Character) -> Date? {
        let formatter = DateFormatter()
        switch timeMode {
        case "z":
            formatter.dateFormat = "HHmmss"
        case "/":
            formatter.dateFormat = "yyMMddHHmmss"
        case "\\":
            formatter.dateFormat = "MMddHHmm"
        default:
            formatter.dateFormat = "HHmmss"
        }
        return formatter.date(from: timestamp)
    }

}

// MARK: - Position (With Messaging)
public struct PositionWithMessagingPacket {
    public let latitude: Double
    public let longitude: Double
    public let timestamp: Date?
    public let messagingEnabled: Bool
    public let symbolTable: Character?
    public let symbolCode: Character?
    public let comment: String?

    public var type: APRSPacketType {
        return timestamp == nil ? .positionNoTimestamp : .positionWithTimestamp
    }
    public var description: String {
        return """
        \(self.type.rawValue)
        """
    }
    // public var description: String {
    //     let formatter = DateFormatter()
    //     formatter.dateFormat = "HHmmss"
    //     let timestampString = formatter.string(from: timestamp)
    //     return """
    //     \(self.type.rawValue)\
    //     \(timestampString)\
    //     \(String(format: "%08.4f", latitude))\
    //     \(symbolTable ?? " ")\
    //     \(String(format: "%09.4f", longitude))\
    //     \(symbolCode ?? " ")\
    //     \(comment ?? "")
    //     """
    // }
}

// MARK: - Weather
public struct WeatherPacket {
    public let timestamp: Date?
    public let latitude: Double?
    public let longitude: Double?
    public let windDirection: Int?
    public let windSpeed: Int?
    public let windGust: Int?
    public let temperatureF: Double?
    public let rainfallLastHour: Double?
    public let rainfallLast24h: Double?
    public let rainfallSinceMidnight: Double?
    public let humidity: Int?
    public let pressure: Double?
    public let comment: String?

    public let type: APRSPacketType = .weatherReport
    public var description: String {
        var description  = "\(self.type.rawValue)"
        if let timestamp = timestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyMMddHHmm"
            description += formatter.string(from: timestamp)
        }
        if let windDirection = windDirection {
            description += "c\(windDirection)"
        }
        if let windSpeed = windSpeed {
            description += "s\(String(format: "%03d", windSpeed))"
        }
        if let windGust = windGust {
            description += "g\(String(format: "%03d", windGust))"
        }
        if let temperatureF = temperatureF {
            description += "t\(String(format: "%03d", Int(temperatureF)))"
        }
        if let rainfallLastHour = rainfallLastHour {
            description += "r\(String(format: "%03d", Int(rainfallLastHour)))"
        }
        if let rainfallLast24h = rainfallLast24h {
            description += "p\(String(format: "%03d", Int(rainfallLast24h)))"
        }
        if let rainfallSinceMidnight = rainfallSinceMidnight {
            description += "P\(String(format: "%03d", Int(rainfallSinceMidnight)))"
        }
        if let humidity = humidity {
            description += "h\(humidity)"
        }
        if let pressure = pressure {
            description += "b\(String(format: "%05d", Int(pressure)))"
        }
        if let comment = comment {
            description += "\(comment)"
        }
        return description
    }

    /**
     * Decode an APRS weather report.
     * Example: "_10090556c220s004g005t077r000p000P000h50b09900" 
     */
    public init?(rawValue: String) {

        // Example: "_10090556c220s004g005t077r000p000P000h50b09900"
        // Remove leading underscore if present
        var data = rawValue.hasPrefix("_") ? String(rawValue.dropFirst()) : rawValue

        var timestampString : String? = nil

        let regex = try! NSRegularExpression(pattern: "^([0-9]*)(.*)$")
        if let match = regex.firstMatch(in: data, options: [], range: NSRange(location: 0, length: data.utf16.count)) {
            if let timestampRange = Range(match.range(at: 1), in: data) {
                timestampString = String(data[timestampRange])
            }
            if let nonTimestampRange = Range(match.range(at: 2), in: data) {
                data = String(data[nonTimestampRange])
            }
        }

        let windDirection = matchAfterPrefix(data, prefix: "c")
        let windSpeed     = matchAfterPrefix(data, prefix: "s")
        let windGust      = matchAfterPrefix(data, prefix: "g")
        let tempF         = matchAfterPrefix(data, prefix: "t")
        let rainLastHour  = matchAfterPrefix(data, prefix: "r")
        let rain24        = matchAfterPrefix(data, prefix: "p")
        let rainMidnight  = matchAfterPrefix(data, prefix: "P")
        let humidity      = matchAfterPrefix(data, prefix: "h")
        let baro          = matchAfterPrefix(data, prefix: "b")

        if timestampString == nil {
            self.timestamp = nil
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyMMddHHmm"
            self.timestamp = formatter.date(from: timestampString!)
        }

        self.latitude = nil
        self.longitude = nil
        self.windDirection = Int(windDirection ?? "")
        self.windSpeed = Int(windSpeed ?? "")
        self.windGust = Int(windGust ?? "")
        self.temperatureF = Double(tempF ?? "")
        self.rainfallLastHour = Double(rainLastHour ?? "")
        self.rainfallLast24h = Double(rain24 ?? "")
        self.rainfallSinceMidnight = Double(rainMidnight ?? "")
        self.humidity = Int(humidity ?? "")
        self.pressure = Double(baro ?? "")
        self.comment = nil
    }
}

// MARK: - Status
public struct StatusPacket {
    public let sourceCallsign: String
    public let statusText: String
    public let timestamp: Date?

    public let type: APRSPacketType = .status
    public var description: String {
        return """
        \(self.type.rawValue)
        """
    }
}


// MARK: - Telemetry
public struct TelemetryPacket {
    public let sequenceNumber: Int
    public let analogValues: [Double]   // e.g., up to 5 channels
    public let digitalValues: [Bool]    // e.g., up to 8 bits
    public let comment: String?

    public let type: APRSPacketType = .telemetry

    // Example: "T#123,456,789,012,345
    public var description: String {
        return """
        \(self.type.rawValue)#\
        \(self.sequenceNumber),\
        \(self.analogValues.map { String($0) }.joined(separator: ",")),\
        \(self.digitalValues.map { $0 ? "1" : "0" }.joined(separator: ""))
        """
    }

    public init?(rawValue: String) {
        guard let valuesString = rawValue.split(separator: "#").last else {
            return nil
        }

        let parts = valuesString.split(separator: ",")
        guard parts.count >= 1 else {
            return nil
        }

        self.sequenceNumber = Int(parts[0]) ?? 0
        self.digitalValues = parts.last?.map { $0 == "1" } ?? []
        self.analogValues = parts[1..<parts.count-1].compactMap { Double($0) }
        self.comment = nil
    }
}


// MARK: - Object
public struct ObjectPacket {
    public let name: String
    public let latitude: Double?
    public let longitude: Double?
    public let timestamp: Date?
    public let symbolTable: Character?
    public let symbolCode: Character?
    public let alive: Bool        // 'Alive' (real-time) vs. 'Killed'
    public let comment: String?

    public let type: APRSPacketType = .object
    public var description: String {
        return """
        \(self.type.rawValue)
        """
    }
}

// MARK: - Item
public struct ItemPacket {
    public let name: String
    public let latitude: Double?
    public let longitude: Double?
    public let symbolTable: Character?
    public let symbolCode: Character?
    public let comment: String?

    public let type: APRSPacketType = .item
    public var description: String {
        return """
        \(self.type.rawValue)
        """
    }
}

// MARK: - Query
public struct QueryPacket {
    public let rawQuery: String
    // Could include parsed details for e.g. station info requests, etc.

    public let type: APRSPacketType = .query
    public var description: String {
        return """
        \(self.type.rawValue)
        """
    }
}

public enum APRSPacketType: Character, CaseIterable {
    case message = ":"
    case positionNoTimestamp = "!"
    case positionWithTimestamp = "@"
    case weatherReport = "_"
    case telemetry = "T"
    case object = ";"
    case item = ")"
    case query = "?"
    case status = ">"
    case unknown = " "
}

// MARK: - Unified Enum
public enum APRSPacket: CustomStringConvertible {
    case positionNoTimestamp(PositionNoTimestampPacket)
    case positionWithTimestamp(PositionWithTimestampPacket)
    case positionWithMessaging(PositionWithMessagingPacket)
    case status(StatusPacket)
    case message(MessagePacket)
    case telemetry(TelemetryPacket)
    case weather(WeatherPacket)
    case object(ObjectPacket)
    case item(ItemPacket)
    case query(QueryPacket)

    public var description: String {
        switch self {
        case .positionNoTimestamp(let packet):
            return packet.description
        case .positionWithTimestamp(let packet):
            return packet.description
        case .positionWithMessaging(let packet):
            return packet.description
        case .status(let packet):
            return packet.description
        case .message(let packet):
            return packet.description
        case .telemetry(let packet):
            return packet.description
        case .weather(let packet):
            return packet.description
        case .object(let packet):
            return packet.description
        case .item(let packet):
            return packet.description
        case .query(let packet):
            return packet.description
        }
    }

    public var type: APRSPacketType {
        switch self {
        case .message(_):
            return .message
        case .positionNoTimestamp(_):
            return .positionNoTimestamp
        case .positionWithTimestamp(_):
            return .positionWithTimestamp
        case .positionWithMessaging(_):
            // Assuming messaging packets share the same indicator as position with timestamp.
            return .positionWithTimestamp
        case .status(_):
            return .status
        case .telemetry(_):
            return .telemetry
        case .weather(_):
            return .weatherReport
        case .object(_):
            return .object
        case .item(_):
            return .item
        case .query(_):
            return .query
        }
    }

    public init?(rawValue: String) {
        guard let firstChar = rawValue.first else {
            return nil
        }

        guard let messageType = APRSPacketType(rawValue: firstChar) else {
            return nil
        }
        
        let content = String(rawValue.dropFirst())

        switch messageType {
        case .message:
            guard let packet = MessagePacket(rawValue: content) else {
                return nil
            }
            self = .message(packet)
        case .positionNoTimestamp:
            guard let packet = PositionNoTimestampPacket(rawValue: content) else {
                return nil
            }
            self = .positionNoTimestamp(packet)
        case .positionWithTimestamp:
            guard let packet = PositionWithTimestampPacket(rawValue: content) else {
                return nil
            }
            self = .positionWithTimestamp(packet)
        case .weatherReport:
            guard let packet = WeatherPacket(rawValue: content) else {
                return nil
            }
            self = .weather(packet)
        case .telemetry:
            guard let packet = TelemetryPacket(rawValue: content) else {
                return nil
            }
            self = .telemetry(packet)
        // case .object:
        //     return decodeAPRSObject(content)
        // case .item:
        //     return decodeAPRSItem(content)
        // case .query:
        //     return decodeAPRSQuery(content)
        // case .status:
        //     return decodeAPRSStatus(content)
        default:
            return nil
        }
    }
}

public func decodeBase91(_ encoded: String) -> Double {
    let base91Chars = Array(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
    )
    var value: Int = 0
    for char in encoded {
        if let index = base91Chars.firstIndex(of: char) {
            value = value * 91 + index
        }
    }

    let degrees = value / 380926
    let minutes = (value % 380926) / 6351
    let seconds = Double(value % 6351) / 105.0

    let decimalDegrees = Double(degrees) + Double(minutes) / 60.0 + seconds / 3600.0

    return decimalDegrees
}

public func encodeBase91(_ value: Double) -> String {
    let degrees = Int(value)
    let minutes = Int((value - Double(degrees)) * 60)
    let seconds = Int(((value - Double(degrees)) * 60 - Double(minutes)) * 60)

    let base91Chars = Array(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
    )

    let encoded = degrees * 380926 + minutes * 6351 + seconds * 105

    var result = ""
    var encodedValue = encoded
    while encodedValue > 0 {
        let index = encodedValue % 91
        result = String(base91Chars[index]) + result
        encodedValue /= 91
    }

    return result
}

// Utility to find digits after a known letter. Adjust to parse the exact number of digits if needed.
private func matchAfterPrefix(_ data: String, prefix: Character) -> String? {
    guard let range = data.range(of: "\(prefix)[0-9]+", options: .regularExpression) else {
        return nil
    }
    return String(data[range].dropFirst()) // drop the letter
}