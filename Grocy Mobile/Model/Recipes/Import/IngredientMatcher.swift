//
//  IngredientMatcher.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import Foundation

// MARK: - Match quality

/// How an imported ingredient got its product or quantity unit.
nonisolated enum IngredientMatchQuality: Hashable, Sendable {
    /// The names are the same (apart from case, plural or a known spelling of the unit).
    case exact
    /// A likely match the person should check, e.g. "Sahne" for "süße Sahne".
    case suggested
    /// Suggested by Apple Intelligence, for an ingredient whose name matches no product, e.g. "Pflanzenöl" → "Rapsöl".
    case intelligence
    /// Chosen by the person.
    case manual
    /// Nothing was found.
    case none

    /// Suggestions, from the names or from Apple Intelligence, that the person should check.
    var needsCheck: Bool {
        self == .suggested || self == .intelligence
    }
}

/// A product that may fit an ingredient, with a score: 100 and more is an exact match, lower ones are suggestions.
struct ProductMatchCandidate {
    let product: MDProduct
    let score: Int

    var quality: IngredientMatchQuality { score >= RecipeImportMapper.exactProductScore ? .exact : .suggested }
}

// MARK: - Products

extension RecipeImportMapper {
    /// Candidates below this score aren't suggested.
    static let minimumProductScore = 40
    /// Candidates with at least this score are exact matches.
    static let exactProductScore = 100

    /// Finds the product for an ingredient name, or `nil` when nothing fits well enough.
    func matchProduct(for ingredientName: String, note: String = "") -> MDProduct? {
        productCandidates(for: ingredientName, note: note).first?.product
    }

