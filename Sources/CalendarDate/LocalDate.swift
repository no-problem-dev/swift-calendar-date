import Foundation

/// A day on the calendar, with no time of day and no time zone, such as 2026-09-25.
///
/// Two people in different time zones mean the same `LocalDate` by "2026-09-25", even though the day
/// starts at different instants for each of them. Converting to and from an instant (`Date`) therefore
/// always takes the time zone as an argument; nothing here reads the device's time zone or clock.
///
/// The calendar is the proleptic Gregorian calendar, and years run from 1 through 9999 so that the text
/// form is always the fixed-width `YYYY-MM-DD`. That form is also the `Codable` and dictionary-key form.
/// A date that is not known yet is `LocalDate?` and `nil`, never an empty string.
///
/// Values that come from outside — text, JSON, an instant from a server or a cache — convert through
/// failable initializers and give `nil` when they are not a date. Only arithmetic the caller controls,
/// such as ``adding(days:)`` past year 9999, traps.
///
/// ```swift
/// let tokyo = TimeZone(identifier: "Asia/Tokyo")!
/// let today = LocalDate.today(now: now, in: tokyo)
/// let yesterday = today.adding(days: -1)
/// for day in yesterday...today { print(day) }   // 2026-09-24, 2026-09-25
/// ```
public struct LocalDate: Sendable, Hashable {
    /// The Gregorian year, from 1 through 9999.
    public let year: Int
    /// The month of the year, from 1 (January) through 12 (December).
    public let month: Int
    /// The day of the month, from 1 through the last day of that month.
    public let day: Int

    /// Returns nil for a date the calendar does not have, such as 2026-02-30 or year 0.
    ///
    /// - Parameters:
    ///   - year: The Gregorian year, from 1 through 9999.
    ///   - month: The month, from 1 through 12.
    ///   - day: The day of the month.
    public init?(year: Int, month: Int, day: Int) {
        guard Civil.isValid(year: year, month: month, day: day) else { return nil }
        self.year = year
        self.month = month
        self.day = day
    }

    /// Parses exactly `YYYY-MM-DD` with ASCII digits; anything else, including a time part, is nil.
    ///
    /// `"2026-9-25"`, `"2026-09-25T00:00:00Z"`, `" 2026-09-25"` and `"2026-02-30"` are all rejected, so a
    /// value that parses always prints back as the same string.
    ///
    /// - Parameter description: The text to parse.
    public init?(_ description: String) {
        let bytes = Array(description.utf8)
        guard bytes.count == 10, bytes[4] == UInt8(ascii: "-"), bytes[7] == UInt8(ascii: "-") else {
            return nil
        }
        func number(_ range: Range<Int>) -> Int? {
            var value = 0
            for byte in bytes[range] {
                guard (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte) else { return nil }
                value = value * 10 + Int(byte - UInt8(ascii: "0"))
            }
            return value
        }
        guard let year = number(0..<4), let month = number(5..<7), let day = number(8..<10) else {
            return nil
        }
        self.init(year: year, month: month, day: day)
    }

    /// The date a wall calendar in the given time zone shows at the given instant, or nil when there is none.
    ///
    /// The result is nil when the instant is not a finite number (NaN or infinity) or when its date falls
    /// outside years 1 through 9999, as `Date.distantPast` does. Use this for instants that come from
    /// outside; use ``today(now:in:)`` for the current time.
    ///
    /// - Parameters:
    ///   - instant: The moment to read.
    ///   - timeZone: Whose calendar to read it on. The same instant is a different date in Tokyo and New York.
    public init?(_ instant: Date, in timeZone: TimeZone) {
        guard let wall = Civil.wallClock(of: instant, in: timeZone) else { return nil }
        self.init(dayNumber: wall.dayNumber)
    }

    /// Today in the given time zone, where the caller supplies what "now" is.
    ///
    /// Unlike ``init(_:in:)`` this never returns nil: `now` comes from a real clock, and a clock that
    /// reports a year outside 1 through 9999 is a programmer error, which traps. Taking `now` as an
    /// argument keeps the answer testable and keeps the clock at the caller's composition root.
    ///
    /// - Parameters:
    ///   - now: The current instant, as the caller's clock reports it.
    ///   - timeZone: The time zone whose calendar decides where today begins.
    public static func today(now: Date, in timeZone: TimeZone) -> LocalDate {
        guard let today = LocalDate(now, in: timeZone) else {
            preconditionFailure("The clock reported \(now.timeIntervalSince1970) seconds since 1970, outside years 1 through 9999")
        }
        return today
    }

    /// The first instant of this day in the given time zone, which is midnight unless a clock change skips it.
    ///
    /// Where a daylight-saving change skips midnight (America/Santiago on 2026-09-06), the day begins at
    /// the transition, 01:00 local time.
    ///
    /// Where a time zone skips the whole date (Pacific/Apia jumped from 2011-12-29 to 2011-12-31), the
    /// result is the same instant as the next day's start, and that instant reads back as the next day.
    ///
    /// - Parameter timeZone: The time zone whose midnight to find.
    public func start(in timeZone: TimeZone) -> Date {
        timeZone.firstInstant(atOrAfterWall: dayNumber * Civil.secondsPerDay)
    }

