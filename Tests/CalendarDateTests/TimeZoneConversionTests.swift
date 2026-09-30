import Foundation
import Testing
@testable import CalendarDate

@Suite("Converting in Asia/Tokyo")
struct TokyoTests {
    @Test("2026-09-25 in Tokyo starts at 15:00 UTC the day before")
    func startOfDay() {
        #expect(date("2026-09-25").start(in: Zone.tokyo) == instant("2026-09-24T15:00:00Z"))
    }

    @Test("The same instant is a different date in Tokyo and New York")
    func sameInstantDifferentDates() {
        let noonInTokyo = instant("2026-09-25T03:00:00Z")
        #expect(LocalDate(noonInTokyo, in: Zone.tokyo) == date("2026-09-25"))
        #expect(LocalDate(noonInTokyo, in: Zone.newYork) == date("2026-09-24"))
        #expect(LocalTime(noonInTokyo, in: Zone.tokyo) == time("12:00"))
        #expect(LocalTime(noonInTokyo, in: Zone.newYork) == time("23:00"))
    }

    @Test("Today flips at Tokyo midnight, not at UTC midnight")
    func todayFlipsAtLocalMidnight() {
        #expect(LocalDate.today(now: instant("2026-09-24T14:59:59Z"), in: Zone.tokyo) == date("2026-09-24"))
        #expect(LocalDate.today(now: instant("2026-09-24T15:00:00Z"), in: Zone.tokyo) == date("2026-09-25"))
    }

    @Test("A wall-clock time on a date names one instant")
    func wallClockToInstant() {
        #expect(date("2026-09-25").instant(at: time("15:30"), in: Zone.tokyo) == instant("2026-09-25T06:30:00Z"))
        #expect(date("2026-09-25").instant(at: time("00:00"), in: Zone.tokyo) == instant("2026-09-24T15:00:00Z"))
        #expect(date("2026-09-25").instant(at: time("23:59"), in: Zone.tokyo) == instant("2026-09-25T14:59:00Z"))
    }

    @Test("Seconds are dropped when reading the wall clock")
    func dropsSeconds() {
        #expect(LocalTime(instant("2026-09-25T06:30:59Z"), in: Zone.tokyo) == time("15:30"))
    }
}

@Suite("Converting across daylight-saving changes in America/New_York")
struct NewYorkDaylightSavingTests {
    @Test("The spring-forward day is 23 hours long")
    func springForwardDayLength() {
        let start = date("2026-03-08").start(in: Zone.newYork)
        let next = date("2026-03-09").start(in: Zone.newYork)
        #expect(start == instant("2026-03-08T05:00:00Z"))
        #expect(next.timeIntervalSince(start) == 23 * 3600)
    }

    @Test("The fall-back day is 25 hours long")
    func fallBackDayLength() {
        let start = date("2026-11-01").start(in: Zone.newYork)
        let next = date("2026-11-02").start(in: Zone.newYork)
        #expect(start == instant("2026-11-01T04:00:00Z"))
        #expect(next.timeIntervalSince(start) == 25 * 3600)
    }

    @Test("A skipped time has no instant")
    func skippedTimeIsNil() {
        #expect(date("2026-03-08").instant(at: time("02:30"), in: Zone.newYork) == nil)
        #expect(date("2026-03-08").instant(at: time("01:59"), in: Zone.newYork) == instant("2026-03-08T06:59:00Z"))
        #expect(date("2026-03-08").instant(at: time("03:00"), in: Zone.newYork) == instant("2026-03-08T07:00:00Z"))
    }

    @Test("A repeated time names the earlier of its two instants")
    func repeatedTimeIsEarlier() {
        #expect(date("2026-11-01").instant(at: time("01:30"), in: Zone.newYork) == instant("2026-11-01T05:30:00Z"))
        // The later 01:30 still reads back as 01:30 on the same date.
        let later = instant("2026-11-01T06:30:00Z")
        #expect(LocalDate(later, in: Zone.newYork) == date("2026-11-01"))
        #expect(LocalTime(later, in: Zone.newYork) == time("01:30"))
    }

    @Test("The clock jumps from 01:59 to 03:00")
    func clockJumps() {
        #expect(LocalTime(instant("2026-03-08T06:59:59Z"), in: Zone.newYork) == time("01:59"))
        #expect(LocalTime(instant("2026-03-08T07:00:00Z"), in: Zone.newYork) == time("03:00"))
    }