    /// Products that may fit an ingredient, best first.
    ///
    /// The note is used to prefer a more specific product: "Thymian (getrockneter)" finds "Thymian, getrocknet"
    /// when it exists, and "Thymian" otherwise. Besides the same name, a product fits when all its words appear
    /// in the ingredient ("Sahne" in "süße Sahne"), when it's the end of a compound word ("Schnitzel" in "Schweineschnitzel"),
    /// when it's more specific than the ingredient ("Mehl Type 405" for "Mehl"), or when the names differ by a typo.
    func productCandidates(for ingredientName: String, note: String = "", limit: Int = 5) -> [ProductMatchCandidate] {
        let nameWords = Self.normalizedName(ingredientName).split(separator: " ").map(String.init).filter { !Self.fillerWords.contains($0) }
        guard !nameWords.isEmpty else { return [] }
        let noteStems = Set(Self.normalizedName(note).split(separator: " ").map { Self.stem(String($0)) })
        let ingredient = MatchableName(words: nameWords)

        let candidates = products.filter(\.active).compactMap { product -> ProductMatchCandidate? in
            let productWords = Self.normalizedName(product.name).split(separator: " ").map(String.init).filter { !Self.fillerWords.contains($0) }
            guard !productWords.isEmpty else { return nil }
            let score = Self.score(product: MatchableName(words: productWords), ingredient: ingredient, noteStems: noteStems)
            return score >= Self.minimumProductScore ? ProductMatchCandidate(product: product, score: score) : nil
        }
        let ingredientLength = ingredient.joined.count
        return Array(
            candidates.sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                // The product whose name is closest in length is the more likely one
                let lhsDistance = abs(lhs.product.name.count - ingredientLength)
                let rhsDistance = abs(rhs.product.name.count - ingredientLength)
                if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
                return lhs.product.name < rhs.product.name
            }
            .prefix(limit)
        )
    }

    /// Words that don't tell products apart.
    /// Products to offer Apple Intelligence for an ingredient that matched none by name.
    /// The model's context is small, so with many products only those sharing the most letter triples with the ingredient are offered.
    func intelligenceCandidates(for ingredientName: String, limit: Int = 120) -> [MDProduct] {
        let activeProducts = products.filter(\.active)
        guard activeProducts.count > limit else { return activeProducts }
        let ingredientTrigrams = Self.trigrams(of: ingredientName)
        return activeProducts
            .map { (product: $0, shared: Self.trigrams(of: $0.name).intersection(ingredientTrigrams).count) }
            .sorted { $0.shared > $1.shared }
            .prefix(limit)
            .map(\.product)
    }

    /// Sets the product Apple Intelligence suggested, then the unit again, as units depend on the product's conversions.
    func intelligenceSuggested(_ product: MDProduct, for ingredient: inout ImportedIngredient) {
        ingredient.productID = product.id
        ingredient.productMatch = .intelligence
        productChanged(&ingredient)
    }

    /// Whether Apple Intelligence should look for a product: nothing matched by name, and the person hasn't chosen one.
    static func needsIntelligenceMatch(_ ingredient: ImportedIngredient) -> Bool {
        ingredient.isIncluded && !ingredient.isSaved && ingredient.productID == nil && ingredient.productMatch == .none
    }

    /// The letter triples of a name, for finding names that share parts (e.g. "Kirschtomate" and "Tomate").
    static func trigrams(of name: String) -> Set<String> {
        let letters = Array(normalizedName(name).replacingOccurrences(of: " ", with: ""))
        guard letters.count >= 3 else { return [String(letters)] }
        return Set((0...(letters.count - 3)).map { String(letters[$0..<($0 + 3)]) })
    }

    private static let fillerWords: Set<String> = ["und", "oder", "mit", "and", "or", "with", "of", "the", "a"]

    /// Normalized words of a name, also stemmed and joined, so they're computed once per name.
    private struct MatchableName {
        let words: [String]
        let stems: [String]
        let stemSet: Set<String>
        /// The name without spaces, for compound words.
        let joined: String

        init(words: [String]) {
            self.words = words
            self.stems = words.map { RecipeImportMapper.stem($0) }
            self.stemSet = Set(stems)
            self.joined = words.joined()
        }
    }

    private static func score(product: MatchableName, ingredient: MatchableName, noteStems: Set<String>) -> Int {
        let productStems = product.stemSet
        let nameStems = ingredient.stemSet

        // Same name, possibly made more specific by the note: "Thymian, getrocknet" for "Thymian (getrockneter)"
        if productStems.isSuperset(of: nameStems) {
            let extraStems = productStems.subtracting(nameStems)
            if extraStems.isEmpty {
                return exactProductScore
            }
            if extraStems.isSubset(of: noteStems) {
                return exactProductScore + 10 + extraStems.count
            }
            // More specific than the ingredient ("Mehl Type 405" for "Mehl"); the more extra words, the less likely
            return max(minimumProductScore, 60 - 5 * extraStems.count)
        }

        // All words of the product appear in the ingredient ("Sahne" in "süße Sahne")
        if productStems.isSubset(of: nameStems.union(noteStems)), !productStems.isDisjoint(with: nameStems) {
            let covered = Double(productStems.intersection(nameStems).count) / Double(nameStems.count)
            return 70 + Int((20 * covered).rounded())
        }

        // Compound words: "Schnitzel" in "Schweineschnitzel", or the more specific "Weizenmehl" for "Mehl"
        if product.joined.count >= 4, ingredient.words.contains(where: { $0.count > product.joined.count && $0.hasSuffix(product.joined) }) {
            return 55
        }
        if ingredient.joined.count >= 4, product.words.contains(where: { $0.count > ingredient.joined.count && $0.hasSuffix(ingredient.joined) }) {
            return 45
        }

        // Typos and other spellings ("Jogurt" for "Joghurt")
        let shorterLength = min(product.joined.count, ingredient.joined.count)
        let allowedDistance = shorterLength >= 8 ? 2 : (shorterLength >= 5 ? 1 : 0)
        if allowedDistance > 0, levenshteinDistance(product.joined, ingredient.joined, limit: allowedDistance) <= allowedDistance {
            return 40
        }
        return 0
    }

    /// A word without the usual English and German plural and adjective endings, for comparing words:
    /// "Zwiebeln" → "zwiebel", "tomatoes" → "tomato", "getrockneter" and "getrocknet" → "getrocknet".
    /// Both sides of a comparison are stemmed, so stems don't need to be real words.
    /// Endings are removed until none is left, so words that differ by one ending get the same stem
    /// ("champignons" → "champignon" → "champigno", and "champignon" → "champigno").
    static func stem(_ word: String) -> String {
        let irregular = ["eier": "ei", "eiern": "ei", "leaves": "leaf", "knives": "knife", "loaves": "loaf"]
        if let stem = irregular[word] { return stem }
        var current = word
        while let shorter = strippingEnding(current) {
            current = shorter
        }
        return current
    }

    private static func strippingEnding(_ word: String) -> String? {
        guard word.count > 3 else { return nil }
        for suffix in ["oes", "ies", "ern", "er", "es", "en", "em", "n", "s", "e"] where word.hasSuffix(suffix) {
            let stem = String(word.dropLast(suffix.count))
            if stem.count >= 3 {
                switch suffix {
                case "ies": return stem + "y"
                case "oes": return stem + "o"
                default: return stem
                }
            }
        }
        return nil
    }

    /// The Levenshtein distance between two strings, or `limit + 1` once it exceeds `limit`.
    static func levenshteinDistance(_ lhs: String, _ rhs: String, limit: Int) -> Int {
        let a = Array(lhs)
        let b = Array(rhs)
        if abs(a.count - b.count) > limit { return limit + 1 }
        if a.isEmpty || b.isEmpty { return max(a.count, b.count) }
        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            current[0] = i
            var rowMinimum = current[0]
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
                rowMinimum = min(rowMinimum, current[j])
            }
            if rowMinimum > limit { return limit + 1 }
            swap(&previous, &current)
        }
        return previous[b.count]
    }
}

