# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-09-30

### Added

- `LocalDate`: a Gregorian calendar date with no time zone, years 1 through 9999. Adds and counts
  days, knows its weekday, is `Comparable` and `Strideable` so `a...b` is an iterable run of days,
  and uses `"YYYY-MM-DD"` for text, `Codable` and dictionary keys. Any other text is refused.
- Months and weeks on `LocalDate`: `daysInMonth`, `monthSpan` (the 1st through the last day) and
  `startOfWeek(firstWeekday:)`.
- `LocalTime`: a wall-clock time to the minute, `"HH:mm"` for text and `Codable`.
- `Weekday`, whose raw value is Foundation's `weekday` number (Sunday is 1) and whose `Codable` form
  is the lowercase English name, such as `"monday"`.
- Conversions between instants and dates or wall-clock times, each taking a `TimeZone`:
  `LocalDate(_:in:)`, `LocalDate.today(now:in:)`, `start(in:)`, `instant(at:in:)` and
  `LocalTime(_:in:)`. A skipped wall-clock time converts to `nil`, a repeated one to its earlier
  instant, a day whose midnight is skipped starts at the transition, and a date skipped entirely
  starts where the next date starts.
- `LocalDate(_:in:)` and `LocalTime(_:in:)` return `nil` for an instant that is NaN, infinite, or
  outside years 1 through 9999 (such as `Date.distantPast`), so input from outside never traps.
  `today(now:in:)` stays non-optional for a real clock's value.
- `DateSpan`: days from a first through a last day, with nights, days, containment and overlap.
- `TimeWindow`: instants from a start up to, but not including, an end; a zero-length window is a
  fixed time that holds its one instant. `contains`, `overlaps` and `intersection` all follow that
  rule, so back-to-back windows do not overlap and two fixed times at the same instant do.
- `Calendar.gregorian(timeZone:)`: a Gregorian calendar pinned to a time zone.
- A test that fails if the sources read the device's clock, time zone, calendar, locale or
  environment.
