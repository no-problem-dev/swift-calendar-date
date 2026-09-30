# Time Zones and Daylight Saving

Why every conversion takes a time zone, and what happens on the days a clock skips or repeats an hour.

## Overview

A date is only meaningful together with the time zone it was read in. 03:00 UTC on 2026-09-25 is noon
on the 25th in Tokyo and 23:00 on the 24th in New York. Code that reads the device's time zone gets a
different answer when the user travels, and tests that pass at home fail on a machine set to UTC.

So the package has no default. Each conversion names its time zone:

| From | To | API |
|---|---|---|
| `Date` | ``LocalDate`` | ``LocalDate/init(_:in:)``, ``LocalDate/today(now:in:)`` |
| `Date` | ``LocalTime`` | ``LocalTime/init(_:in:)`` |
| ``LocalDate`` | `Date` | ``LocalDate/start(in:)`` |
| ``LocalDate`` + ``LocalTime`` | `Date` | ``LocalDate/instant(at:in:)`` |

Arithmetic on dates — ``LocalDate/adding(days:)``, ``LocalDate/days(to:)``, ``LocalDate/weekday`` —
needs no time zone at all, and is computed without a `Calendar`.

## Days are not 24 hours

Where clocks change, a day can be 23 or 25 hours long. In America/New_York, 2026-03-08 is 23 hours and
2026-11-01 is 25. Adding one day to a ``LocalDate`` always moves to the next date; adding 86,400
seconds to a `Date` does not. Step in days, then convert once.

## Times the clock skips

When clocks spring forward, a stretch of wall-clock times never happens. In New York there is no
02:30 on 2026-03-08. ``LocalDate/instant(at:in:)`` returns `nil` for such a time rather than a nearby
time the caller did not ask for, so the caller decides what a missing time means.

## Times the clock repeats

When clocks fall back, a stretch of wall-clock times happens twice. In New York, 01:30 on 2026-11-01
comes first in daylight time and again an hour later in standard time.
``LocalDate/instant(at:in:)`` returns the earlier one. Both instants read back as the same
``LocalDate`` and ``LocalTime``.

## Days whose midnight is skipped

A few time zones change their clocks at midnight. America/Santiago goes from 00:00 straight to 01:00
on 2026-09-06, so that date has no midnight. ``LocalDate/start(in:)`` returns the first instant the
date exists, 01:00 local time, which matches Foundation's `Calendar.startOfDay(for:)`.

## When a Calendar is still needed

For date math these types do not cover, ``Foundation/Calendar/gregorian(timeZone:)`` makes a
Gregorian calendar pinned to a time zone. Set its `locale` yourself if the app needs one; the package
does not choose one for you.
