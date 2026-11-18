//
//  IngredientLineParser.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 14.11.26.
//

import Foundation
import NaturalLanguage

// MARK: - Parsed ingredient line

/// One ingredient line from a recipe website, split into amount, unit, name and note.
///
/// `"2-3 EL Olivenöl, kaltgepresst"` becomes amount 3, amount text `"2-3"`, unit `"EL"`,
/// name `"Olivenöl"` and note `"kaltgepresst"`.
nonisolated struct ParsedIngredientLine: Equatable, Sendable {
    /// The full line as it was on the website.
    var originalText: String
    /// The amount, or `nil` when the line has none (e.g. "Salt and pepper"). For a range, the upper bound.
    var amount: Double?
    /// The amount as written, set only when it can't be represented by a single number (ranges like "2-3").
    var amountText: String?
    /// The unit as written (e.g. "EL", "g", "cups"), or `nil`.
    var unit: String?
    /// The unit this line uses, when it is a known one.
    var knownUnit: KnownIngredientUnit?
    /// The ingredient name, without amount, unit and note.
    var name: String
    /// Additional information, from text after a comma or in parentheses.
    var note: String
    /// A quantity without a number, like "n. B." or "etwas". It's also part of the note.
    var vagueAmount: String? = nil
}

// MARK: - Known units

