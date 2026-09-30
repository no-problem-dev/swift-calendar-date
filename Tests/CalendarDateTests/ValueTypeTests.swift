import Foundation
import Testing
@testable import CalendarDate

@Suite("LocalTime")
struct LocalTimeTests {
    @Test("Text in the exact HH:mm form parses and prints back unchanged", arguments: ["00:00", "09:05", "15:30", "23:59"])
    func roundTripsText(_ text: String) {
        #expect(LocalTime(text)?.description == text)
    }

    @Test("Any other text is refused", arguments: [
        "", "9:05", "09:5", "24:00", "12:60", "12-30", "1230", "12:30:00", " 12:30", "１２:３０", "-1:00",
    ])
    func refusesOtherText(_ text: String) {
        #expect(LocalTime(text) == nil)
    }

    @Test("Out-of-range parts are refused, not clamped")
    func refusesOutOfRange() {
        #expect(LocalTime(hour: 24) == nil)
        #expect(LocalTime(hour: -1) == nil)
        #expect(LocalTime(hour: 12, minute: 60) == nil)
        #expect(LocalTime(hour: 7)?.minuteOfDay == 420)
    }

    @Test("Order follows the clock")
    func ordersByClock() {
        #expect(time("09:59") < time("10:00"))
        #expect(time("00:00").minuteOfDay == 0)
        #expect(time("23:59").minuteOfDay == 1439)
    }

    @Test("Codable uses HH:mm and refuses anything else")
    func codable() throws {
        let data = try JSONEncoder().encode([time("09:05")])
        #expect(String(decoding: data, as: UTF8.self) == #"["09:05"]"#)
        #expect(try JSONDecoder().decode([LocalTime].self, from: data) == [time("09:05")])
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([LocalTime].self, from: Data(#"["9:05"]"#.utf8))
        }
    }
}

@Suite("DateSpan")
struct DateSpanTests {
    private let trip = DateSpan(first: date("2026-09-23"), last: date("2026-09-26"))!

    @Test("A reversed pair is nil; the same day twice is a day trip")
    func ordering() {
        #expect(DateSpan(first: date("2026-09-26"), last: date("2026-09-23")) == nil)
        let dayTrip = DateSpan(first: date("2026-09-25"), last: date("2026-09-25"))
        #expect(dayTrip?.nights == 0)
        #expect(dayTrip?.days.count == 1)
    }

    @Test("Nights and days")
    func nightsAndDays() {
        #expect(trip.nights == 3)
        #expect(trip.days.count == 4)
        #expect(trip.days.map(\.description) == ["2026-09-23", "2026-09-24", "2026-09-25", "2026-09-26"])
    }

    @Test("Nights across a leap day and a year end")
    func nightsAcrossBoundaries() {
        #expect(DateSpan(first: date("2024-02-28"), last: date("2024-03-01"))?.nights == 2)
        #expect(DateSpan(first: date("2026-02-28"), last: date("2026-03-01"))?.nights == 1)
        #expect(DateSpan(first: date("2026-12-30"), last: date("2027-01-02"))?.nights == 3)
    }

    @Test("Contains includes both ends")
    func contains() {
        #expect(trip.contains(date("2026-09-23")))
        #expect(trip.contains(date("2026-09-25")))
        #expect(trip.contains(date("2026-09-26")))
        #expect(!trip.contains(date("2026-09-22")))
        #expect(!trip.contains(date("2026-09-27")))
    }

    @Test("Spans overlap when they share a day")
    func overlaps() {
        #expect(trip.overlaps(DateSpan(first: date("2026-09-26"), last: date("2026-09-28"))!))
        #expect(!trip.overlaps(DateSpan(first: date("2026-09-27"), last: date("2026-09-28"))!))
        #expect(trip.overlaps(DateSpan(first: date("2026-09-24"), last: date("2026-09-24"))!))
    }

    @Test("A closed range makes the same span")
    func fromRange() {
        #expect(DateSpan(date("2026-09-23")...date("2026-09-26")) == trip)
    }

