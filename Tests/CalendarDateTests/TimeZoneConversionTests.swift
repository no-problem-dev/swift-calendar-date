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
        #expect(day?.adding(days: 1) == date("2026-03-08"))
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
    /// Instants spread over 1900 through 2037 with fractions of a second, from a fixed seed so every run
    /// checks the same ones. Instants before 1970 have negative seconds, where rounding toward zero
    /// instead of down would read the wrong day.
    private static let samples: [Date] = {
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15
        let first = -2_208_988_800   // 1900-01-01T00:00:00Z
        let span = 4_354_905_600     // through 2037-12-31
        return (0..<4000).map { _ in
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let seconds = first + Int(state >> 20) % span
            return Date(timeIntervalSince1970: Double(seconds) + Double(state % 1000) / 1000)
        }
    }()

    @Test("Date and wall-clock time match Calendar.dateComponents", arguments: Zone.all)
    func componentsMatch(_ timeZone: TimeZone) {
        let calendar = Calendar.gregorian(timeZone: timeZone)
        for sample in Self.samples {
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: sample)
            guard let day = LocalDate(sample, in: timeZone), let clock = LocalTime(sample, in: timeZone) else {
                Issue.record("\(sample) did not convert in \(timeZone.identifier)")
                continue
            }
            #expect(parts.year == day.year && parts.month == day.month && parts.day == day.day, "\(sample)")
            #expect(parts.hour == clock.hour && parts.minute == clock.minute, "\(sample)")
        }
    }

    @Test("The start of a day matches Calendar.startOfDay", arguments: Zone.all)
    func startOfDayMatches(_ timeZone: TimeZone) {
        let calendar = Calendar.gregorian(timeZone: timeZone)
        for sample in Self.samples {
            let day = LocalDate(sample, in: timeZone)
            #expect(day?.start(in: timeZone) == calendar.startOfDay(for: sample), "\(sample) in \(timeZone.identifier)")
        }
    }

    @Test("A wall-clock time converts to an instant that reads back the same", arguments: Zone.all)
    func wallClockRoundTrips(_ timeZone: TimeZone) {
        for sample in Self.samples {
            guard let day = LocalDate(sample, in: timeZone), let clock = LocalTime(sample, in: timeZone) else {
                Issue.record("\(sample) did not convert in \(timeZone.identifier)")
                continue
            }
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

@Suite("Every clock change from 1970 through 2037")
struct TransitionTests {
    private static let from = Date(timeIntervalSince1970: 0)
    private static let through = Date(timeIntervalSince1970: 2_145_916_800)   // 2038-01-01T00:00:00Z

    private static func transitions(in timeZone: TimeZone) -> [Date] {
        var found: [Date] = []
        var cursor = from
        while let next = timeZone.nextDaylightSavingTimeTransition(after: cursor), next < through {
            found.append(next)
            cursor = next
        }
        return found
    }

    @Test("The walk finds the transitions", arguments: Zone.changing)
    func findsTransitions(_ timeZone: TimeZone) {
        #expect(Self.transitions(in: timeZone).count >= 10, "\(timeZone.identifier)")
    }

    @Test("Around each transition, the start of the day matches Calendar.startOfDay", arguments: Zone.changing)
    func startOfDayAroundTransitions(_ timeZone: TimeZone) {
        let calendar = Calendar.gregorian(timeZone: timeZone)
        for transition in Self.transitions(in: timeZone) {
            for offset in [-86_400.0, -1, 0, 1, 86_400] {
                let instant = transition.addingTimeInterval(offset)
                #expect(
                    LocalDate(instant, in: timeZone)?.start(in: timeZone) == calendar.startOfDay(for: instant),
                    "\(instant) in \(timeZone.identifier)"
                )
            }
        }
    }

    /// Every quarter hour on the day of each transition converts to the earliest instant whose wall clock
    /// reads that time, found here from the offsets on both sides of the transition; nil when neither fits.
    @Test("Around each transition, wall-clock times convert to the earliest matching instant", arguments: Zone.changing)
    func wallClockAroundTransitions(_ timeZone: TimeZone) {
        for transition in Self.transitions(in: timeZone) {
            let offsets = [
                timeZone.secondsFromGMT(for: transition.addingTimeInterval(-1)),
                timeZone.secondsFromGMT(for: transition),
            ]
            guard let day = LocalDate(transition, in: timeZone) else {
                Issue.record("\(transition) did not convert in \(timeZone.identifier)")
                continue
            }
            let midnight = Double(day.dayNumber * 86_400)
            for quarter in 0..<96 {
                let time = LocalTime(hour: quarter / 4, minute: quarter % 4 * 15)!
                let wall = midnight + Double(time.minuteOfDay * 60)
                let expected = offsets
                    .map { Date(timeIntervalSince1970: wall - Double($0)) }
                    .filter { LocalDate($0, in: timeZone) == day && LocalTime($0, in: timeZone) == time }
                    .min()
                #expect(day.instant(at: time, in: timeZone) == expected, "\(day) \(time) in \(timeZone.identifier)")
            }
        }
    }
}

@Suite("Instants before 1970 and fractions of a second")
struct NegativeAndFractionalSecondsTests {
    @Test("One second before 1970 is still 1969-12-31 at 23:59")
    func oneSecondBeforeEpoch() {
        #expect(LocalDate(Date(timeIntervalSince1970: -1), in: Zone.utc) == date("1969-12-31"))
        #expect(LocalTime(Date(timeIntervalSince1970: -1), in: Zone.utc) == time("23:59"))
        #expect(LocalDate(Date(timeIntervalSince1970: -0.5), in: Zone.utc) == date("1969-12-31"))
        #expect(LocalDate(Date(timeIntervalSince1970: -86_400), in: Zone.utc) == date("1969-12-31"))
        #expect(LocalDate(Date(timeIntervalSince1970: -86_400.5), in: Zone.utc) == date("1969-12-30"))
    }

    @Test("A fraction of a second before midnight is still the same day")
    func fractionBeforeMidnight() {
        #expect(LocalDate(Date(timeIntervalSince1970: 86_399.999), in: Zone.utc) == date("1970-01-01"))
        #expect(LocalTime(Date(timeIntervalSince1970: 86_399.999), in: Zone.utc) == time("23:59"))
        #expect(LocalDate(instant("2026-09-24T14:59:59Z").addingTimeInterval(0.9), in: Zone.tokyo) == date("2026-09-24"))
    }
}

@Suite("Instants that are not a date")
struct OutOfRangeInstantTests {
    @Test("Instants outside years 1 through 9999, NaN and infinity convert to nil", arguments: [
        Date.distantPast,
        Date(timeIntervalSince1970: 1e12),
        Date(timeIntervalSince1970: -1e12),
        Date(timeIntervalSinceReferenceDate: .nan),
        Date(timeIntervalSinceReferenceDate: .infinity),
        Date(timeIntervalSinceReferenceDate: -.infinity),
        Date(timeIntervalSince1970: 1e300),
    ])
    func nilOutsideRange(_ instant: Date) {
        for timeZone in Zone.all {
            #expect(LocalDate(instant, in: timeZone) == nil)
            #expect(LocalTime(instant, in: timeZone) == nil)
        }
    }

    @Test("The first and last instants of the supported years still convert")
    func edgesConvert() {
        let first = date("0001-01-01").start(in: Zone.utc)
        #expect(LocalDate(first, in: Zone.utc) == date("0001-01-01"))
        #expect(LocalTime(first, in: Zone.utc) == time("00:00"))
        #expect(LocalDate(first.addingTimeInterval(-0.001), in: Zone.utc) == nil)

        let last = date("9999-12-31").instant(at: time("23:59"), in: Zone.utc)!.addingTimeInterval(59.999)
        #expect(LocalDate(last, in: Zone.utc) == date("9999-12-31"))
        #expect(LocalTime(last, in: Zone.utc) == time("23:59"))
        #expect(LocalDate(last.addingTimeInterval(0.001), in: Zone.utc) == nil)
        #expect(LocalDate(Date.distantFuture, in: Zone.utc) == date("4001-01-01"))
    }

    @Test("Where the local date is in range the conversion works, even if UTC's is not")
    func localOffsetDecides() {
        let lastUTC = date("9999-12-31").instant(at: time("23:59"), in: Zone.utc)!.addingTimeInterval(60)
        #expect(LocalDate(lastUTC, in: Zone.utc) == nil)
        #expect(LocalDate(lastUTC, in: Zone.newYork) == date("9999-12-31"))
        #expect(LocalDate(lastUTC, in: Zone.tokyo) == nil)
    }

    @Test("Stepping past year 9999 traps")
    func addingPastLastYearTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = LocalDate("9999-12-31")!.adding(days: 1)
        }
    }

    @Test("A clock that reports a year outside 1 through 9999 traps in today(now:in:)")
    func todayTrapsOnImpossibleClock() async {
        await #expect(processExitsWith: .failure) {
            _ = LocalDate.today(now: .distantPast, in: TimeZone(identifier: "UTC")!)
        }
    }
}

@Suite("A day a time zone skips entirely")
struct SkippedDayTests {
    // Pacific/Apia went from 2011-12-29 straight to 2011-12-31.
    @Test("The skipped day starts where the next day starts, and that instant reads as the next day")
    func skippedDayStart() {
        let skipped = date("2011-12-30")
        #expect(skipped.start(in: Zone.apia) == skipped.adding(days: 1).start(in: Zone.apia))
        #expect(LocalDate(skipped.start(in: Zone.apia), in: Zone.apia) == date("2011-12-31"))
        #expect(skipped.instant(at: time("12:00"), in: Zone.apia) == nil)
        #expect(date("2011-12-29").instant(at: time("23:59"), in: Zone.apia) != nil)
    }
}