    /// The instant a wall clock in the given time zone shows this date and time, or nil if the clock skips it.
    ///
    /// When a clock change makes the time happen twice (01:30 on the night New York falls back), the earlier
    /// of the two instants is returned. When it skips the time (02:30 on the night New York springs forward),
    /// the result is nil rather than a nearby time the caller did not ask for.
    ///
    /// - Parameters:
    ///   - time: The wall-clock time on this date.
    ///   - timeZone: The time zone the wall clock belongs to.
    public func instant(at time: LocalTime, in timeZone: TimeZone) -> Date? {
        timeZone.instants(atWall: dayNumber * Civil.secondsPerDay + time.minuteOfDay * 60).first
    }

    /// The date the given number of days later, or earlier when the number is negative.
    ///
    /// Stepping by days never touches a time zone, so it is unaffected by daylight-saving changes.
    /// Stepping outside years 1 through 9999 is a programmer error and traps: the caller controls both
    /// the date and the step.
    ///
    /// - Parameter days: How many days to move.
    public func adding(days: Int) -> LocalDate {
        LocalDate(dayNumber: dayNumber + days)
    }

    /// How many days from this date to the other, negative when the other date is earlier.
    ///
    /// - Parameter other: The date to count to.
    public func days(to other: LocalDate) -> Int {
        other.dayNumber - dayNumber
    }

    /// The day of the week, computed from the date alone.
    public var weekday: Weekday {
        let sinceThursday = ((dayNumber % 7) + 7) % 7
        return Weekday(rawValue: (sinceThursday + 4) % 7 + 1)!
    }

    /// How many days this date's month has: 28 through 31.
    public var daysInMonth: Int {
        Civil.daysInMonth(year: year, month: month)
    }

    /// Every day of this date's month, from the 1st through the last day.
    ///
    /// ```swift
    /// let february = LocalDate("2024-02-10")!.monthSpan
    /// february.first        // 2024-02-01
    /// february.last         // 2024-02-29
    /// february.first.weekday // .thursday, where a month grid starts
    /// ```
    public var monthSpan: DateSpan {
        DateSpan(LocalDate(year: year, month: month, day: 1)!...LocalDate(year: year, month: month, day: daysInMonth)!)
    }

    /// The first day of the week that contains this date, for weeks that begin on the given weekday.
    ///
    /// Pass the week start the app shows, such as `.monday`; the answer never depends on the device's
    /// locale. A week that would begin before 0001-01-01 traps, like ``adding(days:)``.
    ///
    /// - Parameter firstWeekday: The weekday each week begins on.
    public func startOfWeek(firstWeekday: Weekday) -> LocalDate {
        adding(days: -((weekday.rawValue - firstWeekday.rawValue + 7) % 7))
    }

    /// Days since 1970-01-01, which is day 0.
    var dayNumber: Int {
        Civil.dayNumber(year: year, month: month, day: day)
    }

    init(dayNumber: Int) {
        let civil = Civil.civil(dayNumber: dayNumber)
        precondition(
            Civil.years.contains(civil.year),
            "LocalDate supports years 1 through 9999; day \(dayNumber) is year \(civil.year)"
        )
        self.year = civil.year
        self.month = civil.month
        self.day = civil.day
    }
}

extension LocalDate: Comparable {
    public static func < (lhs: LocalDate, rhs: LocalDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

extension LocalDate: Strideable {
    public func distance(to other: LocalDate) -> Int {
        days(to: other)
    }

    public func advanced(by n: Int) -> LocalDate {
        adding(days: n)
    }
}

extension LocalDate: LosslessStringConvertible {
    /// The date as `YYYY-MM-DD`, such as `2026-09-25`.
    public var description: String {
        func pad(_ value: Int, _ width: Int) -> String {
            let digits = String(value)
            return String(repeating: "0", count: max(0, width - digits.count)) + digits
        }
        return "\(pad(year, 4))-\(pad(month, 2))-\(pad(day, 2))"
    }
}

extension LocalDate: Codable {
    /// Decodes a single `YYYY-MM-DD` string, and fails on anything else.
    ///
    /// - Parameter decoder: The decoder to read from.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let date = LocalDate(text) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a date in the form YYYY-MM-DD, got \"\(text)\""
            )
        }
        self = date
    }

    /// Encodes the date as a single `YYYY-MM-DD` string.
    ///
    /// - Parameter encoder: The encoder to write to.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension LocalDate: CodingKeyRepresentable {
    /// The date as a `YYYY-MM-DD` key, so a `[LocalDate: Value]` dictionary encodes as a keyed object.
    public var codingKey: any CodingKey {
        DateKey(stringValue: description)
    }

    /// Reads a `YYYY-MM-DD` key, and returns nil for any other key.
    ///
    /// - Parameter codingKey: The key to read.
    public init?<T: CodingKey>(codingKey: T) {
        self.init(codingKey.stringValue)
    }

    private struct DateKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }
}
