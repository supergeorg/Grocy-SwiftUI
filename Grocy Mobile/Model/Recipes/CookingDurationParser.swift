//
//  CookingDurationParser.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 28.11.26.
//

import Foundation

/// A time a preparation step mentions, like "5 Minuten" or "1 hour 30 minutes".
nonisolated struct CookingDuration: Hashable, Sendable {
    /// Where the time is in the text.
    var range: Range<String.Index>
    /// The text that names the time, as written.
    var text: String
    /// The time in seconds. For a range ("20–25 minutes"), the shorter one, so the cook can check in time.
    var seconds: TimeInterval
    /// The longer time of a range, if the text names one.
    var upperSeconds: TimeInterval?
}

/// Finds times in German and English recipe text: digits ("10", "1,5", "½"), number words up to sixty ("fünf", "twenty"),
/// ranges ("20-25", "10 bis 12"), hours, minutes and seconds ("Std.", "min", "Sekunden"), and the common phrases
/// ("eine halbe Stunde", "half an hour", "Viertelstunde"). An hour directly followed by minutes is one time.
nonisolated enum CookingDurationParser {
    private static let numberWords: [String: Double] = [
        "ein": 1, "eine": 1, "einen": 1, "einer": 1, "one": 1, "a": 1, "an": 1,
        "zwei": 2, "two": 2, "drei": 3, "three": 3, "vier": 4, "four": 4, "fünf": 5, "five": 5,
        "sechs": 6, "six": 6, "sieben": 7, "seven": 7, "acht": 8, "eight": 8, "neun": 9, "nine": 9,
        "zehn": 10, "ten": 10, "elf": 11, "eleven": 11, "zwölf": 12, "twelve": 12,
        "fünfzehn": 15, "fifteen": 15, "zwanzig": 20, "twenty": 20, "fünfundzwanzig": 25, "twenty-five": 25,
        "dreißig": 30, "thirty": 30, "vierzig": 40, "forty": 40, "fünfundvierzig": 45, "forty-five": 45,
        "fünfzig": 50, "fifty": 50, "sechzig": 60, "sixty": 60,
        "anderthalb": 1.5, "eineinhalb": 1.5, "zweieinhalb": 2.5,
    ]

    private static let fractions: [Character: Double] = ["½": 0.5, "¼": 0.25, "¾": 0.75, "⅓": 1.0 / 3, "⅔": 2.0 / 3]

    private static let units: [(pattern: String, seconds: Double)] = [
        ("stunden|stunde|std\\.?|hours|hour|hrs\\.?|hr\\.?|h", 3600),
        ("minuten|minute|min\\.?|mins\\.?|minutes", 60),
        ("sekunden|sekunde|sek\\.?|seconds|second|secs\\.?|sec\\.?|s", 1),
    ]

    private static let numberPattern: String = {
        let words = numberWords.keys.sorted { $0.count > $1.count }.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
        let fractionCharacters = String(fractions.keys)
        return "(?:\\d+(?:[.,]\\d+)?[\(fractionCharacters)]?|[\(fractionCharacters)]|\(words))"
    }()

    private static let expression: NSRegularExpression? = {
        let unitPattern = units.map { "(\($0.pattern))" }.joined(separator: "|")
        let rangeSeparator = "\\s*(?:-|–|—|bis|to|or|oder)\\s*"
        let quantity = "(\(numberPattern))(?:\(rangeSeparator)(\(numberPattern)))?\\s*(?:\(unitPattern))"
        let phrases = "(eine\\s+halbe\\s+stunde|halbe\\s+stunde|half\\s+an\\s+hour|viertelstunde|quarter\\s+of\\s+an\\s+hour|dreiviertelstunde)"
        let pattern = "(?<![\\p{L}\\p{N}])(?:\(phrases)|\(quantity))(?![\\p{L}\\p{N}])"
        return try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()

    private static let phraseSeconds: [String: Double] = [
        "eine halbe stunde": 1800, "halbe stunde": 1800, "half an hour": 1800,
        "viertelstunde": 900, "quarter of an hour": 900, "dreiviertelstunde": 2700,
    ]

    /// The times in `text`, in the order they appear.
    static func durations(in text: String) -> [CookingDuration] {
        guard let expression else { return [] }
        let matches = expression.matches(in: text, range: NSRange(text.startIndex..., in: text))
        var found: [CookingDuration] = []
        for match in matches {
            guard let range = Range(match.range, in: text), let duration = duration(of: match, in: text, range: range) else { continue }
            // "1 Stunde 30 Minuten" or "1 h and 30 min" is one time.
            if let last = found.last, last.upperSeconds == nil, duration.upperSeconds == nil, last.seconds >= 3600, duration.seconds < 3600,
                text[last.range.upperBound..<range.lowerBound].trimmingCharacters(in: .whitespaces).lowercased()
                    .isEmptyOrJoiner
            {
                let merged = last.range.lowerBound..<range.upperBound
                found[found.count - 1] = CookingDuration(range: merged, text: String(text[merged]), seconds: last.seconds + duration.seconds)
            } else {
                found.append(duration)
            }
        }
        return found
    }

    private static func duration(of match: NSTextCheckingResult, in text: String, range: Range<String.Index>) -> CookingDuration? {
        func group(_ index: Int) -> String? {
            Range(match.range(at: index), in: text).map { String(text[$0]) }
        }
        if let phrase = group(1) {
            let normalized = phrase.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
            guard let seconds = phraseSeconds[normalized] else { return nil }
            return CookingDuration(range: range, text: String(text[range]), seconds: seconds)
        }
        guard let first = group(2).flatMap(number(from:)) else { return nil }
        let second = group(3).flatMap(number(from:))
        guard let unitIndex = (0..<units.count).first(where: { match.range(at: 4 + $0).location != NSNotFound }) else { return nil }
        let factor = units[unitIndex].seconds
        // Single letters and articles ("a", "s", "h") only count with digits, so "a s" or "an h" aren't times.
        let unit = group(4 + unitIndex)?.lowercased() ?? ""
        let firstText = group(2)?.lowercased() ?? ""
        if ["a", "an"].contains(firstText) && unit.count == 1 { return nil }
        if unit == "s", !firstText.contains(where: \.isNumber) { return nil }

        let lower = min(first, second ?? first) * factor
        let upper = second.map { max(first, $0) * factor }
        guard lower > 0, lower <= 24 * 3600 else { return nil }
        return CookingDuration(range: range, text: String(text[range]), seconds: lower, upperSeconds: upper == lower ? nil : upper)
    }

    private static func number(from text: String) -> Double? {
        let lowered = text.lowercased()
        if let word = numberWords[lowered] { return word }
        var digits = lowered
        var fraction = 0.0
        if let last = digits.last, let value = fractions[last] {
            fraction = value
            digits.removeLast()
        }
        if digits.isEmpty { return fraction }
        guard let value = Double(digits.replacingOccurrences(of: ",", with: ".")) else { return nil }
        return value + fraction
    }
}

extension String {
    /// Nothing, or a word that joins an hour and its minutes ("1 Stunde und 30 Minuten").
    fileprivate nonisolated var isEmptyOrJoiner: Bool {
        ["", "und", "and", ","].contains(self)
    }
}
