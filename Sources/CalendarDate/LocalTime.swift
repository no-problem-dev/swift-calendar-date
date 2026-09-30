import Foundation

/// A time on a wall clock to the minute, with no date and no time zone, such as 15:30.
///
/// Timetables, opening hours and "around 15:30" are wall-clock times. Pair one with a ``LocalDate`` and
/// a time zone to get the instant it names, with ``LocalDate/instant(at:in:)``. The `Codable` and text
/// form is `HH:mm` on a 24-hour clock.
public struct LocalTime: Sendable, Hashable {
    /// The hour on a 24-hour clock, from 0 through 23.
    public let hour: Int
    /// The minute, from 0 through 59.
    public let minute: Int

    /// Returns nil unless the hour is 0 through 23 and the minute is 0 through 59; values are never clamped.
    ///
    /// - Parameters:
    ///   - hour: The hour on a 24-hour clock.
    ///   - minute: The minute.
    public init?(hour: Int, minute: Int = 0) {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        self.hour = hour
        self.minute = minute
    }

    /// Parses exactly `HH:mm` with ASCII digits on a 24-hour clock; `"9:05"` and `"24:00"` are nil.
    ///
    /// - Parameter description: The text to parse.
    public init?(_ description: String) {
        let bytes = Array(description.utf8)
        guard bytes.count == 5, bytes[2] == UInt8(ascii: ":") else { return nil }
        let digits = [bytes[0], bytes[1], bytes[3], bytes[4]]
        guard digits.allSatisfy({ (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) }) else { return nil }
        let value = digits.map { Int($0 - UInt8(ascii: "0")) }
        self.init(hour: value[0] * 10 + value[1], minute: value[2] * 10 + value[3])
    }

    /// The time a wall clock in the given time zone shows at the given instant, dropping the seconds.
    ///
    /// - Parameters:
    ///   - instant: The moment to read.
    ///   - timeZone: Whose wall clock to read it on.
    public init(_ instant: Date, in timeZone: TimeZone) {
        let secondOfDay = Civil.wallClock(of: instant, in: timeZone).secondOfDay
        self.hour = secondOfDay / 3600
        self.minute = secondOfDay % 3600 / 60
    }

    /// Minutes since midnight, from 0 through 1439.
    public var minuteOfDay: Int {
        hour * 60 + minute
    }
}

extension LocalTime: Comparable {
    public static func < (lhs: LocalTime, rhs: LocalTime) -> Bool {
        lhs.minuteOfDay < rhs.minuteOfDay
    }
}

extension LocalTime: LosslessStringConvertible {
    /// The time as `HH:mm`, such as `09:05`.
    public var description: String {
        let hh = hour < 10 ? "0\(hour)" : "\(hour)"
        let mm = minute < 10 ? "0\(minute)" : "\(minute)"
        return "\(hh):\(mm)"
    }
}

extension LocalTime: Codable {
    /// Decodes a single `HH:mm` string, and fails on anything else.
    ///
    /// - Parameter decoder: The decoder to read from.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let time = LocalTime(text) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a time in the form HH:mm, got \"\(text)\""
            )
        }
        self = time
    }

    /// Encodes the time as a single `HH:mm` string.
    ///
    /// - Parameter encoder: The encoder to write to.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