/// Units that are commonly used on recipe websites, with their spellings in English and German.
/// They are used to recognize the unit of an ingredient line and to find the matching Grocy quantity unit.
nonisolated enum KnownIngredientUnit: String, CaseIterable, Sendable {
    case milligram, gram, kilogram
    case milliliter, centiliter, deciliter, liter
    case teaspoon, tablespoon, cup
    case ounce, pound, fluidOunce
    case pinch, dash, handful
    case piece, clove, bunch, sprig, slice, leaf, stalk
    case can, jar, package, bag, cube, tub

    /// `true` for units that measure an amount (weight, volume, spoons, a pinch), `false` for units that count things (pieces, cans, bunches).
    /// "1 Paprikaschote" means one piece, so it can't be stored in a product's measuring unit like grams.
    var isMeasure: Bool {
        switch self {
        case .milligram, .gram, .kilogram, .milliliter, .centiliter, .deciliter, .liter, .teaspoon, .tablespoon, .cup,
            .ounce, .pound, .fluidOunce, .pinch, .dash, .handful:
            true
        case .piece, .clove, .bunch, .sprig, .slice, .leaf, .stalk, .can, .jar, .package, .bag, .cube, .tub:
            false
        }
    }

    /// Lowercased spellings, without a trailing period.
    var aliases: [String] {
        switch self {
        case .milligram: ["mg", "milligram", "milligrams", "milligramm"]
        case .gram: ["g", "gr", "gram", "grams", "gramm", "gramme"]
        case .kilogram: ["kg", "kilo", "kilogram", "kilograms", "kilogramm"]
        case .milliliter: ["ml", "milliliter", "milliliters", "millilitre", "millilitres"]
        case .centiliter: ["cl", "centiliter", "zentiliter"]
        case .deciliter: ["dl", "deciliter", "deziliter"]
        case .liter: ["l", "ltr", "liter", "liters", "litre", "litres"]
        case .teaspoon: ["tl", "teelöffel", "tsp", "teaspoon", "teaspoons"]
        case .tablespoon: ["el", "essl", "eßl", "esslöffel", "eßlöffel", "tbsp", "tbs", "tablespoon", "tablespoons"]
        case .cup: ["cup", "cups", "tasse", "tassen"]
        case .ounce: ["oz", "ounce", "ounces", "unze", "unzen"]
        case .pound: ["lb", "lbs", "pound", "pounds", "pfund"]
        case .fluidOunce: ["fl oz", "floz", "fluid ounce", "fluid ounces"]
        case .pinch: ["prise", "prisen", "pinch", "pinches", "msp", "messerspitze", "messerspitzen"]
        case .dash: ["schuss", "spritzer", "dash", "dashes", "splash"]
        case .handful: ["handvoll", "hand voll", "handful", "handfuls"]
        case .piece: ["stück", "stk", "st", "piece", "pieces", "pc", "pcs", "schote", "schoten"]
        case .clove: ["zehe", "zehen", "clove", "cloves"]
        case .bunch: ["bund", "bunch", "bunches", "bd"]
        case .sprig: ["zweig", "zweige", "zweiglein", "sprig", "sprigs", "stiel", "stiele"]
        case .slice: ["scheibe", "scheiben", "slice", "slices"]
        case .leaf: ["blatt", "blätter", "leaf", "leaves"]
        case .stalk: ["stange", "stangen", "stalk", "stalks"]
        case .can: ["dose", "dosen", "can", "cans", "tin", "tins"]
        case .jar: ["glas", "gläser", "jar", "jars"]
        case .package: ["pck", "pkg", "pkt", "päckchen", "packung", "packungen", "package", "packages", "packet", "packets", "pack"]
        case .bag: ["beutel", "tüte", "tüten", "bag", "bags"]
        case .cube: ["würfel", "cube", "cubes"]
        case .tub: ["becher", "tub", "tubs"]
        }
    }

    /// Unit words at the end of compound words, like "Paprikaschote" (a piece of paprika) or "Knoblauchzehe" (a clove of garlic).
    /// Longest first, so the plural is found before the singular.
    static let compoundSuffixes: [(suffix: String, unit: KnownIngredientUnit)] = [
        ("schoten", .piece), ("schote", .piece), ("zehen", .clove), ("zehe", .clove), ("stangen", .stalk), ("stange", .stalk),
        ("zweige", .sprig), ("zweig", .sprig), ("blätter", .leaf), ("blatt", .leaf), ("scheiben", .slice), ("scheibe", .slice),
    ]

    /// The UN/CEFACT common codes some websites use in structured ingredients (`unitCode`).
    var unitCodes: [String] {
        switch self {
        case .milligram: ["MGM"]
        case .gram: ["GRM"]
        case .kilogram: ["KGM"]
        case .milliliter: ["MLT"]
        case .centiliter: ["CLT"]
        case .deciliter: ["DLT"]
        case .liter: ["LTR"]
        case .teaspoon: ["G25"]
        case .tablespoon: ["G24"]
        case .cup: ["G21"]
        case .ounce: ["ONZ"]
        case .pound: ["LBR"]
        case .fluidOunce: ["OZA"]
        case .piece: ["H87", "C62", "EA"]
        default: []
        }
    }

    /// Finds the known unit for a spelling like "EL", "Esslöffel", "tbsp." or "GRM".
    static func matching(_ token: String) -> KnownIngredientUnit? {
        let normalized = token.normalizedUnitToken
        guard !normalized.isEmpty else { return nil }
        return allCases.first { unit in
            unit.aliases.contains(normalized) || unit.unitCodes.contains(token.uppercased())
        }
    }
}

// MARK: - Parser

