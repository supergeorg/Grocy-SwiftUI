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
}
