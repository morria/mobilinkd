import Foundation

// MARK: - APRS Packet Types
public enum APRSPacketType {
    case position
    case message
    case bulletin
    case weather
    case status
    case other
}

// MARK: - APRS Parsed Packet Structure
public struct APRSPacket {
    public let source: String
    public let destination: String
    public let path: [String]
    public let packetType: APRSPacketType
    public let payload: String      // Raw payload after the colon
    public let messageRecipient: String? // For messages
    public let messageText: String? // For messages
    public let bulletinID: String?  // For bulletins, e.g. "BLN1"
    public let positionData: String? // For position reports
    public let weatherData: String?  // For WX data
}

// MARK: - APRS Parser
public class APRSParser {
    
    /// Main entry point: parse a single TNC2-format APRS packet string.
    /// Example: "W1AW>APRS,TCPIP*:!1234.56N/12345.67W-Test"
    public func parse(_ rawPacket: String) -> APRSPacket? {
        // Basic TNC2 format: <source>><dest>[,<path>]:<informationField>
        // e.g. "KD6PCE>APRS,WIDE1-1,WIDE2-1:Hello"
        
        guard let tnc2Parts = splitTnc2Header(rawPacket) else {
            return nil
        }
        
        let (source, destination, pathString, payload) = tnc2Parts
        let path = pathString.isEmpty ? [] : pathString.split(separator: ",").map { String($0) }
        
        // Identify payload type
        let packetType = identifyPacketType(payload)
        
        // Extract specialized data based on packetType
        switch packetType {
        case .message:
            let (recipient, text) = parseMessage(payload)
            return APRSPacket(
                source: source,
                destination: destination,
                path: path,
                packetType: .message,
                payload: payload,
                messageRecipient: recipient,
                messageText: text,
                bulletinID: nil,
                positionData: nil,
                weatherData: nil
            )
        case .bulletin:
            let bulletinID = parseBulletinID(payload)
            return APRSPacket(
                source: source,
                destination: destination,
                path: path,
                packetType: .bulletin,
                payload: payload,
                messageRecipient: nil,
                messageText: nil,
                bulletinID: bulletinID,
                positionData: nil,
                weatherData: nil
            )
        case .weather:
            let wx = payload
            return APRSPacket(
                source: source,
                destination: destination,
                path: path,
                packetType: .weather,
                payload: payload,
                messageRecipient: nil,
                messageText: nil,
                bulletinID: nil,
                positionData: nil,
                weatherData: wx
            )
        case .position:
            return APRSPacket(
                source: source,
                destination: destination,
                path: path,
                packetType: .position,
                payload: payload,
                messageRecipient: nil,
                messageText: nil,
                bulletinID: nil,
                positionData: payload,
                weatherData: nil
            )
        case .status, .other:
            return APRSPacket(
                source: source,
                destination: destination,
                path: path,
                packetType: packetType,
                payload: payload,
                messageRecipient: nil,
                messageText: nil,
                bulletinID: nil,
                positionData: nil,
                weatherData: nil
            )
        }
    }
    
    // MARK: Helpers
    
    /// Splits a TNC2 packet line into (sou
