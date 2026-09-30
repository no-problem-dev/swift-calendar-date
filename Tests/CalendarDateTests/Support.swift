import Foundation
@testable import CalendarDate

enum Zone {
    static let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    static let newYork = TimeZone(identifier: "America/New_York")!
    static let santiago = TimeZone(identifier: "America/Santiago")!
    static let utc = TimeZone(identifier: "UTC")!
    static let kolkata = TimeZone(identifier: "Asia/Kolkata")!
    static let lordHowe = TimeZone(identifier: "Australia/Lord_Howe")!
    static let chatham = TimeZone(identifier: "Pacific/Chatham")!
    /// Skipped the whole of 2011-12-30 when it moved across the date line.
    static let apia = TimeZone(identifier: "Pacific/Apia")!
    /// Changes its clocks at midnight.
    static let havana = TimeZone(identifier: "America/Havana")!
    /// Changes its clocks at midnight, on dates that moved from year to year.
    static let beirut = TimeZone(identifier: "Asia/Beirut")!

    static let all = [tokyo, newYork, santiago, utc, kolkata, lordHowe, chatham, apia, havana, beirut]

    /// Time zones that change their clocks, for checks that walk every transition.
    static let changing = [newYork, santiago, lordHowe, chatham, apia, havana, beirut]
}

/// An instant written in UTC, such as `"2026-09-24T15:00:00Z"`.
func instant(_ iso: String) -> Date {
    try! Date.ISO8601FormatStyle().parse(iso)
}

func date(_ text: String) -> LocalDate {
    LocalDate(text)!
}

func time(_ text: String) -> LocalTime {
    LocalTime(text)!
}
