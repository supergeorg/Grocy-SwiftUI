//
//  DateFormatter.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

extension Date {
    var asJSONDateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self)
    }
    nonisolated var iso8601withFractionalSeconds: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: self)
    }

    /// Local date and time as Grocy's `IsIsoDateTime` expects it (`Y-m-d H:i:s`), e.g. for `tracked_time`.
    /// Grocy ignores other formats and uses the current time instead.
    nonisolated var grocyDateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter.string(from: self)
    }

    nonisolated var hasTimeComponent: Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: self)
        return self != startOfDay
    }

    /// Whether the date carries a real time of day worth showing.
    /// Grocy stores date-only values as midnight (`00:00:00`) or as the end of the day (`23:59:59`, e.g. due dates of chores tracked by date).
    nonisolated var hasTimeOfDay: Bool {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: self)
        let isStartOfDay = components.hour == 0 && components.minute == 0 && components.second == 0
        let isEndOfDay = components.hour == 23 && components.minute == 59 && components.second == 59
        return !isStartOfDay && !isEndOfDay
    }
}

func formatDateOutput(_ dateStrIN: String) -> String? {
    if dateStrIN == "2999-12-31" {
        return "unlimited"
    }
    let dateFormatterIN = DateFormatter()
    dateFormatterIN.dateFormat = "yyyy-MM-dd"
    let dateToFormat = dateFormatterIN.date(from: dateStrIN)
    let dateFormatterOUT = DateFormatter()
    dateFormatterOUT.dateFormat = "dd.MM.yyyy"
    if let dateToFormat = dateToFormat {
        let dateStrOut = dateFormatterOUT.string(from: dateToFormat)
        return dateStrOut
    } else {
        return nil
    }
}

func formatDateAsString(_ date: Date?, showTime: Bool? = false, localizationKey: String? = nil) -> String? {
    if let date = date {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        if let localizationKey = localizationKey {
            dateFormatter.locale = Locale(identifier: localizationKey)
        } else {
            dateFormatter.locale = .current
        }
        dateFormatter.dateStyle = .medium
        if showTime == true {
            dateFormatter.timeStyle = .medium
        }
        let dateStr = dateFormatter.string(from: date)
        return dateStr
    } else {
        return nil
    }
}

/// Formats a date from Grocy and adds the time when the value has one (see `Date.hasTimeOfDay`).
/// - Parameter dateOnly: Hides the time, e.g. for chores that are tracked by date only.
nonisolated func formatDateTimeAsString(_ date: Date?, dateOnly: Bool = false, localizationKey: String? = nil) -> String? {
    guard let date else { return nil }
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone.current
    dateFormatter.locale = localizationKey.map { Locale(identifier: $0) } ?? .current
    dateFormatter.dateStyle = .medium
    if !dateOnly && date.hasTimeOfDay {
        dateFormatter.timeStyle = .short
    }
    return dateFormatter.string(from: date)
}

func formatTimestampOutput(_ timeStamp: String, localizationKey: String? = nil) -> String? {
    let timeStampDate = getDateFromTimestamp(timeStamp)
    let timeStampFormatted = formatDateAsString(timeStampDate, showTime: true, localizationKey: localizationKey)
    return timeStampFormatted
}

/// Parses dates and timestamps from Grocy and from older app versions.
///
/// Grocy's own formats (`Y-m-d` and `Y-m-d H:i:s`, local time) take a fast path without a formatter: a full sync
/// parses thousands of them, and creating formatters for each one took seconds on the main thread.
/// Everything else goes through formatters that are made once.
nonisolated func getDateFromString(_ dateString: String?) -> Date? {
    guard let dateString else { return nil }
    if let date = GrocyDateParser.parseGrocyFormat(dateString) {
        return date
    }
    return GrocyDateParser.parseWithFormatters(dateString)
}

