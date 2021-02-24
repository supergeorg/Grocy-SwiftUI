//
//  DateFormatter.swift
//  grocy-ios
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
}

extension String {
    var iso8601withFractionalSeconds: Date? { return Formatter.iso8601withFractionalSeconds.date(from: self) }
}

func formatDateOutput(_ dateStrIN: String) -> String? {
    if dateStrIN == "2999-12-31" {
        return "unbegrenzt"
    }
    let dateFormatterIN = DateFormatter()
    dateFormatterIN.dateFormat = "yyyy-MM-dd"
    let dateToFormat = dateFormatterIN.date(from: dateStrIN)
    let dateFormatterOUT = DateFormatter()
    dateFormatterOUT.dateFormat = "dd.MM.yyyy"
    if dateToFormat != nil {
        let dateStrOut = dateFormatterOUT.string(from: dateToFormat!)
        return dateStrOut
    } else {
        return nil//"Fehler bei Datum"
    }
}

func formatDateAsString(_ date: Date, showTime: Bool = true) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    if showTime {
        dateFormatter.timeStyle = .medium
    }
    let dateStr = dateFormatter.string(from: date)
    return dateStr
}

func formatTimestampOutput(_ timeStampIN: String) -> String {
    let dateFormatterIN = DateFormatter()
    //    EX: 2020-11-20 13:04:38
    dateFormatterIN.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateToFormat = dateFormatterIN.date(from: timeStampIN)
    let dateFormatterOUT = DateFormatter()
    dateFormatterOUT.dateFormat = "dd.MM.yyyy HH:mm:ss"
    if dateToFormat != nil {
        let dateStrOut = dateFormatterOUT.string(from: dateToFormat!)
        return dateStrOut
    } else {
        return "Fehler bei Datum"
    }
}

func getDateFromString(_ dateStrIN: String) -> Date? {
    let dateFormatterIN = DateFormatter()
    dateFormatterIN.dateFormat = "yyyy-MM-dd"
    let dateToFormat = dateFormatterIN.date(from: dateStrIN)
    return dateToFormat
}

func getDateFromTimestamp(_ timeStampIN: String) -> Date? {
    let dateFormatterIN = DateFormatter()
    dateFormatterIN.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateToFormat = dateFormatterIN.date(from: timeStampIN)
    return dateToFormat
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
    } else {return nil}
}

func formatDays(daysToFormat: Int?) -> String? {
    let datecomponents = DateComponents(day: daysToFormat)
    
    let dcf = DateComponentsFormatter()
    dcf.allowedUnits = [.day, .month, .year]
    dcf.unitsStyle = .abbreviated
    return dcf.string(from: datecomponents)
}

func getRelativeDateAsText(_ date: Date, localizationKey: String? = nil) -> String {
    let formatter = RelativeDateTimeFormatter()
    if let localizationKey = localizationKey {
        formatter.locale = Locale(identifier: localizationKey)
    } else {
        formatter.locale = .current
    }
    formatter.dateTimeStyle = .named
    if let formattedString = formatter.string(for: date) { return formattedString } else { return "" }
}
