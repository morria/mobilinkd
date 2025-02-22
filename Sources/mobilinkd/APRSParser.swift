import Foundation


// MARK: - APRS Packet Types
public enum APRSPacketType {
    case message(from: String, to: String, text: String)
    case bulletin(text: String)
    case weather(APRSWeatherData)
    case telemetry(data: String)
    case unknown(raw: String)
}

// MARK: - Weather Data Struct
public struct APRSWeatherData {
    let windDirection: Int?
    let windSpeed: Int?
    let temperature: Int?
    let humidity: Int?
    let barometricPressure: Int?
}

// MARK: - APRS Parser
public struct APRSParser {
    
    public static func parse(frame: AX25Frame) -> APRSPacketType {
        // Convert `info` field from bytes to ASCII string
        guard let payload = String(bytes: frame.info, encoding: .ascii) else {
            return .unknown(raw: "Invalid ASCII data")
        }
        
        if payload.starts(with: ":") { 
            return parseMessage(payload)
        } else if payload.starts(with: "BLN") { 
            return .bulletin(text: String(payload.dropFirst(4)))
        } else if payload.starts(with: "T#") { 
            return .telemetry(data: payload)
        } else if isWeatherReport(payload) { 
            return .weather(parseWeatherData(payload))
        }
        
        return .unknown(raw: payload)
    }
    
    private static func parseMessage(_ payload: String) -> APRSPacketType {
        let parts = payload.dropFirst().split(separator: ":", maxSplits: 2, omittingEmptySubsequences: true)
        guard parts.count >= 2 else { return .unknown(raw: String(payload)) }
        
        let recipient = String(parts[0]).trimmingCharacters(in: .whitespaces)
        let messageText = String(parts[1]).trimmingCharacters(in: .whitespaces)
        
        return .message(from: recipient, to: recipient, text: messageText)
    }
    
    private static func isWeatherReport(_ payload: String) -> Bool {
        return payload.starts(with: "!") || payload.starts(with: "/") || payload.starts(with: "@") || payload.starts(with: "_")
    }

    private static func parseWeatherData(_ payload: String) -> APRSWeatherData {
        let weatherRegex = try! NSRegularExpression(pattern: "[_!/](\\d{3})/(\\d{3})g?(\\d{3})?t(-?\\d{2,3})r(\\d{3})p(\\d{3})P(\\d{3})h(\\d{2})b(\\d{5})")
        
        if let match = weatherRegex.firstMatch(in: payload, range: NSRange(payload.startIndex..., in: payload)) {
            return APRSWeatherData(
                windDirection: extractInt(from: payload, match: match, at: 1),
                windSpeed: extractInt(from: payload, match: match, at: 2),
                temperature: extractInt(from: payload, match: match, at: 4),
                humidity: extractInt(from: payload, match: match, at: 8),
                barometricPressure: extractInt(from: payload, match: match, at: 9)
            )
        }
        
        return APRSWeatherData(windDirection: nil, windSpeed: nil, temperature: nil, humidity: nil, barometricPressure: nil)
    }
    
    private static func extractInt(from payload: String, match: NSTextCheckingResult, at index: Int) -> Int? {
        if let range = Range(match.range(at: index), in: payload) {
            return Int(payload[range])
        }
        return nil
    }
}
