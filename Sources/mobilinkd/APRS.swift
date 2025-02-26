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
        return decodeAPRSPositionWithTimestamp(content)
    // Add other cases here as needed
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
    // Position format: !DDMM.mmN/DDDMM.mmW/S or compressed format
    // where first / is divider, second / is symbol table, and S is symbol
    if content.count >= 20 { // Ensure content has at least 20 characters
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
    } else if content.count >= 9 { // Handle compressed format
        let symbolTable = content[content.index(content.startIndex, offsetBy: 8)]
        let symbol = content[content.index(content.startIndex, offsetBy: 9)]
        return APRSMessage(type: .positionNoTimestamp, content: content, symbolTable: symbolTable, symbol: symbol)
    }
    return APRSMessage(type: .positionNoTimestamp, content: content)
}

func decodeAPRSPositionWithTimestamp(_ content: String) -> APRSMessage {
    let isCompressed = content.count >= 19 && content.contains("z")

    if isCompressed {
        return decodeCompressedPositionWithTimestamp(content)
    }

    return decodeStandardPositionWithTimestamp(content)
}

func decodeStandardPositionWithTimestamp(_ content: String) -> APRSMessage {
    // Position with timestamp format: @HHMMSSzDDMM.mmN/DDDMM.mmW/S
    let capturePattern = #"^([0-9]{6})z([0-9]{4}\.[0-9]{2}[NS])/([0-9]{5}\.[0-9]{2}[EW])(.)(.)$"#
    let matches = regexMatch(string: content, pattern: capturePattern)

    let timestamp = matches[0]
    let latitude = matches[1]
    let longitude = matches[2]
    let symbolTable = matches[3].first
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

func parseAPRSTimestamp(_ timestamp: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "HHmmss"
    return formatter.date(from: timestamp)
}

func decodeCompressedPositionWithTimestamp(_ content: String) -> APRSMessage {
    // Compressed position with timestamp format: @HHMMSSzDDMM.mmN/DDDMM.mmW/S
    let symbolTable = content[content.index(content.startIndex, offsetBy: 8)]
    let symbol = content[content.index(content.startIndex, offsetBy: 9)]

    let date = parseAPRSTimestamp(String(content.prefix(6)))

    return APRSMessage(
        type: .positionWithTimestamp, 
        content: content, 
        symbolTable: symbolTable, 
        symbol: symbol,
        date: date
    )
}