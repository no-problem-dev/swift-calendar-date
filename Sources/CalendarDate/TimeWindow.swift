import Foundation

/// A stretch of time from a start instant up to, but not including, an end instant — or a single instant.
///
/// The start is never after the end. Which instants a window holds follows one rule, and every method
/// uses it:
///
/// - A window with room, `start < end`, is half-open: it holds `start` and every instant before `end`,
///   but not `end` itself. Consecutive windows where one ends at the instant the next starts therefore
///   cover time with no gap and no overlap, and the boundary instant belongs to exactly one of them,
///   the later one.
/// - A zero-length window, `start == end`, is a fixed time. It holds that one instant.
///
/// | Method | Question | 15:00–16:00 and 16:00–17:00 | Two fixed times at 15:00 | Fixed 15:00 and 15:00–16:00 | Fixed 16:00 and 15:00–16:00 |
/// |---|---|---|---|---|---|
/// | ``contains(_:)`` | Does the window hold this instant? | 16:00 is in the second only | 15:00 is in both | 15:00 is in both | 16:00 is in the fixed one only |
/// | ``overlaps(_:)`` | Do the windows hold an instant in common? | no | yes | yes | no |
/// | ``intersection(_:)`` | Which instants do they hold in common? | nil | fixed 15:00 | fixed 15:00 | nil |
///
/// So two fixed appointments at the same time overlap, and a fixed appointment at the start of a range
/// overlaps it, while back-to-back ranges do not.
///
/// The `Codable` form is `{"start": …, "end": …}`, with each instant written by the encoder's date
/// strategy, and decoding rejects a reversed pair. Unlike Foundation's `DateInterval`, creating a
/// reversed window returns nil instead of trapping, so input from outside can be checked without a crash.
public struct TimeWindow: Sendable, Hashable {
    /// The earliest instant in the window, included.
    public let start: Date
    /// Where the window ends; never before the start. Excluded unless the window is a single instant.
    public let end: Date

    /// Returns nil when the end is before the start.
    ///
    /// - Parameters:
    ///   - start: The earliest instant, included.
    ///   - end: The instant the window stops at, excluded unless it equals the start.
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

    /// Whether the window holds the instant: from the start up to but not including the end, or the one
    /// instant of a zero-length window.
    ///
    /// - Parameter instant: The instant to test.
    public func contains(_ instant: Date) -> Bool {
        isInstant ? instant == start : start <= instant && instant < end
    }

    /// Whether the two windows hold at least one instant in common, as ``contains(_:)`` decides.
    ///
    /// Back-to-back windows do not overlap. Two fixed times at the same instant do, and so does a fixed
    /// time with any window that contains it. Always equal to `intersection(other) != nil`.
    ///
    /// - Parameter other: The window to compare with.
    public func overlaps(_ other: TimeWindow) -> Bool {
        intersection(other) != nil
    }

    /// The instants both windows hold, or nil if they hold none in common.
    ///
    /// - Parameter other: The window to intersect with.
    public func intersection(_ other: TimeWindow) -> TimeWindow? {
        switch (isInstant, other.isInstant) {
        case (true, _):
            other.contains(start) ? self : nil
        case (false, true):
            contains(other.start) ? other : nil
        case (false, false):
            max(start, other.start) < min(end, other.end)
                ? TimeWindow(start: max(start, other.start), end: min(end, other.end))
                : nil
        }
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