// MARK: - Quantity units

extension RecipeImportMapper {
    /// Finds the Grocy quantity unit for a unit from a website, by its name or plural name,
    /// or by any spelling of the same known unit (so "EL" finds a unit named "Esslöffel" or "Tablespoon").
    func matchQuantityUnit(for unit: String, knownUnit: KnownIngredientUnit?) -> MDQuantityUnit? {
        quantityUnitMatch(for: unit, knownUnit: knownUnit)?.unit
    }

    /// The quantity unit for a unit from a website, and how sure the match is.
    ///
    /// Exact: the name or plural name, any spelling of the same known unit ("g" finds "Gramm" or "grams"),
    /// or a word of the unit's name ("g" finds "Gramm (g)"). Suggested: the same word stem ("Dosen" finds "Dose")
    /// or an abbreviation of the name ("Scheib" finds "Scheibe").
    func quantityUnitMatch(for unit: String, knownUnit: KnownIngredientUnit?) -> (unit: MDQuantityUnit, quality: IngredientMatchQuality)? {
        let token = unit.normalizedUnitToken
        guard !token.isEmpty else { return nil }
        let activeUnits = quantityUnits.filter(\.active)
        let spellings = Set([token] + (knownUnit?.aliases ?? []))

        func names(of quantityUnit: MDQuantityUnit) -> [String] {
            [quantityUnit.name, quantityUnit.namePlural].map(\.normalizedUnitToken).filter { !$0.isEmpty }
        }

        if let direct = activeUnits.first(where: { names(of: $0).contains(token) }) {
            return (direct, .exact)
        }
        if let known = activeUnits.first(where: { !spellings.isDisjoint(with: names(of: $0)) }) {
            return (known, .exact)
        }
        // Names like "Gramm (g)" or "g (Gramm)"
        if let word = activeUnits.first(where: { quantityUnit in
            names(of: quantityUnit).contains { name in !spellings.isDisjoint(with: Self.unitNameWords(name)) }
        }) {
            return (word, .exact)
        }
        let tokenStem = Self.stem(Self.normalizedName(token))
        if let stemmed = activeUnits.first(where: { names(of: $0).contains { Self.stem(Self.normalizedName($0)) == tokenStem } }) {
            return (stemmed, .suggested)
        }
        if knownUnit == nil, token.count >= 3, let abbreviated = activeUnits.first(where: { names(of: $0).contains { $0.count > token.count && $0.hasPrefix(token) } }) {
            return (abbreviated, .suggested)
        }
        return nil
    }

    /// The words of a unit name, without parentheses and punctuation ("Gramm (g)" → "gramm", "g").
    private static func unitNameWords(_ name: String) -> Set<String> {
        Set(name.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map { String($0).normalizedUnitToken })
    }
}

// MARK: - Names for new units

/// The language of the unit names suggested for new quantity units.
nonisolated enum IngredientUnitLanguage: Sendable {
    case german, english

    /// The language of the person's app settings, for units that are spelled the same in both languages ("g", "ml").
    static var appLanguage: IngredientUnitLanguage {
        let key = UserDefaults.standard.string(forKey: "localizationKey") ?? Locale.current.language.languageCode?.identifier ?? "en"
        return key.hasPrefix("de") ? .german : .english
    }

    /// The language of a recipe's ingredient lines, from the units they use ("EL", "Bund" or "tbsp", "cups").
    static func detect(in lines: [ParsedIngredientLine]) -> IngredientUnitLanguage? {
        var germanCount = 0
        var englishCount = 0
        for line in lines {
            guard let unit = line.unit, let knownUnit = line.knownUnit else { continue }
            switch knownUnit.language(of: unit) {
            case .german: germanCount += 1
            case .english: englishCount += 1
            case nil: break
            }
        }
        if germanCount == englishCount { return nil }
        return germanCount > englishCount ? .german : .english
    }
}

