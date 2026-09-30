/// A day of the week, numbered as Foundation's `Calendar` numbers the `weekday` component (Sunday is 1).
///
/// The raw values match `Calendar.component(.weekday, from:)` for a Gregorian calendar, so existing code
/// that stores that number can convert with `Weekday(rawValue:)`.
public enum Weekday: Int, Sendable, Hashable, CaseIterable, Codable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}
