import Foundation

public enum APRSMessageType: Character {
    case positionNoTimestamp = "!"
    case positionWithTimestamp = "@"
    case positionWithMessaging = "="
    case status = ">"
    case message = ":"
    case telemetry = "T"
    case weatherReport = "_"
    case object = ";"
    case item = ")"
    case query = "?"
    case unknown = "u"

    public var description: String {
        switch self {
        case .positionNoTimestamp: return "Position (no timestamp)"
        case .positionWithTimestamp: return "Position (with timestamp)"
        case .positionWithMessaging: return "Position (with messaging)"
        case .status: return "Status"
        case .message: return "Message"
        case .telemetry: return "Telemetry"
        case .weatherReport: return "Weather Report"
        case .object: return "Object"
        case .item: return "Item"
        case .query: return "Query"
        case .unknown: return "Unknown"
        }
    }
}

public struct APRSMessage {
    public let type: APRSMessageType
    public let sender: String?
    public let receiver: String?
    public let content: String
    public let symbolTable: Character?
    public let symbol: Character?
    public let latitude: String?
    public let longitude: String?
    public let date: Date?

    public init(
        type: APRSMessageType,
        sender: String? = nil,
        receiver: String? = nil,
        content: String,
        symbolTable: Character? = nil,
        symbol: Character? = nil,
        latitude: String? = nil,
        longitude: String? = nil,
        date: Date? = nil
    ) {
        self.type = type
        self.sender = sender
        self.receiver = receiver
        self.content = content
        self.symbolTable = symbolTable
        self.symbol = symbol
        self.latitude = latitude
        self.longitude = longitude
        self.date = date
    }
}

public func decodeAPRS(_ info: String) -> APRSMessage {
    guard let firstChar = info.first, let messageType = APRSMessageType(rawValue: firstChar) else {
        return APRSMessage(type: .unknown, content: info)
    }
    
    let content = String(info.dropFirst())
    switch messageType {
    case .message:
        return decodeAPRSMessage(content)
    case .positionNoTimestamp:
        return decodeAPRSPosition(content)
    case .positionWithTimestamp:
        return decodeAPRSPosition(content)
    default:
        return APRSMessage(type: messageType, content: content)
    }
}

func decodeAPRSMessage(_ data: String) -> APRSMessage {
    let parts = data.split(
        separator: ":", 
        maxSplits: 2, 
        omittingEmptySubsequences: true
    )
    
    guard parts.count == 2 else {
        return APRSMessage(
            type: .message, 
            content: data
        )
    }
    
    return APRSMessage(
        type: .message,
        receiver: parts[0].trimmingCharacters(in: .whitespaces),
        content: String(parts[1])
    )
}

func decodeAPRSPosition(_ content: String) -> APRSMessage {

    switch content.count {
        case 26:
            // "@092345z4903.50N/07201.75W-"
            return decodeAPRSPositionUncompressedWithTimestamp(content)
        case 20:
            // "@092345z/5L!!<*e7>7P["
            return decodeAPRSPositionCompressedWithTimestamp(content)
        case 19:
            // "!4903.50N/07201.75W-"
            return decodeAPRSPositionUncompressedNoTimestamp(content)
        case 13:
            // "!/5L!!<*e7>7P["
            return decodeAPRSPositionCompressedNoTimestamp(content)
        default:
            return APRSMessage(type: .unknown, content: content)
    }
}

/**
 * Decode an APRS position (compressed) with no timestamp.
 * Example: "!4903.50N/07201.75W-"
 */
func decodeAPRSPositionUncompressedNoTimestamp(_ content: String) -> APRSMessage {
    let capturePattern = #"^([0-9]{4}\.[0-9]{2}[NS])/([0-9]{5}\.[0-9]{2}[EW])(.)(.)$"#
    let matches = regexMatch(string: content, pattern: capturePattern)

    let latitude = matches[0]
    let longitude = matches[1]
    let symbolTable = matches[2].first
    let symbol = matches[3].first

    return APRSMessage(
        type: .positionNoTimestamp,
        content: content,
        symbolTable: symbolTable,
        symbol: symbol,
        latitude: latitude,
        longitude: longitude
    )
}

