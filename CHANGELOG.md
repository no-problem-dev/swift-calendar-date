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
- `LocalTime`: a wall-clock time to the minute, `"HH:mm"` for text and `Codable`.
- `Weekday`, numbered as Foundation's `weekday` component.
- Conversions between instants and dates or wall-clock times, each taking a `TimeZone`:
  `LocalDate(_:in:)`, `LocalDate.today(now:in:)`, `start(in:)`, `instant(at:in:)` and
  `LocalTime(_:in:)`. A skipped wall-clock time converts to `nil`, a repeated one to its earlier
  instant, and a day whose midnight is skipped starts at the transition.
- `DateSpan`: days from a first through a last day, with nights, days, containment and overlap.
- `TimeWindow`: instants from a start through an end, with duration, containment, overlap and
  intersection.
- `Calendar.gregorian(timeZone:)`: a Gregorian calendar pinned to a time zone.
- A test that fails if the sources read the device's clock, time zone, calendar or locale.
