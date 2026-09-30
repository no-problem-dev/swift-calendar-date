import Foundation
import Testing

/// The package promises that every answer depends only on its arguments. These tests read the source
/// and fail if anything reaches for the device's clock, time zone, calendar or locale.
@Suite("Source policy")
struct SourcePolicyTests {
    private static let sourceDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources/CalendarDate")

    /// What the device decides: the clock, and the current time zone, calendar and locale.
    private static let forbidden: [(name: String, pattern: String)] = [
        ("Date()", #"\bDate\s*\(\s*\)"#),
        ("Date.now", #"\.now\b"#),
        ("TimeZone.current", #"\bTimeZone\s*\.\s*(current|autoupdatingCurrent|local)\b"#),
        ("Calendar.current", #"\bCalendar\s*\.\s*(current|autoupdatingCurrent)\b"#),
        ("Locale.current", #"\bLocale\s*\.\s*(current|autoupdatingCurrent)\b"#),
        (".current shorthand", #"\.(current|autoupdatingCurrent)\b"#),
    ]

    private static func sourceFiles() throws -> [URL] {
        let enumerator = FileManager.default.enumerator(at: sourceDirectory, includingPropertiesForKeys: nil)
        return (enumerator?.allObjects as? [URL] ?? []).filter { $0.pathExtension == "swift" }
    }

    @Test("The sources are where the test looks")
    func findsSources() throws {
        let names = try Self.sourceFiles().map(\.lastPathComponent)
        #expect(names.contains("LocalDate.swift"))
        #expect(names.count >= 5)
    }

    @Test("No source reads the device's clock, time zone, calendar or locale")
    func noAmbientState() throws {
        var hits: [String] = []
        for file in try Self.sourceFiles() {
            let text = try String(contentsOf: file, encoding: .utf8)
            for (name, pattern) in Self.forbidden {
                let regex = try NSRegularExpression(pattern: pattern)
                let count = regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
                if count > 0 { hits.append("\(file.lastPathComponent): \(name) ×\(count)") }
            }
        }
        #expect(hits.isEmpty, "\(hits)")
    }

    @Test("The patterns catch what they are meant to catch", arguments: [
        "let now = Date()", "Date.now", "TimeZone.current", "TimeZone.autoupdatingCurrent",
        "Calendar.current", "Locale.current", "calendar: Calendar = .current", "Locale.autoupdatingCurrent",
    ])
    func patternsBite(_ sample: String) throws {
        let caught = try Self.forbidden.contains { _, pattern in
            try NSRegularExpression(pattern: pattern)
                .numberOfMatches(in: sample, range: NSRange(sample.startIndex..., in: sample)) > 0
        }
        #expect(caught)
    }
}