/**
 * Decode an APRS position (uncompressed) with a timestamp.
 * Exmaple: "@092345z4903.50N/07201.75W-"
 */
func decodeAPRSPositionUncompressedWithTimestamp(_ content: String) -> APRSMessage {

    // Position with timestamp format: @HHMMSSzDDMM.mmN/DDDMM.mmW/S
    let capturePattern = #"^([0-9]{6})z([0-9]{4}\.[0-9]{2}[NS])(.)([0-9]{5}\.[0-9]{2}[EW])(.)$"#
    let matches = regexMatch(string: content, pattern: capturePattern)

    let timestamp = matches[0]
    let latitude = matches[1]
    let symbolTable = matches[2].first
    let longitude = matches[3]
    let symbol = matches[4].first

    return APRSMessage(
        type: .positionWithTimestamp,
        content: content,
        symbolTable: symbolTable,
        symbol: symbol,
        latitude: latitude,
        longitude: longitude,
        date: parseAPRSTimestamp(timestamp)
    )
}

/**
 * Decode an APRS position (compressed) with no timestamp.
 * Example: "@092345z/5L!!<*e7>7P["
 */
func decodeAPRSPositionCompressedWithTimestamp(_ content: String) -> APRSMessage {
    // Compressed position with timestamp format: @HHMMSSz/5L!!<*e7>7P[
    let timestamp = String(content.prefix(6))
    let symbolTable = content[content.index(content.startIndex, offsetBy: 7)]
    let encodedLat = content[content.index(content.startIndex, offsetBy: 7)...content.index(content.startIndex, offsetBy: 11)]
    let encodedLon = content[content.index(content.startIndex, offsetBy: 12)...content.index(content.startIndex, offsetBy: 16)]
    let symbol = content[content.index(content.startIndex, offsetBy: 19)]
    let latitude = decodeBase91(encodedLat)
    let longitude = decodeBase91(encodedLon)
    let date = parseAPRSTimestamp(timestamp)
    return APRSMessage(
        type: .positionWithTimestamp,
        content: content,
        symbolTable: symbolTable,
        symbol: symbol,
        latitude: latitude,
        longitude: longitude,
        date: date
    )
}

/**
 * Decode an APRS position (compressed) with no timestamp.
 * Example: "!/5L!!<*e7>7P["
 */
func decodeAPRSPositionCompressedNoTimestamp(_ content: String) -> APRSMessage {
    // Compressed position with no timestamp format: !/5L!!<*e7>7P[
    let symbolTable = content[content.index(content.startIndex, offsetBy: 0)]
    let encodedLat = content[content.index(content.startIndex, offsetBy: 1)...content.index(content.startIndex, offsetBy: 5)]
    let encodedLon = content[content.index(content.startIndex, offsetBy: 6)...content.index(content.startIndex, offsetBy: 10)]
    let symbol = content[content.index(content.startIndex, offsetBy: 12)]
    let latitude = decodeBase91(encodedLat)
    let longitude = decodeBase91(encodedLon)
    return APRSMessage(
        type: .positionNoTimestamp,
        content: content,
        symbolTable: symbolTable,
        symbol: symbol,
        latitude: latitude,
        longitude: longitude
    )
}

func parseAPRSTimestamp(_ timestamp: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "HHmmss"
    return formatter.date(from: timestamp)
}

func decodeBase91(_ encoded: Substring) -> String {
    let base91Chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~")
    var value: Int = 0
    for char in encoded {
        if let index = base91Chars.firstIndex(of: char) {
            value = value * 91 + index
        }
    }
    let degrees = value / 380926
    let minutes = (value % 380926) / 6351
    // Convert Int to Double before division
    let seconds = Double(value % 6351) / 105.0
    return String(format: "%02d%02d.%02d", degrees, minutes, Int(seconds))
}