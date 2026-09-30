import Foundation

extension Calendar {
    /// A Gregorian calendar pinned to the given time zone, for date math the types here do not cover.
    ///
    /// The locale is left as Foundation sets it for a new calendar, so week rules and formatting do not
    /// follow the device; set `locale` yourself if an app needs one. The time zone is always the one passed
    /// in, never the device's.
    ///
    /// Foundation's Gregorian calendar counts dates before 1582-10-15 in the Julian calendar, while
    /// ``LocalDate`` is proleptic Gregorian throughout, so the two disagree on those older dates.
    ///
    /// - Parameter timeZone: The time zone every conversion in this calendar uses.
    public static func gregorian(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