extension KnownIngredientUnit {
    /// The singular and plural name of the unit in a language.
    nonisolated func names(in language: IngredientUnitLanguage) -> (singular: String, plural: String) {
        switch language {
        case .german:
            switch self {
            case .milligram: ("Milligramm", "Milligramm")
            case .gram: ("Gramm", "Gramm")
            case .kilogram: ("Kilogramm", "Kilogramm")
            case .milliliter: ("Milliliter", "Milliliter")
            case .centiliter: ("Zentiliter", "Zentiliter")
            case .deciliter: ("Deziliter", "Deziliter")
            case .liter: ("Liter", "Liter")
            case .teaspoon: ("Teelöffel", "Teelöffel")
            case .tablespoon: ("Esslöffel", "Esslöffel")
            case .cup: ("Tasse", "Tassen")
            case .ounce: ("Unze", "Unzen")
            case .pound: ("Pfund", "Pfund")
            case .fluidOunce: ("Flüssigunze", "Flüssigunzen")
            case .pinch: ("Prise", "Prisen")
            case .dash: ("Schuss", "Schuss")
            case .handful: ("Handvoll", "Handvoll")
            case .piece: ("Stück", "Stück")
            case .clove: ("Zehe", "Zehen")
            case .bunch: ("Bund", "Bund")
            case .sprig: ("Zweig", "Zweige")
            case .slice: ("Scheibe", "Scheiben")
            case .leaf: ("Blatt", "Blätter")
            case .stalk: ("Stange", "Stangen")
            case .can: ("Dose", "Dosen")
            case .jar: ("Glas", "Gläser")
            case .package: ("Packung", "Packungen")
            case .bag: ("Beutel", "Beutel")
            case .cube: ("Würfel", "Würfel")
            case .tub: ("Becher", "Becher")
            }
        case .english:
            switch self {
            case .milligram: ("Milligram", "Milligrams")
            case .gram: ("Gram", "Grams")
            case .kilogram: ("Kilogram", "Kilograms")
            case .milliliter: ("Milliliter", "Milliliters")
            case .centiliter: ("Centiliter", "Centiliters")
            case .deciliter: ("Deciliter", "Deciliters")
            case .liter: ("Liter", "Liters")
            case .teaspoon: ("Teaspoon", "Teaspoons")
            case .tablespoon: ("Tablespoon", "Tablespoons")
            case .cup: ("Cup", "Cups")
            case .ounce: ("Ounce", "Ounces")
            case .pound: ("Pound", "Pounds")
            case .fluidOunce: ("Fluid ounce", "Fluid ounces")
            case .pinch: ("Pinch", "Pinches")
            case .dash: ("Dash", "Dashes")
            case .handful: ("Handful", "Handfuls")
            case .piece: ("Piece", "Pieces")
            case .clove: ("Clove", "Cloves")
            case .bunch: ("Bunch", "Bunches")
            case .sprig: ("Sprig", "Sprigs")
            case .slice: ("Slice", "Slices")
            case .leaf: ("Leaf", "Leaves")
            case .stalk: ("Stalk", "Stalks")
            case .can: ("Can", "Cans")
            case .jar: ("Jar", "Jars")
            case .package: ("Package", "Packages")
            case .bag: ("Bag", "Bags")
            case .cube: ("Cube", "Cubes")
            case .tub: ("Tub", "Tubs")
            }
        }
    }

    /// The language a spelling of this unit belongs to, or `nil` when it's the same in both ("g", "ml").
    nonisolated func language(of spelling: String) -> IngredientUnitLanguage? {
        let token = spelling.normalizedUnitToken
        let germanAbbreviations: Set<String> = ["tl", "el", "essl", "eßl", "stk", "st", "pck", "pkt", "bd", "msp"]
        let englishAbbreviations: Set<String> = ["tsp", "tbsp", "tbs", "oz", "lb", "lbs", "fl oz", "floz", "pc", "pcs", "pkg"]
        let german = names(in: .german)
        let english = names(in: .english)
        let germanNames = Set([german.singular, german.plural].map(\.normalizedUnitToken))
        let englishNames = Set([english.singular, english.plural].map(\.normalizedUnitToken))
        let isGerman = germanAbbreviations.contains(token) || germanNames.contains(token)
        let isEnglish = englishAbbreviations.contains(token) || englishNames.contains(token)
        if isGerman == isEnglish { return nil }
        return isGerman ? .german : .english
    }
}

extension ParsedIngredientLine {
    /// The name and plural name for a new quantity unit for this line's unit:
    /// the full name of a known unit ("TL" → "Teelöffel"), or the unit as written.
    nonisolated func newQuantityUnitNames(language: IngredientUnitLanguage) -> (singular: String, plural: String)? {
        guard let unit, !unit.isEmpty else { return nil }
        if let knownUnit {
            return knownUnit.names(in: knownUnit.language(of: unit) ?? language)
        }
        let name = unit.removingPluralMarker.trimmingTrailingPeriod
        let capitalized = name.prefix(1).uppercased() + name.dropFirst()
        return (capitalized, "")
    }
}
