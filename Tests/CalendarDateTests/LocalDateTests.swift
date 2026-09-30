import Foundation
import Testing
@testable import CalendarDate

@Suite("LocalDate: making and reading dates")
struct LocalDateMakingTests {
    @Test("A real date is kept as given")
    func keepsComponents() {
        let day = LocalDate(year: 2026, month: 9, day: 25)
        #expect(day?.year == 2026)
        #expect(day?.month == 9)
        #expect(day?.day == 25)
    }

    @Test("Dates the calendar does not have are nil", arguments: [
        (2026, 2, 29), (2026, 2, 30), (2026, 4, 31), (2026, 13, 1), (2026, 0, 1),
        (2026, 1, 0), (2026, 1, 32), (0, 1, 1), (10000, 1, 1), (-1, 6, 1), (1900, 2, 29), (2100, 2, 29),
    ])
    func rejectsImpossibleDates(_ parts: (Int, Int, Int)) {
        #expect(LocalDate(year: parts.0, month: parts.1, day: parts.2) == nil)
    }

    @Test("February 29 exists only in leap years", arguments: [2000, 2024, 2028, 2400])
    func acceptsLeapDays(_ year: Int) {
        #expect(LocalDate(year: year, month: 2, day: 29) != nil)
    }

    @Test("Text in the exact YYYY-MM-DD form parses and prints back unchanged", arguments: [
        "2026-09-25", "0001-01-01", "9999-12-31", "2024-02-29", "1970-01-01",
    ])
    func roundTripsText(_ text: String) {
        #expect(LocalDate(text)?.description == text)
    }

    @Test("Any other text is refused", arguments: [
        "", "2026-9-25", "2026-09-5", "26-09-25", "2026/09/25", "2026.09.25", "20260925",
        "2026-09-25T00:00:00Z", "2026-09-25 ", " 2026-09-25", "+2026-09-25", "2026-09-2a",
        "２０２６-０９-２５", "2026-02-30", "2026-13-01", "0000-01-01", "2026-09-25\n", "2026-0-925",
    ])
    func refusesOtherText(_ text: String) {
        #expect(LocalDate(text) == nil)
    }

    @Test("Small years are padded to four digits")
    func padsYears() {
        #expect(LocalDate(year: 33, month: 3, day: 3)?.description == "0033-03-03")
    }
}

@Suite("LocalDate: arithmetic on days")
struct LocalDateArithmeticTests {
    @Test("Adding days crosses month, year and leap-day boundaries", arguments: [
        ("2026-09-25", 1, "2026-09-26"),
        ("2026-09-30", 1, "2026-10-01"),
        ("2026-12-31", 1, "2027-01-01"),
        ("2027-01-01", -1, "2026-12-31"),
        ("2024-02-28", 1, "2024-02-29"),
        ("2024-02-29", 1, "2024-03-01"),
        ("2026-02-28", 1, "2026-03-01"),
        ("2026-09-25", -365, "2025-09-25"),
        ("2024-03-01", -366, "2023-03-01"),
        ("2026-09-25", 0, "2026-09-25"),
        ("1969-12-31", 1, "1970-01-01"),
        ("0001-01-01", 3_652_058, "9999-12-31"),
    ])
    func addsDays(_ case: (String, Int, String)) {
        #expect(date(`case`.0).adding(days: `case`.1) == date(`case`.2))
    }

    @Test("Counting days is the inverse of adding them")
    func countsDays() {
        #expect(date("2026-09-25").days(to: date("2026-09-26")) == 1)
        #expect(date("2026-09-26").days(to: date("2026-09-25")) == -1)
        #expect(date("2024-01-01").days(to: date("2025-01-01")) == 366)
        #expect(date("2026-01-01").days(to: date("2027-01-01")) == 365)
        #expect(date("1900-01-01").days(to: date("2100-01-01")) == 73_049)
    }

