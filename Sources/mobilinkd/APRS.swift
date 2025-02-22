
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
}

public func decodeAPRS(_ info: String) -> APRSMessage {
    guard let firstChar = info.first, let messageType = APRSMessageType(rawValue: firstChar) else {
        return APRSMessage(type: .unknown, sender: nil, receiver: nil, content: info)
    }
    
    let content = String(info.dropFirst())

    if messageType == .message {
        return decodeAPRSMessage(content)
    }

    return APRSMessage(type: messageType, sender: nil, receiver: nil, content: content)
}

private func decodeAPRSMessage(_ data: String) -> APRSMessage {
    // APRS message format: ":ADDRESSEE  :MESSAGE_TEXT"
    let parts = data.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: true)
    
    guard parts.count == 2 else {
        return APRSMessage(type: .message, sender: nil, receiver: nil, content: data)
    }
    
    let receiver = parts[0].trimmingCharacters(in: .whitespaces)
    let messageText = parts[1]

    return APRSMessage(type: .message, sender: nil, receiver: receiver, content: String(messageText))
}