/// Splits ingredient lines like "200 g Butter, weich" into amount, unit, name and note.
nonisolated enum IngredientLineParser {

    /// Parses an ingredient from the JSON-LD parser.
    static func parse(_ ingredient: Ingredient) -> ParsedIngredientLine {
        switch ingredient {
        case .text(let text):
            return parse(text)
        case .structured(let value, let name, let unitCode):
            var line = parse(name)
            line.originalText = ingredient.displayText
            if let amount = parseAmount(value.trimmingCharacters(in: .whitespaces)), amount.consumedAll {
                line.amount = amount.value
                line.amountText = amount.isRange ? value : nil
            }
            if let unitCode, !unitCode.isEmpty {
                line.unit = unitCode
                line.knownUnit = KnownIngredientUnit.matching(unitCode)
            }
            return line
        }
    }

    /// Parses a plain ingredient line.
    static func parse(_ rawText: String) -> ParsedIngredientLine {
        let text = rawText.strippingHTML.collapsingWhitespace
        var line = ParsedIngredientLine(originalText: text, amount: nil, amountText: nil, unit: nil, knownUnit: nil, name: text, note: "")
        var rest = Substring(text)
        var notes: [String] = []

        // Vague quantities like "n. B. Butter" or "etwas Salz" have no amount; they are kept as note
        for word in vagueQuantities {
            if rest.lowercased().hasPrefix(word + " ") {
                let vagueAmount = String(rest.prefix(word.count))
                notes.append(vagueAmount)
                line.vagueAmount = vagueAmount
                rest = rest.dropFirst(word.count).drop(while: { $0.isWhitespace })
                break
            }
        }

        // Amount
        if let amount = parseAmount(String(rest)) {
            line.amount = amount.value
            if amount.isRange {
                line.amountText = String(rest.prefix(amount.length)).trimmingCharacters(in: .whitespaces)
            }
            rest = rest.dropFirst(amount.length)
        }

        // Unit, either directly after the amount ("200g") or as the next word ("200 g", "2 EL", "1 fl oz")
        rest = rest.drop(while: { $0.isWhitespace })
        if let (unitText, length) = leadingUnit(in: rest) {
            line.unit = unitText
            line.knownUnit = KnownIngredientUnit.matching(unitText)
            rest = rest.dropFirst(length)
        }
        rest = rest.drop(while: { $0.isWhitespace || $0 == "." })

        // Name and note: "Zwiebel(n), fein gewürfelt (ca. 100 g)"
        var name = String(rest)
        if let commaIndex = firstIndexOutsideParentheses(of: ",", in: name) {
            notes.append(String(name[name.index(after: commaIndex)...]))
            name = String(name[..<commaIndex])
        }
        name = extractParentheses(from: name, into: &notes)

        line.name = name.collapsingWhitespace
        if line.unit == nil {
            separateCompoundUnit(of: &line)
        }
        line.note = notes.map(\.collapsingWhitespace).filter { !$0.isEmpty }.joined(separator: ", ")
        if line.name.isEmpty {
            // Lines like "1 Prise" without a name
            line.name = line.unit ?? text
        }
        return line
    }

    /// "1 Paprikaschote" is one piece of paprika: the unit word at the end of the name becomes the unit.
    private static func separateCompoundUnit(of line: inout ParsedIngredientLine) {
        var words = line.name.components(separatedBy: " ")
        guard let lastWord = words.last else { return }
        let lowercased = lastWord.lowercased()
        for (suffix, unit) in KnownIngredientUnit.compoundSuffixes where lowercased.hasSuffix(suffix) {
            let stem = String(lastWord.dropLast(suffix.count)).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            // "Zehe" alone is the unit; "Ei-Scheibe" has a too short stem to be sure
            guard stem.count >= 3 else { return }
            words[words.count - 1] = stem
            line.name = words.joined(separator: " ")
            line.unit = String(lastWord.suffix(suffix.count)).capitalized
            line.knownUnit = unit
            return
        }
    }

    // MARK: Splitting

    /// The words for "and" that join several ingredients in one line, per language (ISO 639-1 code).
    /// Languages that write "and" attached to the next word (Hebrew, Korean) or without spaces (Chinese, Japanese) aren't split.
    private static let conjunctions: [String: [String]] = [
        "ca": ["i"], "cs": ["a"], "da": ["og"], "de": ["und", "sowie"], "el": ["και"], "en": ["and"], "es": ["y", "e"],
        "et": ["ja"], "fi": ["ja"], "fr": ["et"], "hu": ["és"], "it": ["e", "ed"], "lt": ["ir"], "nb": ["og"], "nl": ["en"],
        "no": ["og"], "pl": ["i", "oraz"], "pt": ["e"], "ro": ["și", "şi"], "ru": ["и"], "sk": ["a"], "sl": ["in"], "sv": ["och"],
        "ta": ["மற்றும்"], "tr": ["ve"], "uk": ["і", "й", "та"],
    ]
    /// Symbols that mean "and" in every language.
    private static let conjunctionSymbols = ["&", "+"]

    /// The words that join ingredients in `language`. For an unknown language, the unambiguous words of all languages
    /// (short ones like "e" or "en" also mean other things).
    static func conjunctions(for language: String?) -> Set<String> {
        let words = language.flatMap { conjunctions[$0] } ?? conjunctions.values.flatMap { $0 }.filter { $0.count >= 3 }
        return Set(words + conjunctionSymbols)
    }

    /// The language of a recipe's ingredient lines as an ISO 639-1 code, e.g. "de", or `nil` when it can't be recognized.
    static func language(of lines: [ParsedIngredientLine]) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(lines.map(\.originalText).joined(separator: "\n"))
        guard let language = recognizer.dominantLanguage, language != .undetermined else { return nil }
        return String(language.rawValue.prefix(while: { $0 != "-" }))
    }

    /// Splits a line that names several ingredients, like "n. B. Salz und Pfeffer", into one line per ingredient.
    /// A part without its own amount gets the amount and unit of the line, so "2 EL Öl und Essig" becomes "2 EL Öl" and "2 EL Essig".
    /// The note applies to every part. Returns `nil` when the line names only one ingredient.
    static func split(_ line: ParsedIngredientLine, language: String?) -> [ParsedIngredientLine]? {
        let conjunctions = conjunctions(for: language)
        var parts: [String] = [""]
        for word in line.name.components(separatedBy: " ") where !word.isEmpty {
            if conjunctions.contains(word.lowercased()) {
                parts.append("")
            } else {
                parts[parts.count - 1] += parts[parts.count - 1].isEmpty ? word : " " + word
            }
        }
        // "Salz und" or "und Pfeffer" aren't two ingredients
        guard parts.count > 1, parts.allSatisfy({ !$0.isEmpty }) else { return nil }

        // The amount and unit as written, e.g. "n. B. " of "n. B. Salz und Pfeffer"
        let quantityText = line.originalText.range(of: line.name).map { String(line.originalText[..<$0.lowerBound]) } ?? ""

        return parts.map { text in
            var part = parse(text)
            if part.amount == nil, part.unit == nil, part.vagueAmount == nil {
                part.originalText = quantityText + text
                part.amount = line.amount
                part.amountText = line.amountText
                part.unit = line.unit
                part.knownUnit = line.knownUnit
                part.vagueAmount = line.vagueAmount
            } else if part.amount == nil, part.vagueAmount == nil, line.unit == nil {
                // "1 Paprikaschote und Zwiebel": the part's unit comes from its name, the amount from the line
                part.originalText = quantityText + text
                part.amount = line.amount
                part.amountText = line.amountText
                part.vagueAmount = line.vagueAmount
            }
            part.note = [line.note, part.note].filter { !$0.isEmpty }.joined(separator: ", ")
            return part
        }
    }

    /// The first `character` that isn't inside parentheses, so "Speck (durchwachsener, klein geschnittener)" keeps its note together.
    private static func firstIndexOutsideParentheses(of character: Character, in text: String) -> String.Index? {
        var depth = 0
        for index in text.indices {
            switch text[index] {
            case "(": depth += 1
            case ")": depth = max(0, depth - 1)
            case character where depth == 0: return index
            default: break
            }
        }
        return nil
    }

    /// Words that stand for an amount without a number, longest first.
    private static let vagueQuantities = [
        "nach belieben", "nach geschmack", "nach bedarf", "n. b.", "n.b.", "evtl.", "eventuell", "etwas", "einige", "wenig",
        "to taste", "a little", "a pinch of", "some",
    ]

    // MARK: Amount

    struct ParsedAmount {
        let value: Double
        let isRange: Bool
        /// Number of characters used from the start of the text.
        let length: Int
        var consumedAll: Bool = false
    }

    private static let unicodeFractions: [Character: Double] = [
        "½": 0.5, "⅓": 1.0 / 3.0, "⅔": 2.0 / 3.0, "¼": 0.25, "¾": 0.75,
        "⅕": 0.2, "⅖": 0.4, "⅗": 0.6, "⅘": 0.8, "⅙": 1.0 / 6.0, "⅚": 5.0 / 6.0,
        "⅛": 0.125, "⅜": 0.375, "⅝": 0.625, "⅞": 0.875,
    ]

    /// Reads a number at the start of `text`: "2", "1,5", "1.5", "1/2", "1 1/2", "1½", "½", or a range "2-3" / "2 bis 3" / "2 to 3".
    static func parseAmount(_ text: String) -> ParsedAmount? {
        let characters = Array(text)
        var index = 0

        func skipSpaces() {
            while index < characters.count, characters[index] == " " { index += 1 }
        }

        func readNumber() -> Double? {
            let start = index
            var digits = ""
            while index < characters.count, characters[index].isASCII, characters[index].isNumber || characters[index] == "," || characters[index] == "." {
                digits.append(characters[index])
                index += 1
            }
            // A trailing separator belongs to the sentence ("2.") and not to the number
            while let last = digits.last, last == "," || last == "." {
                digits.removeLast()
                index -= 1
            }
            var value: Double? = digits.isEmpty ? nil : Double(digits.replacingOccurrences(of: ",", with: "."))

            // Fraction: "1/2" or "1⁄2"
            if let numerator = value, index < characters.count, characters[index] == "/" || characters[index] == "⁄" {
                let fractionStart = index
                index += 1
                var denominatorDigits = ""
                while index < characters.count, characters[index].isASCII, characters[index].isNumber {
                    denominatorDigits.append(characters[index])
                    index += 1
                }
                if let denominator = Double(denominatorDigits), denominator > 0 {
                    value = numerator / denominator
                } else {
                    index = fractionStart
                }
            }

            // Unicode fraction, alone ("½") or after a whole number ("1½" / "1 ½")
            let beforeFraction = index
            if value != nil { skipSpaces() }
            if index < characters.count, let fraction = unicodeFractions[characters[index]] {
                value = (value ?? 0) + fraction
                index += 1
            } else {
                index = beforeFraction
            }

            // Mixed number: "1 1/2"
            if let whole = value, whole == whole.rounded(), index < characters.count, characters[index] == " " {
                let mixedStart = index
                skipSpaces()
                var numeratorDigits = ""
                while index < characters.count, characters[index].isASCII, characters[index].isNumber {
                    numeratorDigits.append(characters[index])
                    index += 1
                }
                if !numeratorDigits.isEmpty, index < characters.count, characters[index] == "/" || characters[index] == "⁄" {
                    index += 1
                    var denominatorDigits = ""
                    while index < characters.count, characters[index].isASCII, characters[index].isNumber {
                        denominatorDigits.append(characters[index])
                        index += 1
                    }
                    if let numerator = Double(numeratorDigits), let denominator = Double(denominatorDigits), denominator > 0 {
                        value = whole + numerator / denominator
                    } else {
                        index = mixedStart
                    }
                } else {
                    index = mixedStart
                }
            }

            if value == nil { index = start }
            return value
        }

        guard let first = readNumber() else { return nil }
        var result = ParsedAmount(value: first, isRange: false, length: index)

        // Range: "2-3", "2 – 3", "2 bis 3", "2 to 3", "2 or 3"
        let afterFirst = index
        skipSpaces()
        var hasSeparator = false
        if index < characters.count, "-–—".contains(characters[index]) {
            index += 1
            hasSeparator = true
        } else {
            for word in ["bis ", "to ", "or ", "oder "] {
                let candidate = String(characters[index..<min(characters.count, index + word.count)]).lowercased()
                if candidate == word {
                    index += word.count
                    hasSeparator = true
                    break
                }
            }
        }
        if hasSeparator {
            skipSpaces()
            if let second = readNumber(), second >= first {
                result = ParsedAmount(value: second, isRange: true, length: index)
            } else {
                index = afterFirst
            }
        } else {
            index = afterFirst
        }

        result.consumedAll = result.length == characters.count
        return result
    }

    // MARK: Unit

    /// Finds a unit at the start of `text`. Known units are always recognized;
    /// an unknown word is only taken as a unit when it is followed by more text and ends with a period ("Pck.").
    private static func leadingUnit(in text: Substring) -> (String, Int)? {
        let words = text.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard let firstWord = words.first else { return nil }

        // Two-word units like "fl oz" or "Hand voll"
        if words.count >= 2 {
            let twoWords = "\(firstWord) \(words[1])"
            if KnownIngredientUnit.matching(twoWords) != nil, words.count > 2 {
                return (twoWords.trimmingTrailingPeriod, text.distance(from: text.startIndex, to: words[1].endIndex))
            }
        }

        let length = text.distance(from: text.startIndex, to: firstWord.endIndex)
        let hasMoreText = words.count > 1

        if KnownIngredientUnit.matching(String(firstWord)) != nil {
            return (String(firstWord).trimmingTrailingPeriod, length)
        }
        if hasMoreText, firstWord.hasSuffix("."), firstWord.count > 1 {
            return (String(firstWord).trimmingTrailingPeriod, length)
        }
        return nil
    }

    // MARK: Note

    /// Moves text in parentheses into `notes`. Short plural markers like "Zwiebel(n)" or "egg(s)" are removed.
    private static func extractParentheses(from text: String, into notes: inout [String]) -> String {
        var result = ""
        var depth = 0
        var current = ""
        for character in text {
            if character == "(" {
                depth += 1
                if depth == 1 { current = ""; continue }
            } else if character == ")", depth > 0 {
                depth -= 1
                if depth == 0 {
                    let content = current.trimmingCharacters(in: .whitespaces)
                    if content.count > 2 { notes.append(content) }
                    continue
                }
            }
            if depth > 0 { current.append(character) } else { result.append(character) }
        }
        return result
    }
}

