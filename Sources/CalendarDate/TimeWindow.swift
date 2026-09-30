import Foundation

/// A stretch of time between two instants, both included, such as "arrive between 15:00 and 15:30".
///
/// The start is never after the end. A window whose start and end are the same instant is a fixed time
/// with no room to move. The `Codable` form is `{"start": …, "end": …}`, with each instant written by
/// the encoder's date strategy, and decoding rejects a reversed pair.
///
/// Unlike Foundation's `DateInterval`, creating a reversed window returns nil instead of trapping, so
/// input from outside can be checked without a crash.
public struct TimeWindow: Sendable, Hashable {
    /// The earliest instant in the window, included.
    public let start: Date
    /// The latest instant in the window, included; never before the start.
    public let end: Date

    /// Returns nil when the end is before the start.
    ///
    /// - Parameters:
    ///   - start: The earliest instant, included.
    ///   - end: The latest instant, included.
    public init?(start: Date, end: Date) {
        guard start <= end else { return nil }
        self.start = start
        self.end = end
    }

    /// A window of zero length at the given instant: a time that cannot move.
    ///
    /// - Parameter instant: The one instant in the window.
    public static func instant(_ instant: Date) -> TimeWindow {
        TimeWindow(start: instant, end: instant)!
    }

    /// The length of the window in seconds; 0 for a fixed time.
    public var duration: TimeInterval {
        end.timeIntervalSince(start)
    }

    /// Whether the window is a single instant with no room to move.
    public var isInstant: Bool {
        start == end
    }

    /// Whether the instant falls on or between the start and the end.
    ///
    /// - Parameter instant: The instant to test.
    public func contains(_ instant: Date) -> Bool {
        start <= instant && instant <= end
    }

    /// Whether each window starts before the other ends, so that back-to-back windows do not overlap.
    ///
    /// Windows where one ends at the instant the next starts do not overlap, which lets a day be cut into
    /// consecutive windows. A zero-length window strictly inside another one overlaps it; one sitting on
    /// an edge, or two zero-length windows at the same instant, do not. Use ``intersection(_:)`` when
    /// sharing a single instant should count.
    ///
    /// - Parameter other: The window to compare with.
    public func overlaps(_ other: TimeWindow) -> Bool {
        start < other.end && other.start < end
    }

    /// The instants both windows contain, or nil if they have none in common.
    ///
    /// Windows that only touch share the one instant where they meet, as a zero-length window.
    ///
    /// - Parameter other: The window to intersect with.
    public func intersection(_ other: TimeWindow) -> TimeWindow? {
        TimeWindow(start: max(start, other.start), end: min(end, other.end))
    }
}

extension TimeWindow: Codable {
    private enum CodingKeys: String, CodingKey {
        case start
        case end
    }

    /// Decodes `{"start": …, "end": …}` and fails when the end is before the start.
    ///
    /// - Parameter decoder: The decoder to read from.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let start = try container.decode(Date.self, forKey: .start)
        let end = try container.decode(Date.self, forKey: .end)
        guard let window = TimeWindow(start: start, end: end) else {
            throw DecodingError.dataCorruptedError(
                forKey: .end,
                in: container,
                debugDescription: "The end \(end) is before the start \(start)"
            )
        }
        self = window
    }

    /// Encodes the window as `{"start": …, "end": …}`.
    ///
    /// - Parameter encoder: The encoder to write to.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(start, forKey: .start)
        try container.encode(end, forKey: .end)
    }
}
