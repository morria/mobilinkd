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
}

public func decodeAPRS(_ info: String) -> APRSMessage {
    guard let firstChar = info.first, let messageType = APRSMessageType(rawValue: firstChar) else {
        return APRSMessage(type: .unknown, sender: nil, receiver: nil, content: info, symbolTable: nil, symbol: nil)
    }
    
    let content = String(info.dropFirst())
    switch messageType {
    case .message:
        return decodeAPRSMessage(content)
    case .positionNoTimestamp:
        return decodeAPRSPosition(content)
    // Add other cases here as needed
    default:
        return APRSMessage(type: messageType, sender: nil, receiver: nil, content: content, symbolTable: nil, symbol: nil)
    }
}

private func decodeAPRSPosition(_ content: String) -> APRSMessage {
    // Position format: !DDMM.mmN/DDDMM.mmW/S or compressed format
    // where first / is divider, second / is symbol table, and S is symbol
    if content.count >= 20 { // Ensure content has at least 20 characters
        let capturePattern = #"^([0-9]{4}\.[0-9]{2}[NS])/([0-9]{5}\.[0-9]{2}[EW])(.)(.)$"#
        let captureRegex = try! NSRegularExpression(
            pattern: capturePattern,
            options: []
        )
        let matches = captureRegex.matches(
            in: content,
            options: [],
            range: NSRange(content.startIndex..<content.endIndex, in: content)
        )
        if let match = matches.first, match.numberOfRanges == 6 {
            let latitudeRange = Range(match.range(at: 1), in: content)
            let longitudeRange = Range(match.range(at: 2), in: content)
            let symbolTableRange = Range(match.range(at: 3), in: content)
            let symbolRange = Range(match.range(at: 4), in: content)
            let latitude = latitudeRange.flatMap { String(content[$0]) }
            let symbolTable = symbolTableRange.flatMap { String(content[$0]) }
            let longitude = longitudeRange.flatMap { String(content[$0]) }
            let symbol = symbolRange.flatMap { String(content[$0]) }
            return APRSMessage(
                type: .positionNoTimestamp,
                sender: nil,
                receiver: nil,
                content: content,
                symbolTable: symbolTable?.first,
                symbol: symbol?.first
            )
        }
    } else if content.count >= 9 { // Handle compressed format
        // let symbolTable = content[content.index(content.startIndex, offsetBy: 8)]
        // let symbol = content[content.index(content.startIndex, offsetBy: 9)]
        // return APRSMessage(type: .positionNoTimestamp, sender: nil, receiver: nil, content: content, symbolTable: symbolTable, symbol: symbol)
    }
    return APRSMessage(type: .positionNoTimestamp, sender: nil, receiver: nil, content: content, symbolTable: nil, symbol: nil)
}

private func decodeAPRSMessage(_ data: String) -> APRSMessage {
    // APRS message format: ":ADDRESSEE  :MESSAGE_TEXT"
    let parts = data.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: true)
    
    guard parts.count == 2 else {
        return APRSMessage(type: .message, sender: nil, receiver: nil, content: data, symbolTable: nil, symbol: nil)
    }
    
    let receiver = parts[0].trimmingCharacters(in: .whitespaces)
    let messageText = parts[1]

    return APRSMessage(type: .message, sender: nil, receiver: receiver, content: String(messageText), symbolTable: nil, symbol: nil)
}