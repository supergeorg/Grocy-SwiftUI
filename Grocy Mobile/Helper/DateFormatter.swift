//
//  DateFormatter.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

extension ISO8601DateFormatter {
    convenience init(_ formatOptions: Options, timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!) {
        self.init()
        self.formatOptions = formatOptions
        self.timeZone = timeZone
    }
}

extension Formatter {
    static let iso8601withFractionalSeconds = ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
}

extension Date {
    var iso8601withFractionalSeconds: String { return Formatter.iso8601withFractionalSeconds.string(from: self) }
    var asJSONDateString: String { return formatAsJSONDateString(date: self) }
}

extension String {
    var iso8601withFractionalSeconds: Date? { return Formatter.iso8601withFractionalSeconds.date(from: self) }
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

func formatTimestampOutput(_ timeStamp: String, localizationKey: String? = nil) -> String? {
    let timeStampDate = getDateFromTimestamp(timeStamp)
    let timeStampFormatted = formatDateAsString(timeStampDate, showTime: true, localizationKey: localizationKey)
    return timeStampFormatted
}

func getDateFromString(_ dateString: String) -> Date? {
    let strategy = Date.ISO8601FormatStyle()
        .year()
        .month()
        .day()
        .dateSeparator(.dash)
    let date = try? Date(dateString, strategy: strategy)
    return date
}

func getDateFromTimestamp(_ dateString: String) -> Date? {
    let strategy = Date.ISO8601FormatStyle()
        .year()
        .month()
        .day()
        .dateSeparator(.dash)
        .dateTimeSeparator(.space)
        .time(includingFractionalSeconds: false)
        .timeSeparator(.colon)
    let date = try? Date(dateString, strategy: strategy)
    return date
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
    } else { return nil }
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
            let startOfToday = Calendar.current.startOfDay(for: Date())
            return dateFormatter.localizedString(for: date, relativeTo: startOfToday)
        }
    } else {
        return nil
    }
}

func getNeverOverdueDate() -> Date {
    var dateComponents = DateComponents()
    dateComponents.year = 2999
    dateComponents.month = 12
    dateComponents.day = 31
    dateComponents.timeZone = TimeZone(abbreviation: "UTC")
    dateComponents.hour = 0
    dateComponents.minute = 0
    dateComponents.second = 0
    return Calendar(identifier: .gregorian)
        .date(from: dateComponents)!
}

func formatAsJSONDateString(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.string(from: date)
}