    @Test("Order follows the calendar, not the text")
    func ordersByCalendar() {
        #expect(date("2026-09-25") < date("2026-09-26"))
        #expect(date("2026-09-30") < date("2026-10-01"))
        #expect(date("2025-12-31") < date("2026-01-01"))
        #expect(!(date("2026-09-25") < date("2026-09-25")))
    }

    @Test("A closed range of dates is a countable run of days")
    func rangesAreCollections() {
        let days = Array(date("2024-02-27")...date("2024-03-01"))
        #expect(days.map(\.description) == ["2024-02-27", "2024-02-28", "2024-02-29", "2024-03-01"])
        #expect((date("2026-09-25")...date("2026-09-25")).count == 1)
        #expect(Array(stride(from: date("2026-09-01"), to: date("2026-09-22"), by: 7)).map(\.day) == [1, 8, 15])
    }

    @Test("Weekdays follow the calendar", arguments: [
        ("1970-01-01", Weekday.thursday),
        ("2026-09-25", Weekday.friday),
        ("2026-09-27", Weekday.sunday),
        ("2024-02-29", Weekday.thursday),
        ("2000-01-01", Weekday.saturday),
        ("1969-12-31", Weekday.wednesday),
        ("0001-01-01", Weekday.monday),
    ])
    func knowsWeekdays(_ case: (String, Weekday)) {
        #expect(date(`case`.0).weekday == `case`.1)
    }

    @Test("Weekdays and dates agree with Foundation's Gregorian calendar over 1601 through 2400")
    func agreesWithFoundation() {
        let calendar = Calendar.gregorian(timeZone: Zone.utc)
        var day = date("1601-01-01")
        let end = date("2400-12-31")
        while day <= end {
            let midnight = day.start(in: Zone.utc)
            let parts = calendar.dateComponents([.year, .month, .day, .weekday], from: midnight)
            #expect(parts.year == day.year)
            #expect(parts.month == day.month)
            #expect(parts.day == day.day)
            #expect(parts.weekday == day.weekday.rawValue)
            day = day.adding(days: 37)
        }
    }
}

@Suite("LocalDate: months and weeks")
struct LocalDateMonthAndWeekTests {
    @Test("Days in the month", arguments: [
        ("2024-02-10", 29), ("2026-02-10", 28), ("1900-02-01", 28), ("2000-02-29", 29),
        ("2026-04-30", 30), ("2026-12-31", 31), ("2026-01-01", 31),
    ])
    func daysInMonth(_ case: (String, Int)) {
        #expect(date(`case`.0).daysInMonth == `case`.1)
    }

    @Test("The month span runs from the 1st through the last day")
    func monthSpan() {
        let february = date("2024-02-10").monthSpan
        #expect(february.first == date("2024-02-01"))
        #expect(february.last == date("2024-02-29"))
        #expect(february.days.count == 29)
        #expect(date("9999-12-31").monthSpan.last == date("9999-12-31"))
        #expect(date("0001-01-15").monthSpan.first == date("0001-01-01"))
    }

    @Test("The start of the week follows the weekday passed in")
    func startOfWeek() {
        // 2026-09-25 is a Friday.
        #expect(date("2026-09-25").startOfWeek(firstWeekday: .monday) == date("2026-09-21"))
        #expect(date("2026-09-25").startOfWeek(firstWeekday: .sunday) == date("2026-09-20"))
        #expect(date("2026-09-25").startOfWeek(firstWeekday: .friday) == date("2026-09-25"))
        #expect(date("2026-09-25").startOfWeek(firstWeekday: .saturday) == date("2026-09-19"))
        #expect(date("2026-09-21").startOfWeek(firstWeekday: .monday) == date("2026-09-21"))
    }

