import Foundation

/// Proleptic Gregorian arithmetic on day numbers counted from 1970-01-01.
///
/// The algorithms are Howard Hinnant's `days_from_civil` / `civil_from_days`. They need no
/// `Calendar`, so the result cannot depend on the device's calendar, locale or time zone.
enum Civil {
    static let secondsPerDay = 86_400
    static let years: ClosedRange<Int> = 1...9999

    static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 2: isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11: 30
        default: 31
        }
    }

    static func isValid(year: Int, month: Int, day: Int) -> Bool {
        years.contains(year)
            && (1...12).contains(month)
            && day >= 1 && day <= daysInMonth(year: year, month: month)
    }

    static func dayNumber(year: Int, month: Int, day: Int) -> Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yearOfEra = y - era * 400
        let dayOfYear = (153 * (month + (month > 2 ? -3 : 9)) + 2) / 5 + day - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146_097 + dayOfEra - 719_468
    }

    static func civil(dayNumber: Int) -> (year: Int, month: Int, day: Int) {
        let z = dayNumber + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let dayOfEra = z - era * 146_097
        let yearOfEra = (dayOfEra - dayOfEra / 1460 + dayOfEra / 36524 - dayOfEra / 146_096) / 365
        let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
        let shiftedMonth = (5 * dayOfYear + 2) / 153
        let day = dayOfYear - (153 * shiftedMonth + 2) / 5 + 1
        let month = shiftedMonth < 10 ? shiftedMonth + 3 : shiftedMonth - 9
        return (yearOfEra + era * 400 + (month <= 2 ? 1 : 0), month, day)
    }

    /// Splits an instant into its local day number and the seconds elapsed since that day's midnight.
    static func wallClock(of instant: Date, in timeZone: TimeZone) -> (dayNumber: Int, secondOfDay: Int) {
        let offset = timeZone.secondsFromGMT(for: instant)
        let local = Int((instant.timeIntervalSince1970 + Double(offset)).rounded(.down))
        let dayNumber = local >= 0 ? local / secondsPerDay : (local + 1) / secondsPerDay - 1
        return (dayNumber, local - dayNumber * secondsPerDay)
    }
}

extension TimeZone {
    /// Every instant whose wall clock reads `wall` (seconds since local 1970-01-01 00:00), earliest first.
    ///
    /// Empty inside a spring-forward gap, two instants inside a fall-back overlap.
    func instants(atWall wall: Int) -> [Date] {
        let offsets = Set([wall - Civil.secondsPerDay, wall, wall + Civil.secondsPerDay].map {
            secondsFromGMT(for: Date(timeIntervalSince1970: Double($0)))
        })
        return offsets
            .map { wall - $0 }
            .filter { secondsFromGMT(for: Date(timeIntervalSince1970: Double($0))) == wall - $0 }
            .sorted()
            .map { Date(timeIntervalSince1970: Double($0)) }
    }

    /// The first instant whose wall clock reads `wall` or later.
    ///
    /// Equals the earliest of ``instants(atWall:)`` when the wall time exists. Inside a gap it is the
    /// transition itself, which is where the skipped stretch of the day actually begins.
    func firstInstant(atOrAfterWall wall: Int) -> Date {
        if let exact = instants(atWall: wall).first { return exact }
        let before = secondsFromGMT(for: Date(timeIntervalSince1970: Double(wall - Civil.secondsPerDay)))
        let after = secondsFromGMT(for: Date(timeIntervalSince1970: Double(wall + Civil.secondsPerDay)))
        // A gap means the offset jumped forward from `before` to `after` at some instant T with
        // T + before <= wall < T + after, so T lies in (wall - after, wall - before].
        var low = wall - max(after, before) + 1
        var high = wall - before
        while low < high {
            let mid = low + (high - low) / 2
            if secondsFromGMT(for: Date(timeIntervalSince1970: Double(mid))) == before {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return Date(timeIntervalSince1970: Double(low))
    }
}
