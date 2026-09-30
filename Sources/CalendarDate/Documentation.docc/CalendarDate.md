# ``CalendarDate``

Calendar dates, wall-clock times and spans whose answers depend only on their arguments.

@Metadata {
    @PageColor(blue)
}

## Overview

A `Date` is an instant. Most app logic, though, is about days: today's reading streak, the date
printed on a receipt, the nights of a trip. Deriving those from `Date` with `Calendar.current` makes
the answer depend on where the phone is, so the same data gives a different "today" in Tokyo and in
New York.

This package keeps days and instants apart. ``LocalDate`` and ``LocalTime`` carry no time zone, and
every conversion to or from an instant takes a `TimeZone` argument. The package never reads the
device's clock, time zone, calendar or locale; "now" is always passed in.

```swift
let tokyo = TimeZone(identifier: "Asia/Tokyo")!

// A receipt dated up to one day ahead is accepted; counted in days, not in 24-hour steps.
func accepts(_ printed: LocalDate, now: Date) -> Bool {
    (-365...1).contains(LocalDate.today(now: now, in: tokyo).days(to: printed))
}

// Visits per day, keyed by date; encodes as {"2026-09-25": 3, ...}.
let visitsPerDay = Dictionary(grouping: visits) { LocalDate($0.at, in: tokyo) }.mapValues(\.count)
```

## Topics

### Essentials

- <doc:TimeZonesAndDaylightSaving>

### Dates and times

- ``LocalDate``
- ``LocalTime``
- ``Weekday``

### Spans

- ``DateSpan``
- ``TimeWindow``

### Calendars

- ``Foundation/Calendar/gregorian(timeZone:)``
