
import Foundation

/**
 * Take a string and a regular expression and return an array of matches
 * indexed by the capture groups in the regular expression.
 */
public func regexMatch(string: String, pattern: String) -> Array<String> {
    let captureRegex = try! NSRegularExpression(
        pattern: pattern,
        options: []
    )
    let matches = captureRegex.matches(
        in: string,
        options: [],
        range: NSRange(string.startIndex..<string.endIndex, in: string)
    )
    if let match = matches.first {
        return (1..<match.numberOfRanges).map { index in
            let range = Range(match.range(at: index), in: string)
            return range.flatMap {
                 String(string[$0])
            }!
        }
    }
    return []
}