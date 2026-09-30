import Foundation
import Testing
import CalendarDate

/// The jobs the package was written for, through the public API only.
@Suite("Usage")
struct UsageTests {
    /// A reading streak is alive if the last reading day, in Tokyo, is today or yesterday in Tokyo,
    /// wherever the phone happens to be.
    private func streakIsActive(lastReadingDate: String, now: Date) -> Bool {
        guard let last = LocalDate(lastReadingDate) else { return false }
        let today = LocalDate.today(now: now, in: Zone.tokyo)
        return last >= today.adding(days: -1) && last <= today
    }

    @Test("A streak survives Tokyo midnight and ends the day after")
    func readingStreak() {
        // 00:30 on 2026-09-25 in Tokyo, which is still 11:30 on 2026-09-24 in New York.
        let justAfterMidnight = instant("2026-09-24T15:30:00Z")
        #expect(streakIsActive(lastReadingDate: "2026-09-24", now: justAfterMidnight))
        #expect(streakIsActive(lastReadingDate: "2026-09-25", now: justAfterMidnight))
        #expect(!streakIsActive(lastReadingDate: "2026-09-23", now: justAfterMidnight))
        #expect(!streakIsActive(lastReadingDate: "", now: justAfterMidnight))
    }

    /// A receipt date is accepted from a year back through one day ahead of today.
    private func acceptsReceiptDate(_ printed: LocalDate, now: Date, in timeZone: TimeZone) -> Bool {
        let today = LocalDate.today(now: now, in: timeZone)
        return (-365...1).contains(today.days(to: printed))
    }

    @Test("A receipt may be dated up to one day ahead, counted in calendar days")
    func receiptDate() {
        let now = instant("2026-07-28T15:00:00Z")   // 2026-07-29 00:00 in Tokyo
        #expect(acceptsReceiptDate(date("2026-07-30"), now: now, in: Zone.tokyo))
        #expect(!acceptsReceiptDate(date("2026-07-31"), now: now, in: Zone.tokyo))
        #expect(acceptsReceiptDate(date("2025-07-29"), now: now, in: Zone.tokyo))
        #expect(!acceptsReceiptDate(date("2025-07-28"), now: now, in: Zone.tokyo))
        #expect(date("2026-07-26").start(in: Zone.tokyo) == instant("2026-07-25T15:00:00Z"))
    }

    @Test("Per-day counters keyed by date round-trip through JSON in date order")
    func perDayCounters() throws {
        let tokyo = Zone.tokyo
        let opens = [
            instant("2026-09-26T14:59:00Z"),   // 23:59 on 09-26
            instant("2026-09-26T15:01:00Z"),   // 00:01 on 09-27
            instant("2026-09-27T01:00:00Z"),   // 10:00 on 09-27
        ]
        let counts = Dictionary(grouping: opens.compactMap { LocalDate($0, in: tokyo) }) { $0 }.mapValues(\.count)
        #expect(counts == [date("2026-09-26"): 1, date("2026-09-27"): 2])

        let decoded = try JSONDecoder().decode([LocalDate: Int].self, from: JSONEncoder().encode(counts))
        #expect(decoded.keys.sorted() == [date("2026-09-26"), date("2026-09-27")])
    }

    @Test("A trip's days, and an appointment's arrival window on one of them")
    func tripPlanning() {
        let trip = DateSpan(first: date("2026-09-23"), last: date("2026-09-26"))!
        let day = date("2026-09-25")
        #expect(trip.contains(day))
        #expect(day.weekday == .friday)

        let around = day.instant(at: time("15:30"), in: Zone.tokyo)!
        let window = TimeWindow(start: around.addingTimeInterval(-30 * 60), end: around.addingTimeInterval(30 * 60))!
        #expect(window.duration == 3600)
        #expect(LocalTime(window.start, in: Zone.tokyo) == time("15:00"))
        #expect(LocalDate(window.end, in: Zone.tokyo) == day)
    }
}
