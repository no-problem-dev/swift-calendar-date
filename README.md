# CalendarDate

English | [日本語](./README.ja.md)

Calendar dates that never depend on the device's time zone — "today", "yesterday" and "the start of the day" come out the same on every phone, because the time zone is always an argument.

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014%20%7C%20tvOS%2017%20%7C%20watchOS%2010%20%7C%20visionOS%201-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Features

- **A date without a time zone**: `LocalDate` is a day on the calendar. It adds and counts days, knows its weekday, and forms ranges you can iterate
- **The time zone is always explicit**: every conversion between an instant and a date or wall-clock time takes a `TimeZone`. Nothing reads the device's clock, time zone, calendar or locale, and a test enforces it
- **One text form**: `"YYYY-MM-DD"` for `Codable`, dictionary keys and parsing. Anything else is refused instead of guessed
- **Daylight saving handled honestly**: a skipped wall-clock time converts to `nil`, a repeated one to its earlier instant, and a day whose midnight is skipped starts at the transition
- **Input from outside never crashes**: text, JSON and instants (`Date.distantPast`, NaN, milliseconds read as seconds) convert to `nil` when they are not a date. Only arithmetic you control, such as stepping past year 9999, traps
- **Spans and windows that cannot be reversed**: `DateSpan` (days, first through last) and `TimeWindow` (instants from a start up to an end) are `nil` when reversed, including when decoded. A `TimeWindow` holds its start but not its end, so back-to-back windows never overlap; a zero-length window is a fixed time, and two at the same instant overlap
- **Months and weeks**: `daysInMonth`, `monthSpan` and `startOfWeek(firstWeekday:)` build calendar grids without a `Calendar`
- **Foundation only**: no dependencies, `Sendable` throughout

## Usage

```swift
import CalendarDate

let tokyo = TimeZone(identifier: "Asia/Tokyo")!
let now = Date()                                          // your clock, passed in
let today = LocalDate.today(now: now, in: tokyo)          // 2026-09-25, wherever the phone is
let lastRead = LocalDate("2026-09-24")!
let streakAlive = lastRead >= today.adding(days: -1)

let trip = DateSpan(first: LocalDate("2026-09-23")!, last: today)!
trip.nights                                               // 2
for day in trip.days { print(day, day.weekday) }

let meeting = today.instant(at: LocalTime("15:30")!, in: tokyo)   // Date?
let week = today.startOfWeek(firstWeekday: .monday)...today       // this week so far

let fromServer = Date(timeIntervalSince1970: serverSeconds)
let day: LocalDate? = LocalDate(fromServer, in: tokyo)            // nil if it is not a date
```

A date that is not known yet is `LocalDate?` and `nil` — not an empty string, which neither parses
nor decodes.

## Documentation

The API reference and an article on how time zones and daylight saving are handled live on
[GitHub Pages](https://no-problem-dev.github.io/swift-calendar-date/documentation/calendardate/).

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-calendar-date.git", .upToNextMinor(from: "0.1.0"))
]
```

Then add the product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "CalendarDate", package: "swift-calendar-date")
    ]
)
```

## License

MIT License - See [LICENSE](LICENSE) for details.