nonisolated enum GrocyDateParser {
    // All of them are Sendable and only configured here, once, so they can be shared without `nonisolated(unsafe)`.
    // ISO 8601 uses format styles: `ISO8601DateFormatter` isn't Sendable.
    private static let isoWithFractionalSeconds = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let iso = Date.ISO8601FormatStyle()
    // Grocy stores local times without a time zone.
    // Older app versions wrote timestamps in the device's 12-hour format ("2026-08-12 4:33:51 PM"), so those are read too (#250).
    private static let formatters: [DateFormatter] = [
        "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd HH:mm", "yyyy-MM-dd h:mm:ss a", "yyyy-MM-dd h:mm a",
        "yyyy-MM-dd",
    ].map { format in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = format
        return formatter
    }

    /// The same order as before: ISO 8601 first, then the custom formats.
    static func parseWithFormatters(_ dateString: String) -> Date? {
        if let date = (try? isoWithFractionalSeconds.parse(dateString)) ?? (try? iso.parse(dateString)) {
            return date
        }
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }

    /// `yyyy-MM-dd` or `yyyy-MM-dd HH:mm:ss` in the current time zone, or nil for anything else.
    /// Values the formatters would treat differently (an invalid day, a time skipped by daylight saving time)
    /// return nil too, so they still take the formatter path.
    static func parseGrocyFormat(_ dateString: String) -> Date? {
        let bytes = Array(dateString.utf8)
        guard bytes.count == 10 || bytes.count == 19 else { return nil }

        func number(_ range: Range<Int>) -> Int? {
            var value = 0
            for index in range {
                let byte = bytes[index]
                guard byte >= 48 && byte <= 57 else { return nil }
                value = value * 10 + Int(byte - 48)
            }
            return value
        }

        guard bytes[4] == 45, bytes[7] == 45,  // "-"
            let year = number(0..<4), let month = number(5..<7), let day = number(8..<10)
        else { return nil }
        var hour = 0
        var minute = 0
        var second = 0
        if bytes.count == 19 {
            guard bytes[10] == 32, bytes[13] == 58, bytes[16] == 58,  // " ", ":", ":"
                let parsedHour = number(11..<13), let parsedMinute = number(14..<16), let parsedSecond = number(17..<19)
            else { return nil }
            hour = parsedHour
            minute = parsedMinute
            second = parsedSecond
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
        guard let date = calendar.date(from: components) else { return nil }
        // Calendar rolls invalid values over (February 30 becomes March 2); the formatters reject them.
        let check = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        guard check.year == year, check.month == month, check.day == day, check.hour == hour, check.minute == minute,
            check.second == second
        else { return nil }
        // Around a daylight saving time change a local time can exist twice, and Calendar and the formatters pick
        // different ones. Those rare values keep the formatters' result.
        if let transition = calendar.timeZone.nextDaylightSavingTimeTransition(after: date.addingTimeInterval(-2 * 3600)),
            abs(transition.timeIntervalSince(date)) < 2 * 3600
        {
            return nil
        }
        return date
    }
}

/// Parses a Grocy timestamp (`Y-m-d H:i:s`, local time).
nonisolated func getDateFromTimestamp(_ dateString: String) -> Date? {
    getDateFromString(dateString)
}

func getTimeDistanceFromNow(date: Date) -> Int? {
    let startDate = Date()
    let endDate = date
    let components = Calendar.current.dateComponents([.day], from: startDate, to: endDate)
    return components.day
}

func getTimeDistanceFromString(_ dateStrIN: String) -> Int? {
    if let date = getDateFromString(dateStrIN) {
        return getTimeDistanceFromNow(date: date)
    } else {
        return nil
    }
}

func formatDays(daysToFormat: Int?) -> String? {
    let datecomponents = DateComponents(day: daysToFormat)
    let dcf = DateComponentsFormatter()
    dcf.allowedUnits = [.day, .month, .year]
    dcf.unitsStyle = .abbreviated
    return dcf.string(from: datecomponents)
}

func getRelativeDateAsText(_ date: Date?, localizationKey: String? = nil) -> String? {
    if let date = date {
        if Calendar.current.isDateInToday(date) || Calendar.current.isDateInTomorrow(date) || Calendar.current.isDateInYesterday(date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.doesRelativeDateFormatting = true
            if let localizationKey = localizationKey {
                dateFormatter.locale = Locale(identifier: localizationKey)
            } else {
                dateFormatter.locale = .current
            }
            return dateFormatter.string(from: date)
        } else {
            let dateFormatter = RelativeDateTimeFormatter()
            if let localizationKey = localizationKey {
                dateFormatter.locale = Locale(identifier: localizationKey)
            } else {
                dateFormatter.locale = .current
            }
            dateFormatter.dateTimeStyle = .named
            return dateFormatter.localizedString(for: date, relativeTo: Date())
        }
    } else {
        return nil
    }
}

func formatDuration(value: Int, unit: Calendar.Component, localizationKey: String? = nil) -> String? {
    var components = DateComponents()

    switch unit {
    case .year:
        components.year = value
    case .month:
        components.month = value
    case .weekOfMonth:
        components.weekOfMonth = value
    case .day:
        components.day = value
    case .hour:
        components.hour = value
    case .minute:
        components.minute = value
    case .second:
        components.second = value
    default:
        return nil
    }

    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute, .second]

    // Set calendar with locale
    var calendar = Calendar.current
    if let localizationKey = localizationKey {
        calendar.locale = Locale(identifier: localizationKey)
    }
    formatter.calendar = calendar

    return formatter.string(from: components)
}

extension Date {
    nonisolated static let neverOverdue: Date = {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(
            calendar: calendar,
            timeZone: TimeZone(abbreviation: "UTC"),
            year: 2999,
            month: 12,
            day: 31,
            hour: 0,
            minute: 0,
            second: 0
        )
        return calendar.startOfDay(for: calendar.date(from: components)!)
    }()
}

func daysDifference(for date: Date?) -> Int? {
    guard let nextTime = date else { return nil }
    return Calendar.current.dateComponents(
        [.day],
        from: Calendar.current.startOfDay(for: .now),
        to: Calendar.current.startOfDay(for: nextTime)
    ).day
}

extension String {
    var asDate: Date? {
        if let date = detectDate() {
            return date
        }
        return parseStructuredDate()
    }

    private func detectDate() -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return nil }
        let range = NSRange(startIndex..., in: self)
        let match = detector.firstMatch(in: self, options: [], range: range)
        return match?.date
    }

    private func parseStructuredDate() -> Date? {
        // Only needed for compact formats NSDataDetector won't catch
        let compactFormats = ["ddMMyyyy", "yyyyMMdd", "MMyyyy", "MMyy"]
        let input = expandTwoDigitYear()

        for format in compactFormats {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = format
            if let date = df.date(from: input) { return date }
        }
        return nil
    }

    private func expandTwoDigitYear() -> String {
        let parts = components(separatedBy: CharacterSet(charactersIn: ".-/"))
        guard parts.count == 3,
            let last = parts.last,
            last.count == 2,
            let year = Int(last)
        else { return self }

        let separator = String(self.first(where: { ".-/".contains($0) }) ?? ".")
        let expanded = parts.dropLast() + [String(2000 + year)]
        return expanded.joined(separator: separator)
    }
}
