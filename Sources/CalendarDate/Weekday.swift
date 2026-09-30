/// A day of the week.
///
/// The raw values match `Calendar.component(.weekday, from:)` for a Gregorian calendar (Sunday is 1), so
/// existing code that holds that number can convert with `Weekday(rawValue:)`. The number is not the
/// stored form: `Codable` writes the lowercase English name, such as `"monday"`, because a bare number is
/// easy to misread as ISO 8601's Monday-is-1 numbering on a server or in another language.
public enum Weekday: Int, Sendable, Hashable, CaseIterable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    /// The lowercase English name, which is the `Codable` form: `"sunday"` through `"saturday"`.
    public var name: String {
        switch self {
        case .sunday: "sunday"
        case .monday: "monday"
        case .tuesday: "tuesday"
        case .wednesday: "wednesday"
        case .thursday: "thursday"
        case .friday: "friday"
        case .saturday: "saturday"
        }
    }

    /// Reads a lowercase English name, and returns nil for anything else, including a number or `"Monday"`.
    ///
    /// - Parameter name: The name to read.
    public init?(name: String) {
        guard let weekday = Self.allCases.first(where: { $0.name == name }) else { return nil }
        self = weekday
    }
}

extension Weekday: Codable {
    /// Decodes a lowercase English name such as `"monday"`, and fails on anything else.
    ///
    /// - Parameter decoder: The decoder to read from.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let weekday = Weekday(name: text) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a lowercase weekday name such as \"monday\", got \"\(text)\""
            )
        }
        self = weekday
    }

    /// Encodes the weekday as its lowercase English name.
    ///
    /// - Parameter encoder: The encoder to write to.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
    }
}