    @Test("The date changes at local midnight on both sides of the change")
    func dateBoundaries() {
        #expect(LocalDate(instant("2026-03-08T04:59:59Z"), in: Zone.newYork) == date("2026-03-07"))
        #expect(LocalDate(instant("2026-03-08T05:00:00Z"), in: Zone.newYork) == date("2026-03-08"))
        #expect(LocalDate(instant("2026-11-02T04:59:59Z"), in: Zone.newYork) == date("2026-11-01"))
        #expect(LocalDate(instant("2026-11-02T05:00:00Z"), in: Zone.newYork) == date("2026-11-02"))
    }

    @Test("Adding a day to a date is not adding 24 hours")
    func dayIsNotTwentyFourHours() {
        let saturdayNight = instant("2026-03-08T04:30:00Z")   // 23:30 on Saturday 03-07
        let day = LocalDate(saturdayNight, in: Zone.newYork)
        #expect(day.adding(days: 1) == date("2026-03-08"))
        #expect(LocalDate(saturdayNight.addingTimeInterval(24 * 3600), in: Zone.newYork) == date("2026-03-09"))
    }
}

@Suite("A day whose midnight is skipped")
struct SkippedMidnightTests {
    // America/Santiago moves its clocks from 00:00 to 01:00 on 2026-09-06.
    @Test("The day starts at the transition, 01:00 local time")
    func startsAtTransition() {
        let start = date("2026-09-06").start(in: Zone.santiago)
        #expect(start == instant("2026-09-06T04:00:00Z"))
        #expect(LocalDate(start, in: Zone.santiago) == date("2026-09-06"))
        #expect(LocalTime(start, in: Zone.santiago) == time("01:00"))
        #expect(LocalDate(start.addingTimeInterval(-1), in: Zone.santiago) == date("2026-09-05"))
    }

    @Test("Midnight itself has no instant")
    func midnightIsNil() {
        #expect(date("2026-09-06").instant(at: time("00:00"), in: Zone.santiago) == nil)
        #expect(date("2026-09-06").instant(at: time("00:59"), in: Zone.santiago) == nil)
    }

    @Test("The day is 23 hours long")
    func dayLength() {
        let length = date("2026-09-07").start(in: Zone.santiago)
            .timeIntervalSince(date("2026-09-06").start(in: Zone.santiago))
        #expect(length == 23 * 3600)
    }
}

@Suite("Agreement with Foundation's calendar")
struct FoundationAgreementTests {
    /// Instants spread over 1971 through 2037, from a fixed seed so every run checks the same ones.
    private static let samples: [Date] = {
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15
        return (0..<4000).map { _ in
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let seconds = 31_536_000 + Int(state >> 33) % 2_100_000_000
            return Date(timeIntervalSince1970: Double(seconds))
        }
    }()

    @Test("Date and wall-clock time match Calendar.dateComponents", arguments: Zone.all)
    func componentsMatch(_ timeZone: TimeZone) {
        let calendar = Calendar.gregorian(timeZone: timeZone)
        for sample in Self.samples {
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: sample)
            let day = LocalDate(sample, in: timeZone)
            let clock = LocalTime(sample, in: timeZone)
            #expect(parts.year == day.year && parts.month == day.month && parts.day == day.day, "\(sample)")
            #expect(parts.hour == clock.hour && parts.minute == clock.minute, "\(sample)")
        }
    }

    @Test("The start of a day matches Calendar.startOfDay", arguments: Zone.all)
    func startOfDayMatches(_ timeZone: TimeZone) {
        let calendar = Calendar.gregorian(timeZone: timeZone)
        for sample in Self.samples {
            let day = LocalDate(sample, in: timeZone)
            #expect(day.start(in: timeZone) == calendar.startOfDay(for: sample), "\(day) in \(timeZone.identifier)")
        }
    }

    @Test("A wall-clock time converts to an instant that reads back the same", arguments: Zone.all)
    func wallClockRoundTrips(_ timeZone: TimeZone) {
        for sample in Self.samples {
            let day = LocalDate(sample, in: timeZone)
            let clock = LocalTime(sample, in: timeZone)
            guard let back = day.instant(at: clock, in: timeZone) else {
                Issue.record("\(day) \(clock) exists in \(timeZone.identifier) but converted to nil")
                continue
            }
            #expect(LocalDate(back, in: timeZone) == day)
            #expect(LocalTime(back, in: timeZone) == clock)
            #expect(back <= sample, "the earlier instant is chosen, so it is never after the sample")
        }
    }
}
