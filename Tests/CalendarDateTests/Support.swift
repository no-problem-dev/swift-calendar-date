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

    static let all = [tokyo, newYork, santiago, utc, kolkata, lordHowe, chatham]
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