    @Test("The start of the week agrees with Foundation's week for every first weekday", arguments: Weekday.allCases)
    func startOfWeekAgreesWithFoundation(_ firstWeekday: Weekday) throws {
        var calendar = Calendar.gregorian(timeZone: Zone.utc)
        calendar.firstWeekday = firstWeekday.rawValue
        for day in date("2025-12-01")...date("2026-03-31") {
            let week = try #require(calendar.dateInterval(of: .weekOfYear, for: day.start(in: Zone.utc)))
            #expect(day.startOfWeek(firstWeekday: firstWeekday).start(in: Zone.utc) == week.start, "\(day)")
        }
    }
}

@Suite("LocalDate and Foundation before 1582")
struct JulianCalendarTests {
    @Test("Foundation's Gregorian calendar counts dates before 1582-10-15 in the Julian calendar")
    func foundationSwitchesToJulian() {
        let calendar = Calendar.gregorian(timeZone: Zone.utc)
        let old = calendar.dateComponents([.year, .month, .day], from: date("1500-01-01").start(in: Zone.utc))
        #expect(old.year == 1499 && old.month == 12 && old.day == 23)
        let reform = calendar.dateComponents([.year, .month, .day], from: date("1582-10-15").start(in: Zone.utc))
        #expect(reform.year == 1582 && reform.month == 10 && reform.day == 15)
    }
}

@Suite("Weekday: Codable")
struct WeekdayCodableTests {
    @Test("Encodes as the lowercase English name")
    func encodesName() throws {
        let data = try JSONEncoder().encode([Weekday.sunday, .monday, .saturday])
        #expect(String(decoding: data, as: UTF8.self) == #"["sunday","monday","saturday"]"#)
        let back = try JSONDecoder().decode([Weekday].self, from: JSONEncoder().encode(Weekday.allCases))
        #expect(back == Weekday.allCases)
    }

    @Test("Refuses numbers and other spellings", arguments: [#"[2]"#, #"["Monday"]"#, #"["mon"]"#, #"[""]"#])
    func refusesOthers(_ json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([Weekday].self, from: Data(json.utf8))
        }
    }

    @Test("The raw value still matches Foundation's weekday number")
    func rawValueIsFoundationNumber() {
        #expect(Weekday.sunday.rawValue == 1)
        #expect(Weekday.saturday.rawValue == 7)
        #expect(Weekday(name: "friday") == .friday)
    }
}

@Suite("LocalDate: Codable")
struct LocalDateCodableTests {
    @Test("Encodes as a bare YYYY-MM-DD string")
    func encodesAsString() throws {
        let data = try JSONEncoder().encode([date("2026-09-25")])
        #expect(String(decoding: data, as: UTF8.self) == #"["2026-09-25"]"#)
    }

    @Test("Decodes the same string back")
    func decodesString() throws {
        let decoded = try JSONDecoder().decode([LocalDate].self, from: Data(#"["2026-09-25"]"#.utf8))
        #expect(decoded == [date("2026-09-25")])
    }

    @Test("Refuses anything but YYYY-MM-DD when decoding", arguments: [
        #"["2026-9-25"]"#, #"["2026-09-25T00:00:00Z"]"#, #"["2026-02-30"]"#, #"[""]"#, #"[20260925]"#,
    ])
    func refusesOtherText(_ json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([LocalDate].self, from: Data(json.utf8))
        }
    }

    @Test("A dictionary keyed by date encodes as an object keyed by YYYY-MM-DD")
    func dictionaryKeys() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode([date("2026-09-25"): 2, date("2026-09-24"): 1])
        #expect(String(decoding: data, as: UTF8.self) == #"{"2026-09-24":1,"2026-09-25":2}"#)

        let decoded = try JSONDecoder().decode([LocalDate: Int].self, from: data)
        #expect(decoded == [date("2026-09-25"): 2, date("2026-09-24"): 1])
    }

    @Test("A dictionary with a key that is not a date fails to decode")
    func dictionaryRefusesBadKeys() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([LocalDate: Int].self, from: Data(#"{"yesterday":1}"#.utf8))
        }
    }
}
