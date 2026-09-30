/// A run of whole days from a first day through a last day, both included, such as a trip or a booking.
///
/// The first day is never after the last, so a value that exists is always a real span; a one-day span
/// has the same first and last day and zero nights. The `Codable` form is
/// `{"first": "YYYY-MM-DD", "last": "YYYY-MM-DD"}`, and decoding rejects a reversed pair.
///
/// ```swift
/// let trip = DateSpan(first: LocalDate("2026-09-23")!, last: LocalDate("2026-09-26")!)!
/// trip.nights                                   // 3
/// trip.days.count                               // 4
/// trip.contains(LocalDate("2026-09-25")!)       // true
/// ```
public struct DateSpan: Sendable, Hashable {
    /// The first day, included.
    public let first: LocalDate
    /// The last day, included; never before the first.
    public let last: LocalDate

    /// Returns nil when the last day is before the first.
    ///
    /// - Parameters:
    ///   - first: The first day, included.
    ///   - last: The last day, included.
    public init?(first: LocalDate, last: LocalDate) {
        guard first <= last else { return nil }
        self.first = first
        self.last = last
    }

    /// Creates the span a closed range already guarantees to be in order.
    ///
    /// - Parameter days: The days, first through last.
    public init(_ days: ClosedRange<LocalDate>) {
        self.first = days.lowerBound
        self.last = days.upperBound
    }

    /// Nights between the first and last day: 0 for a day trip, 3 for Wednesday through Saturday.
    ///
    /// The same value as `first.days(to: last)`, one less than `days.count`.
    public var nights: Int {
        first.days(to: last)
    }

    /// Every day in the span, in order, as a collection that can be iterated and counted.
    public var days: ClosedRange<LocalDate> {
        first...last
    }

    /// Whether the date falls on or between the first and last day.
    ///
    /// - Parameter date: The date to test.
    public func contains(_ date: LocalDate) -> Bool {
        first <= date && date <= last
    }

    /// Whether the two spans share at least one day.
    ///
    /// - Parameter other: The span to compare with.
    public func overlaps(_ other: DateSpan) -> Bool {
        first <= other.last && other.first <= last
    }
}

extension DateSpan: Codable {
    private enum CodingKeys: String, CodingKey {
        case first
        case last
    }

    /// Decodes `{"first": …, "last": …}` and fails when the last day is before the first.
    ///
    /// - Parameter decoder: The decoder to read from.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let first = try container.decode(LocalDate.self, forKey: .first)
        let last = try container.decode(LocalDate.self, forKey: .last)
        guard let span = DateSpan(first: first, last: last) else {
            throw DecodingError.dataCorruptedError(
                forKey: .last,
                in: container,
                debugDescription: "The last day \(last) is before the first day \(first)"
            )
        }
        self = span
    }

    /// Encodes the span as `{"first": …, "last": …}`.
    ///
    /// - Parameter encoder: The encoder to write to.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(first, forKey: .first)
        try container.encode(last, forKey: .last)
    }
}