    @Test("Codable uses first and last, and refuses a reversed pair")
    func codable() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(trip)
        #expect(String(decoding: data, as: UTF8.self) == #"{"first":"2026-09-23","last":"2026-09-26"}"#)
        #expect(try JSONDecoder().decode(DateSpan.self, from: data) == trip)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(DateSpan.self, from: Data(#"{"first":"2026-09-26","last":"2026-09-23"}"#.utf8))
        }
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(DateSpan.self, from: Data(#"{"first":"2026-09-23"}"#.utf8))
        }
    }
}

@Suite("TimeWindow")
struct TimeWindowTests {
    private let t1500 = instant("2026-09-25T06:00:00Z")
    private let t1530 = instant("2026-09-25T06:30:00Z")
    private let t1600 = instant("2026-09-25T07:00:00Z")

    @Test("A reversed pair is nil; equal ends make a fixed time")
    func ordering() {
        #expect(TimeWindow(start: t1530, end: t1500) == nil)
        let fixed = TimeWindow(start: t1530, end: t1530)
        #expect(fixed == .instant(t1530))
        #expect(fixed?.isInstant == true)
        #expect(fixed?.duration == 0)
    }

    @Test("Duration is the length in seconds")
    func duration() {
        #expect(TimeWindow(start: t1500, end: t1600)?.duration == 3600)
        #expect(TimeWindow(start: t1500, end: t1600)?.isInstant == false)
    }

    @Test("Contains includes both ends")
    func contains() {
        let window = TimeWindow(start: t1500, end: t1530)!
        #expect(window.contains(t1500))
        #expect(window.contains(t1530))
        #expect(!window.contains(t1500.addingTimeInterval(-1)))
        #expect(!window.contains(t1530.addingTimeInterval(1)))
        #expect(TimeWindow.instant(t1500).contains(t1500))
    }

    @Test("Back-to-back windows do not overlap; nested and crossing ones do")
    func overlaps() {
        let first = TimeWindow(start: t1500, end: t1530)!
        let second = TimeWindow(start: t1530, end: t1600)!
        let whole = TimeWindow(start: t1500, end: t1600)!
        #expect(!first.overlaps(second))
        #expect(!second.overlaps(first))
        #expect(first.overlaps(whole))
        #expect(whole.overlaps(second))
        #expect(whole.overlaps(.instant(t1530)))
        #expect(!first.overlaps(.instant(t1530)))
        #expect(!TimeWindow.instant(t1530).overlaps(.instant(t1530)))
    }

    @Test("Intersection keeps the shared instants, including a single touching one")
    func intersection() {
        let first = TimeWindow(start: t1500, end: t1530)!
        let second = TimeWindow(start: t1530, end: t1600)!
        let whole = TimeWindow(start: t1500, end: t1600)!
        #expect(first.intersection(second) == .instant(t1530))
        #expect(whole.intersection(first) == first)
        #expect(TimeWindow.instant(t1500).intersection(second) == nil)
    }

    @Test("Codable uses start and end, and refuses a reversed pair")
    func codable() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let window = TimeWindow(start: t1500, end: t1530)!
        let data = try encoder.encode(window)
        #expect(String(decoding: data, as: UTF8.self) == #"{"end":"2026-09-25T06:30:00Z","start":"2026-09-25T06:00:00Z"}"#)
        #expect(try decoder.decode(TimeWindow.self, from: data) == window)
        #expect(throws: DecodingError.self) {
            try decoder.decode(TimeWindow.self, from: Data(#"{"start":"2026-09-25T06:30:00Z","end":"2026-09-25T06:00:00Z"}"#.utf8))
        }
    }
}

@Suite("Calendar.gregorian(timeZone:)")
struct GregorianCalendarTests {
    @Test("Is Gregorian and uses exactly the time zone passed in", arguments: Zone.all)
    func pinsTimeZone(_ timeZone: TimeZone) {
        let calendar = Calendar.gregorian(timeZone: timeZone)
        #expect(calendar.identifier == .gregorian)
        #expect(calendar.timeZone == timeZone)
    }

    @Test("Agrees with LocalDate on where 2026-09-25 begins in Tokyo")
    func agreesWithLocalDate() {
        let calendar = Calendar.gregorian(timeZone: Zone.tokyo)
        let start = calendar.date(from: DateComponents(year: 2026, month: 9, day: 25))
        #expect(start == date("2026-09-25").start(in: Zone.tokyo))
    }
}