// MARK: - String helpers

nonisolated extension String {
    /// Lowercased and without a trailing period, for comparing unit spellings ("Pck." == "pck").
    /// Plural markers like "Zehe/n", "Dose(n)" or "cup(s)" are removed.
    var normalizedUnitToken: String {
        trimmingCharacters(in: .whitespaces).lowercased().trimmingTrailingPeriod.removingPluralMarker
    }

    /// Removes German and English plural markers at the end: "Zwiebel(n)" → "Zwiebel", "Zehe/n" → "Zehe", "egg(s)" → "egg".
    var removingPluralMarker: String {
        replacingOccurrences(of: "(\\((n|en|e|er|s|es)\\)|/(n|en|e|er|s|es))$", with: "", options: [.regularExpression, .caseInsensitive])
    }

    var trimmingTrailingPeriod: String {
        var result = self
        while result.hasSuffix(".") { result.removeLast() }
        return result
    }

    /// Replaces runs of whitespace with a single space and trims the ends.
    var collapsingWhitespace: String {
        split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    /// Removes HTML tags and decodes the most common HTML entities.
    var strippingHTML: String {
        var text = replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return text.decodingHTMLEntities
    }

    var decodingHTMLEntities: String {
        guard contains("&") else { return self }
        let named: [String: String] = [
            "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&apos;": "'", "&#39;": "'",
            "&nbsp;": " ", "&frac12;": "½", "&frac14;": "¼", "&frac34;": "¾", "&ndash;": "–", "&mdash;": "—",
            "&auml;": "ä", "&ouml;": "ö", "&uuml;": "ü", "&Auml;": "Ä", "&Ouml;": "Ö", "&Uuml;": "Ü", "&szlig;": "ß",
            "&deg;": "°", "&hellip;": "…",
        ]
        var text = self
        for (entity, replacement) in named {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }
        // Numeric entities: &#8211; and &#x2013;
        guard let regex = try? NSRegularExpression(pattern: "&#(x?)([0-9a-fA-F]+);") else { return text }
        let nsText = text as NSString
        var result = ""
        var lastEnd = 0
        for match in regex.matches(in: text, range: NSRange(location: 0, length: nsText.length)) {
            result += nsText.substring(with: NSRange(location: lastEnd, length: match.range.location - lastEnd))
            let isHex = nsText.substring(with: match.range(at: 1)) == "x"
            let number = nsText.substring(with: match.range(at: 2))
            if let code = UInt32(number, radix: isHex ? 16 : 10), let scalar = Unicode.Scalar(code) {
                result.append(Character(scalar))
            } else {
                result += nsText.substring(with: match.range)
            }
            lastEnd = match.range.location + match.range.length
        }
        result += nsText.substring(from: lastEnd)
        return result
    }
}
