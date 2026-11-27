//
//  DateParsingTests.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import Foundation
import Testing

@testable import Grocy_Mobile

@Suite("Parsing and showing Grocy dates")
struct DateParsingTests {
    private func components(_ date: Date?) -> DateComponents? {
        date.map { Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: $0) }
    }

    @Test("Grocy's local date and time formats are parsed as local time")
    func parsesLocalFormats() {
        let expected = DateComponents(year: 2025, month: 11, day: 23, hour: 14, minute: 5, second: 9)
        #expect(components(getDateFromString("2025-11-23 14:05:09")) == expected)
        #expect(components(getDateFromString("2025-11-23T14:05:09")) == expected)
        #expect(components(getDateFromTimestamp("2025-11-23 14:05:09")) == expected)
        #expect(components(getDateFromString("2025-11-23")) == DateComponents(year: 2025, month: 11, day: 23, hour: 0, minute: 0, second: 0))
        #expect(getDateFromString("2025-11-23T14:05:09Z") != nil)
        #expect(getDateFromString("not a date") == nil)
    }

    @Test("ISO 8601 dates with a time zone are parsed as that moment, with or without fractional seconds")
    func parsesISO8601() {
        let moment = Date(timeIntervalSince1970: 1_763_906_709)  // 2025-11-23 14:05:09 UTC
        #expect(getDateFromString("2025-11-23T14:05:09Z") == moment)
        #expect(getDateFromString("2025-11-23T15:05:09+01:00") == moment)
        #expect(getDateFromString("2025-11-23T14:05:09.500Z") == moment.addingTimeInterval(0.5))
    }

    @Test("Timestamps an older app version wrote in the 12-hour format are parsed (#250)")
    func parsesTwelveHourTimestamps() {
        #expect(components(getDateFromString("2026-08-12 4:33:51 PM")) == DateComponents(year: 2026, month: 8, day: 12, hour: 16, minute: 33, second: 51))
        #expect(components(getDateFromString("2026-08-12 12:05:00 AM")) == DateComponents(year: 2026, month: 8, day: 12, hour: 0, minute: 5, second: 0))
        #expect(components(getDateFromString("2026-08-12 9:15 AM")) == DateComponents(year: 2026, month: 8, day: 12, hour: 9, minute: 15, second: 0))
    }

    @Test(
        "Only real times of day are shown",
        arguments: [
            ("2025-11-23 00:00:00", false),
            ("2025-11-23 23:59:59", false),
            ("2025-11-23", false),
            ("2025-11-23 14:05:09", true),
            ("2025-11-23 00:30:00", true),
        ]
    )
    func timeOfDay(dateString: String, hasTime: Bool) throws {
        let date = try #require(getDateFromString(dateString))
        #expect(date.hasTimeOfDay == hasTime)
    }

    @Test("Date-only values are formatted without a time")
    func formatting() throws {
        let withTime = try #require(getDateFromString("2025-11-23 14:05:09"))
        let midnight = try #require(getDateFromString("2025-11-23 00:00:00"))
        let dateOnly = try #require(formatDateTimeAsString(midnight, localizationKey: "en"))
        #expect(formatDateTimeAsString(withTime, localizationKey: "en") != dateOnly)
        #expect(formatDateTimeAsString(withTime, dateOnly: true, localizationKey: "en") == dateOnly)
    }

    @Test(
        "The fast path for Grocy's formats gives the same dates as the formatters",
        arguments: [
            "2026-11-25", "2026-11-25 10:11:12", "2024-02-29 23:59:59", "2999-12-31", "2026-01-01 00:00:00", "2026-12-31 23:59:59",
        ]
    )
    func fastPathMatchesFormatters(dateString: String) throws {
        let fast = try #require(GrocyDateParser.parseGrocyFormat(dateString))
        #expect(fast == GrocyDateParser.parseWithFormatters(dateString))
    }

    @Test(
        "Other values skip the fast path",
        arguments: [
            "2026-02-30", "2026-13-01", "2026-11-25 24:00:00", "2026-11-25 10:61:00", "2026-11-25T10:11:12", "2026-11-25 10:11",
            "2026-1-05", "2026-11-25x10:11:12", "",
        ]
    )
    func fastPathRejects(dateString: String) {
        #expect(GrocyDateParser.parseGrocyFormat(dateString) == nil)
    }

    @Test("Values the fast path rejects are still read by the formatters")
    func fallback() {
        #expect(getDateFromString("2026-11-25T10:11:12") != nil)
        #expect(getDateFromString("2026-08-12 4:33:51 PM") != nil)
        #expect(getDateFromString("2026-11-25T10:11:12.123Z") != nil)
        #expect(getDateFromString("2026-02-30") == nil)
    }
}
