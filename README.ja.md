# CalendarDate

[English](./README.md) | 日本語

端末の時間帯に左右されない暦の日付。時間帯を必ず引数で受けるので、「今日」「昨日」「その日の始まり」がどの端末でも同じになる。

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014%20%7C%20tvOS%2017%20%7C%20watchOS%2010%20%7C%20visionOS%201-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 特徴

- **時間帯を持たない日付**: `LocalDate` は暦の上の 1 日。日の加減・日数の差・曜日・繰り返せる範囲を持つ
- **時間帯は必ず明示する**: 瞬間と日付・壁時計の時刻の変換は、どれも `TimeZone` を引数で受ける。端末の時計・時間帯・暦・ロケールは読まない。読んでいないことをテストが確かめる
- **文字列の形は 1 つ**: `Codable`・辞書のキー・文字列からの変換は `"YYYY-MM-DD"` だけ。ほかの形は推測せずに拒む
- **夏時間を曖昧にしない**: 飛ばされた時刻は `nil`、2 回来る時刻は早い方の瞬間、0 時が飛ばされる日は切り替わりの瞬間から始まる
- **外から来た値で落ちない**: 文字列・JSON・瞬間（`Date.distantPast`・NaN・ミリ秒を秒と取り違えた値）は、日付にならなければ `nil` になる。落ちるのは、年 9999 を越えて日を足すような、呼ぶ側が決めた計算の誤りだけ
- **逆向きにならない幅**: `DateSpan`（最初の日〜最後の日）と `TimeWindow`（始まりの瞬間から終わりの瞬間の手前まで）は、逆向きなら `nil`。デコードでも同じ。`TimeWindow` は始まりを含み終わりを含まないので、続けて並べた窓は重ならない。幅0の窓は時刻に固定した予定で、同じ時刻の2つは重なる
- **月と週**: `daysInMonth`・`monthSpan`・`startOfWeek(firstWeekday:)` で、`Calendar` を使わずに月や週の表を作れる
- **Foundation だけ**: 依存なし。すべて `Sendable`

## 使い方

```swift
import CalendarDate

let tokyo = TimeZone(identifier: "Asia/Tokyo")!
let now = Date()                                          // 時計は呼ぶ側が渡す
let today = LocalDate.today(now: now, in: tokyo)          // 端末がどこにあっても 2026-09-25
let lastRead = LocalDate("2026-09-24")!
let streakAlive = lastRead >= today.adding(days: -1)

let trip = DateSpan(first: LocalDate("2026-09-23")!, last: today)!
trip.nights                                               // 2
for day in trip.days { print(day, day.weekday) }

let meeting = today.instant(at: LocalTime("15:30")!, in: tokyo)   // Date?
let week = today.startOfWeek(firstWeekday: .monday)...today       // 今週の今日まで

let fromServer = Date(timeIntervalSince1970: serverSeconds)
let day: LocalDate? = LocalDate(fromServer, in: tokyo)            // 日付でなければ nil
```

まだ日付が無いことは `LocalDate?` の `nil` で表す。空文字は使わない（変換もデコードも通らない）。

## ドキュメント

API リファレンスと、時間帯・夏時間の扱いの解説は
[GitHub Pages](https://no-problem-dev.github.io/swift-calendar-date/documentation/calendardate/) にある。

## インストール

`Package.swift` に追加する:

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-calendar-date.git", .upToNextMinor(from: "0.1.0"))
]
```

ターゲットに追加する:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "CalendarDate", package: "swift-calendar-date")
    ]
)
```

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照。
