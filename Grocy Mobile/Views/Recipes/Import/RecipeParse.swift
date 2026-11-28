//
//  RecipeParse.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 25.04.26.
//

import Foundation

// MARK: - Models

/// A recipe parsed from schema.org/Recipe JSON-LD.
/// All fields are optional except `name` — every other field degrades gracefully
/// when missing or malformed in the source data.
public struct JSONParsedRecipe: Sendable {

    // MARK: Thing properties
    public let name: String
    /// The recipe's description, without sentences the page doesn't show (see `RecipeParser.shownDescription`).
    public var schemaDescription: String?
    public let url: URL?
    /// From the recipe's `image`, or the page's `og:image` when the recipe has none.
    public var image: URL?

    // MARK: CreativeWork properties
    public let author: String?
    public let datePublished: String?
    public let dateModified: String?
    public let keywords: [String]  // empty when absent
    public let video: VideoInfo?

    // MARK: HowTo properties
    public let prepTime: IsoDuration?
    public let cookTime: IsoDuration?
    public let performTime: IsoDuration?  // active cooking time, distinct from prepTime
    public let totalTime: IsoDuration?
    public let cookingMethod: String?

    // MARK: Recipe-specific properties
    public let recipeYield: String?
    public let recipeIngredient: [Ingredient]  // empty when absent
    public let recipeInstructions: [InstructionStep]  // empty when absent
    public let recipeCategory: String?
    public let recipeCuisine: String?
    public let suitableForDiet: [DietType]  // empty when absent; unknown values preserved
    public let nutrition: NutritionInfo?
    public let aggregateRating: AggregateRating?
}

// MARK: - Supporting Types

// MARK: IsoDuration

/// Parsed ISO 8601 duration (e.g. "PT1H30M", "P0DT0H10M").
/// Returns `nil` from the failable init rather than crashing on bad input.
public struct IsoDuration: Sendable {
    public let totalMinutes: Int

    /// Returns `nil` for any string that doesn't contain a recognisable duration.
    public init?(iso8601 string: String) {
        var minutes = 0
        var current = ""
        for ch in string {
            if ch.isNumber {
                current.append(ch)
            } else if ch == "H" {
                minutes += (Int(current) ?? 0) * 60
                current = ""
            } else if ch == "M" {
                minutes += Int(current) ?? 0
                current = ""
            } else {
                current = ""
            }
        }
        guard minutes > 0 else { return nil }
        totalMinutes = minutes
    }

    /// Human-readable, e.g. "1 h 30 min" or "20 min".
    public var formatted: String {
        guard totalMinutes >= 60 else { return "\(totalMinutes) min" }
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return m > 0 ? "\(h) h \(m) min" : "\(h) h"
    }
}

extension IsoDuration: CustomStringConvertible {
    public var description: String { formatted }
}

// MARK: Ingredient

/// An ingredient — plain text or a structured schema.org PropertyValue.
/// Unrecognised structures fall back to `.text` with whatever string content is available.
nonisolated public enum Ingredient: Sendable {
    case text(String)
    case structured(value: String, name: String, unitCode: String?)

    public var displayText: String {
        switch self {
        case .text(let s):
            return s
        case .structured(let value, let name, let unit):
            return [value, unit, name]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }
}

// MARK: InstructionStep

/// A single instruction step, flattened from HowToStep / HowToSection / plain text.
nonisolated public struct InstructionStep: Sendable {
    public let position: Int
    public let sectionName: String?  // non-nil when the step belongs to a named HowToSection
    public let name: String?
    public let text: String
    public let imageURL: URL?
    public let url: URL?
}

// MARK: NutritionInfo

/// Full schema.org NutritionInformation. Every field is optional;
/// values are kept as raw strings because sites format them inconsistently
/// (e.g. "240 calories", "240 kcal", "240").
public struct NutritionInfo: Sendable {
    public let servingSize: String?
    public let calories: String?
    public let proteinContent: String?
    public let fatContent: String?
    public let saturatedFatContent: String?
    public let unsaturatedFatContent: String?
    public let transFatContent: String?
    public let carbohydrateContent: String?
    public let fiberContent: String?
    public let sugarContent: String?
    public let sodiumContent: String?
    public let cholesterolContent: String?

    /// `true` only when every field is nil — lets callers skip rendering an empty section.
    public var isEmpty: Bool {
        [
            servingSize, calories, proteinContent, fatContent, saturatedFatContent,
            unsaturatedFatContent, transFatContent, carbohydrateContent, fiberContent,
            sugarContent, sodiumContent, cholesterolContent,
        ].allSatisfy { $0 == nil }
    }
}

// MARK: AggregateRating

/// schema.org AggregateRating. `ratingValue` is the only required field;
/// all others default sensibly when missing.
public struct AggregateRating: Sendable {
    public let ratingValue: Double
    public let ratingCount: Int  // 0 when not provided
    public let reviewCount: Int  // 0 when not provided
    public let bestRating: Double  // defaults to 5 per schema.org
    public let worstRating: Double  // defaults to 0 per schema.org
}

// MARK: VideoInfo

/// schema.org VideoObject — fields relevant to recipe pages.
public struct VideoInfo: Sendable {
    public let name: String?
    public let thumbnailURL: URL?
    public let contentURL: URL?
    public let embedURL: URL?
    public let duration: IsoDuration?
    public let uploadDate: String?
}

// MARK: DietType

/// A dietary restriction/guideline from schema.org RestrictedDiet.
/// Unknown values (new schema additions, typos, site-specific strings) are
/// preserved in the `.unknown` case instead of being silently dropped.
public enum DietType: Sendable, Hashable {
    case diabeticDiet
    case glutenFreeDiet
    case halalDiet
    case hinduDiet
    case kosherDiet
    case lowCalorieDiet
    case lowFatDiet
    case lowLactoseDiet
    case lowSaltDiet
    case veganDiet
    case vegetarianDiet
    case unknown(String)  // preserves any value not in the known set

    /// Accepts full URIs ("https://schema.org/VeganDiet") or bare names ("VeganDiet").
    /// Never returns `nil` — unrecognised values become `.unknown(bareName)`.
    public init(rawOrURI string: String) {
        let bare = string.components(separatedBy: "/").last ?? string
        switch bare {
        case "DiabeticDiet": self = .diabeticDiet
        case "GlutenFreeDiet": self = .glutenFreeDiet
        case "HalalDiet": self = .halalDiet
        case "HinduDiet": self = .hinduDiet
        case "KosherDiet": self = .kosherDiet
        case "LowCalorieDiet": self = .lowCalorieDiet
        case "LowFatDiet": self = .lowFatDiet
        case "LowLactoseDiet": self = .lowLactoseDiet
        case "LowSaltDiet": self = .lowSaltDiet
        case "VeganDiet": self = .veganDiet
        case "VegetarianDiet": self = .vegetarianDiet
        default: self = .unknown(bare)
        }
    }

    /// The bare schema.org name, or the raw string for unknown values.
    public var rawValue: String {
        switch self {
        case .diabeticDiet: return "DiabeticDiet"
        case .glutenFreeDiet: return "GlutenFreeDiet"
        case .halalDiet: return "HalalDiet"
        case .hinduDiet: return "HinduDiet"
        case .kosherDiet: return "KosherDiet"
        case .lowCalorieDiet: return "LowCalorieDiet"
        case .lowFatDiet: return "LowFatDiet"
        case .lowLactoseDiet: return "LowLactoseDiet"
        case .lowSaltDiet: return "LowSaltDiet"
        case .veganDiet: return "VeganDiet"
        case .vegetarianDiet: return "VegetarianDiet"
        case .unknown(let s): return s
        }
    }

    public var isKnown: Bool {
        if case .unknown = self { return false }
        return true
    }
}

// MARK: - Errors

public enum RecipeParserError: LocalizedError, Sendable {
    case noRecipeFound
    case invalidJSON(any Error)
    case missingTitle

    public var errorDescription: String? {
        switch self {
        case .noRecipeFound: return "No schema.org Recipe node found in the JSON-LD."
        case .invalidJSON(let e): return "JSON parsing failed: \(e.localizedDescription)"
        case .missingTitle: return "Recipe node is missing a 'name'."
        }
    }
}

// MARK: - Warning Logger

/// Controls how the parser reports unexpected or malformed field values.
/// Defaults to `GrocyLogger.debug`. Swap this out in tests or to route into your own logging system.
/// Example: recipeParserWarnHandler = { MyLogger.warn($0) }
public var recipeParserWarnHandler: @MainActor (String) -> Void = { GrocyLogger.debug("[RecipeParser] \($0)") }

// MARK: - Parser

/// Stateless, Sendable-safe parser. All entry points are static.
public enum RecipeParser {

    // MARK: Private Helpers

    private static func warn(_ field: String, _ detail: String, recipeName: String? = nil) {
        let context = recipeName.map { " in recipe \"\($0)\"" } ?? ""
        recipeParserWarnHandler("Skipping field '\(field)'\(context): \(detail)")
    }

    // MARK: Public API

    /// Extracts all `<script type="application/ld+json">` blocks from `html`
    /// and returns every Recipe node found. Never throws due to a single bad block;
    /// only throws if *no* recipe is found across all blocks.
    public static func parse(html: String) throws -> [JSONParsedRecipe] {
        let blocks = jsonLDBlocks(in: html)
        var recipes = blocks.flatMap { (try? parseJSONString($0)) ?? [] }
        guard !recipes.isEmpty else { throw RecipeParserError.noRecipeFound }
        // Many pages show the recipe's picture as the page's preview picture, even when the JSON-LD has none
        if let pageImage = openGraphImageURL(in: html) {
            for index in recipes.indices where recipes[index].image == nil {
                recipes[index].image = pageImage
            }
        }
        // Many sites fill the description with text for search engines ("Über 26 Bewertungen und für beliebt befunden. Mit ► Portionsrechner"),
        // which the page itself never shows. Only the sentences a reader sees on the page are kept.
        let pageText = visibleText(in: html)
        for index in recipes.indices {
            recipes[index].schemaDescription = shownDescription(recipes[index].schemaDescription, recipeName: recipes[index].name, pageText: pageText)
        }
        return recipes
    }

    /// Parses one or more recipes from a raw JSON-LD string (object or array at root).
    public static func parse(jsonString: String) throws -> [JSONParsedRecipe] {
        try parseJSONString(jsonString)
    }

    /// Fetches `url`, parses the HTML response, and returns all recipes found.
    public static func fetch(from url: URL) async throws -> [JSONParsedRecipe] {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try parse(html: String(decoding: data, as: UTF8.self))
    }

    /// Diagnostic: returns a human-readable trace of what the parser finds at each stage.
    /// Call this when `parse(html:)` throws `.noRecipeFound` to pinpoint the failure.
    public static func diagnose(html: String) -> String {
        var out = ["=== RecipeParser.diagnose ==="]

        let blocks = jsonLDBlocks(in: html)
        out.append("ld+json blocks found: \(blocks.count)")

        for (i, block) in blocks.enumerated() {
            out.append("\n── Block \(i + 1) ──────────────────────")
            out.append(String(block.prefix(300)) + (block.count > 300 ? "…" : ""))

            guard let data = block.data(using: .utf8),
                let raw = try? JSONSerialization.jsonObject(with: data)
            else {
                out.append("  ✗ Could not parse as JSON")
                continue
            }

            let nodes: [JSON]
            if let dict = raw as? JSON {
                nodes = collectNodes(dict)
            } else if let arr = raw as? [JSON] {
                nodes = arr.flatMap { collectNodes($0) }
            } else {
                nodes = []
            }

            if nodes.isEmpty {
                if let dict = raw as? JSON {
                    let top = rawTypeStrings(dict["@type"])
                    let graph = (dict["@graph"] as? [JSON] ?? []).flatMap { rawTypeStrings($0["@type"]) }
                    out.append("  ✗ No Recipe node found")
                    out.append("    top-level @type: \(top.isEmpty   ? "(none)" : top.joined(separator: ", "))")
                    out.append("    @graph @type(s): \(graph.isEmpty ? "(none)" : graph.joined(separator: ", "))")
                } else {
                    out.append("  ✗ No Recipe node found (root is not a JSON object)")
                }
            } else {
                out.append("  ✓ Recipe node(s) found: \(nodes.count)")
                nodes.forEach { out.append("    name: \(($0["name"] as? String) ?? "(missing)")") }
            }
        }

        if blocks.isEmpty {
            out.append("\nHint: no <script type=\"application/ld+json\"> tags matched.")
            let present = html.contains("application/ld+json")
            out.append(
                "Raw search for 'application/ld+json': \(present ? "found — possible regex mismatch" : "not found — JSON-LD may be injected by JavaScript")"
            )
        }

        out.append("\n=== end ===")
        return out.joined(separator: "\n")
    }

    // MARK: HTML Extraction

    private static func jsonLDBlocks(in html: String) -> [String] {
        // Handles: single, double or no quotes (minified pages like Love and Lemons), extra attributes before/after type, any capitalisation
        let pattern = #"<script[^>]+type=["']?application/ld\+json["']?[^>]*>([\s\S]*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        let ns = html as NSString
        return
            regex
            .matches(in: html, range: NSRange(location: 0, length: ns.length))
            .compactMap { m -> String? in
                guard m.numberOfRanges > 1 else { return nil }
                let r = m.range(at: 1)
                guard r.location != NSNotFound else { return nil }
                return ns.substring(with: r).trimmingCharacters(in: .whitespacesAndNewlines)
            }
    }

    /// The page's preview picture (`<meta property="og:image" content="…">`, in either attribute order).
    static func openGraphImageURL(in html: String) -> URL? {
        let patterns = [
            #"<meta[^>]+property=["']og:image(?::url)?["'][^>]*content=["']([^"']+)["']"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]*property=["']og:image(?::url)?["']"#,
        ]
        let ns = html as NSString
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                let match = regex.firstMatch(in: html, range: NSRange(location: 0, length: ns.length)),
                match.range(at: 1).location != NSNotFound
            else { continue }
            let content = ns.substring(with: match.range(at: 1))
                .replacingOccurrences(of: "&amp;", with: "&")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let url = URL(string: content), url.scheme?.hasPrefix("http") == true {
                return url
            }
        }
        return nil
    }

    // MARK: Description

    /// The text a reader sees on the page: without the `<head>`, scripts, styles and tags, lowercased, for comparing with `comparable(_:)`.
    static func visibleText(in html: String) -> String {
        var text = html.replacingOccurrences(of: #"(?is)<head\b.*?</head>"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"(?is)<(script|style|noscript|template|svg)\b[^>]*>.*?</\1>"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        return comparable(text)
    }

    /// The sentences of `description` that the page shows, or `nil` when it shows none of them.
    ///
    /// A description that's only meant for search engines appears in the page's metadata (JSON-LD, `<meta name="description">`)
    /// but not in its text, so this works for any website without knowing its wording.
    /// When the page doesn't even show the recipe's name, its text is probably rendered with JavaScript,
    /// so there's nothing to compare with and the description is kept.
    static func shownDescription(_ description: String?, recipeName: String, pageText: String) -> String? {
        guard let description = description?.strippingHTML.collapsingWhitespace, !description.isEmpty else { return nil }
        let name = comparable(recipeName)
        guard !name.isEmpty, pageText.contains(name) else { return description }
        let shown = sentences(in: description).filter { sentence in
            let text = comparable(sentence)
            return !text.isEmpty && pageText.contains(text)
        }
        return shown.isEmpty ? nil : shown.joined(separator: " ")
    }

    /// Splits text into sentences at `.`, `!` or `?` followed by a space, so decimals like "1.5" stay together.
    static func sentences(in text: String) -> [String] {
        var sentences: [String] = []
        var current = ""
        var previous: Character?
        for character in text {
            if character.isWhitespace, let previous, ".!?".contains(previous) {
                sentences.append(current)
                current = ""
                continue
            }
            current.append(character)
            previous = character
        }
        sentences.append(current)
        return sentences.map(\.collapsingWhitespace).filter { !$0.isEmpty }
    }

    /// Text without tags and entities, with single spaces, lowercased and without punctuation at the ends,
    /// so a sentence matches the page however its HTML is laid out.
    private static func comparable(_ text: String) -> String {
        text.strippingHTML.collapsingWhitespace.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".!?…:;, "))
    }

    // MARK: JSON Parsing

    private static func parseJSONString(_ string: String) throws -> [JSONParsedRecipe] {
        guard let data = string.data(using: .utf8) else { return [] }
        let raw: Any
        do { raw = try JSONSerialization.jsonObject(with: data) } catch { throw RecipeParserError.invalidJSON(error) }

        let nodes: [JSON]
        if let dict = raw as? JSON {
            nodes = collectNodes(dict)
        } else if let arr = raw as? [JSON] {
            nodes = arr.flatMap { collectNodes($0) }
        } else {
            nodes = []
        }

        guard !nodes.isEmpty else { throw RecipeParserError.noRecipeFound }
        let index = nodesByID(raw)
        // Build each recipe independently; a failure in one doesn't abort the others
        return nodes.compactMap { try? buildRecipe(resolvingImageReferences(in: $0, index: index)) }
    }

    /// Every node with an `@id` in the document, e.g. the ImageObjects of a `@graph`.
    private static func nodesByID(_ raw: Any) -> [String: JSON] {
        var index: [String: JSON] = [:]
        func walk(_ value: Any) {
            if let dict = value as? JSON {
                // A node with more than its `@id` is the definition; `{"@id": …}` alone only refers to it
                if let id = dict["@id"] as? String, dict.count > 1, index[id] == nil {
                    index[id] = dict
                }
                dict.values.forEach(walk)
            } else if let array = value as? [Any] {
                array.forEach(walk)
            }
        }
        walk(raw)
        return index
    }

    /// Replaces references like `"image": {"@id": "…#primaryimage"}` with the node they point to.
    private static func resolvingImageReferences(in recipe: JSON, index: [String: JSON]) -> JSON {
        func resolve(_ value: Any) -> Any {
            if let dict = value as? JSON, dict["url"] == nil, dict["contentUrl"] == nil, let id = dict["@id"] as? String {
                return index[id] ?? dict
            }
            return value
        }
        guard let image = recipe["image"] else { return recipe }
        var resolved = recipe
        if let array = image as? [Any] {
            resolved["image"] = array.map(resolve)
        } else {
            resolved["image"] = resolve(image)
        }
        return resolved
    }

    /// Recursively finds @type == "Recipe" nodes, including inside @graph arrays.
    private static func collectNodes(_ dict: JSON) -> [JSON] {
        var found: [JSON] = []
        if normaliseTypes(dict["@type"]).contains("Recipe") { found.append(dict) }
        // Not `[JSON]`: a graph can hold other values, like the empty array on Love and Lemons, which would hide the whole graph
        if let graph = dict["@graph"] as? [Any] { found += graph.flatMap(collectNodes(in:)) }
        return found
    }

    private static func collectNodes(in value: Any) -> [JSON] {
        if let dict = value as? JSON { return collectNodes(dict) }
        if let array = value as? [Any] { return array.flatMap(collectNodes(in:)) }
        return []
    }

    // MARK: Model Builder

    private static func buildRecipe(_ d: JSON) throws -> JSONParsedRecipe {
        // name is the only hard requirement
        guard let name = string(d["name"]), !name.isEmpty else { throw RecipeParserError.missingTitle }

        return JSONParsedRecipe(
            name: name,
            schemaDescription: string(d["description"]),
            url: anyURL(d["url"] ?? d["mainEntityOfPage"]),
            image: imageURLs(d["image"]).first,
            author: personOrOrgName(d["author"]),
            datePublished: string(d["datePublished"]),
            dateModified: string(d["dateModified"]),
            keywords: keywordList(d["keywords"]),
            video: videoInfo(d["video"]),
            prepTime: isoDuration(d["prepTime"]),
            cookTime: isoDuration(d["cookTime"]),
            performTime: isoDuration(d["performTime"]),
            totalTime: isoDuration(d["totalTime"]),
            cookingMethod: string(d["cookingMethod"]),
            recipeYield: yieldText(d["recipeYield"]),
            recipeIngredient: ingredientList(d["recipeIngredient"]),
            recipeInstructions: instructionList(d["recipeInstructions"]),
            recipeCategory: string(d["recipeCategory"]),
            recipeCuisine: string(d["recipeCuisine"]),
            suitableForDiet: dietList(d["suitableForDiet"]),
            nutrition: nutritionInfo(d["nutrition"]),
            aggregateRating: aggregateRating(d["aggregateRating"])
        )
    }

    // MARK: Type Helpers

    /// Normalises type strings — strips URI prefix so both "Recipe" and
    /// "https://schema.org/Recipe" match as "Recipe".
    private static func normaliseTypes(_ v: Any?) -> [String] {
        rawTypeStrings(v).map { $0.components(separatedBy: "/").last ?? $0 }
    }

    /// Returns raw, un-normalised type strings (used for diagnostics).
    private static func rawTypeStrings(_ v: Any?) -> [String] {
        if let s = v as? String { return [s] }
        if let a = v as? [String] { return a }
        return []
    }

    // MARK: Scalar Helpers

    /// Extracts a non-empty trimmed String from any value, including numeric types.
    /// Sites occasionally encode string fields as numbers (e.g. recipeYield: 4).
    private static func string(_ v: Any?) -> String? {
        let raw: String?
        switch v {
        case let s as String: raw = s
        case let i as Int: raw = String(i)
        case let d as Double: raw = String(d)
        default: raw = nil
        }
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }

    private static func anyDouble(_ v: Any?) -> Double? {
        switch v {
        case let d as Double: return d
        case let i as Int: return Double(i)
        case let s as String: return Double(s.trimmingCharacters(in: .whitespaces))
        default: return nil
        }
    }

    private static func anyInt(_ v: Any?) -> Int? {
        switch v {
        case let i as Int: return i
        case let d as Double: return Int(d)
        case let s as String: return Int(s.trimmingCharacters(in: .whitespaces))
        default: return nil
        }
    }

    // MARK: Field Parsers

    private static func personOrOrgName(_ v: Any?) -> String? {
        if let s = v as? String { return string(s) }
        if let d = v as? JSON { return string(d["name"]) }
        // Array of Person/Organization — take the first name found
        if let a = v as? [Any] {
            return a.compactMap { ($0 as? JSON).flatMap { string($0["name"]) } }.first
        }
        return nil
    }

    private static func anyURL(_ v: Any?) -> URL? {
        if let s = v as? String {
            if let url = URL(string: s) { return url }
            warn("url", "malformed URL string: \"\(s)\"")
            return nil
        }
        if let d = v as? JSON {
            guard let id = d["@id"] as? String else { return nil }
            if let url = URL(string: id) { return url }
            warn("url", "malformed @id URL: \"\(id)\"")
            return nil
        }
        return nil
    }

    private static func imageURLs(_ v: Any?) -> [URL] {
        func single(_ item: Any) -> URL? {
            if let s = item as? String {
                if let url = URL(string: s) { return url }
                warn("image", "malformed image URL: \"\(s)\"")
                return nil
            }
            if let d = item as? JSON {
                let src = (d["url"] as? String) ?? (d["contentUrl"] as? String)
                guard let src else { return nil }
                if let url = URL(string: src) { return url }
                warn("image", "malformed image URL in ImageObject: \"\(src)\"")
                return nil
            }
            return nil
        }
        if let arr = v as? [Any] { return arr.compactMap { single($0) } }
        if let v { return [single(v)].compactMap { $0 } }
        return []
    }

    private static func isoDuration(_ v: Any?) -> IsoDuration? {
        guard let s = v as? String else { return nil }
        if let d = IsoDuration(iso8601: s) { return d }
        warn("duration", "unrecognised ISO 8601 duration: \"\(s)\" — expected format like PT10M or PT1H30M")
        return nil
    }

    private static func yieldText(_ v: Any?) -> String? {
        if let s = v as? String { return string(s) }
        if let a = v as? [Any] {
            // Prefer the most descriptive string, e.g. "4 Portionen" over "4"
            return a.compactMap { string($0 as? String ?? "") }
                .max(by: { $0.count < $1.count })
        }
        if let d = v as? JSON {
            // QuantitativeValue: combine value + unitText
            let val = string(d["value"]) ?? ""
            let unit = string(d["unitText"]) ?? ""
            let combined = [val, unit].filter { !$0.isEmpty }.joined(separator: " ")
            return combined.isEmpty ? nil : combined
        }
        // Numeric yield (e.g. recipeYield: 4)
        if let i = v as? Int { return String(i) }
        if let d = v as? Double { return String(d) }
        return nil
    }

    private static func ingredientList(_ v: Any?) -> [Ingredient] {
        // Schema allows a single Text value as well as an array
        let items: [Any]
        if let arr = v as? [Any] { items = arr } else if let s = v as? String, let t = string(s) { return [.text(t)] } else { return [] }

        return items.compactMap { item -> Ingredient? in
            if let s = item as? String {
                return string(s).map { .text($0) }
            }
            if let d = item as? JSON {
                // PropertyValue: { "@type": "PropertyValue", "value": "1", "name": "egg" }
                guard let name = string(d["name"]) else {
                    let fallback = [d["value"], d["name"]]
                        .compactMap { string($0 as? String ?? "") }
                        .joined(separator: " ")
                    if fallback.isEmpty {
                        warn("recipeIngredient", "PropertyValue has no 'name' and no salvageable text — skipping entry")
                        return nil
                    }
                    warn("recipeIngredient", "PropertyValue missing 'name', salvaged display text: \"\(fallback)\"")
                    return .text(fallback)
                }
                let val = string(d["value"]) ?? ""
                let unit = string(d["unitCode"]) ?? string(d["unitText"])
                return .structured(value: val, name: name, unitCode: unit)
            }
            return nil
        }
    }

    private static func instructionList(_ v: Any?) -> [InstructionStep] {
        guard let raw = v else { return [] }
        var pos = 0
        return flatSteps(raw, section: nil, pos: &pos)
    }

    /// Recursively flattens HowToSection → HowToStep / plain text into [InstructionStep].
    private static func flatSteps(_ raw: Any, section: String?, pos: inout Int) -> [InstructionStep] {
        if let arr = raw as? [Any] {
            return arr.flatMap { flatSteps($0, section: section, pos: &pos) }
        }
        if let d = raw as? JSON {
            // HowToSection — recurse with its name as the section label
            if normaliseTypes(d["@type"]).contains("HowToSection") {
                let secName = string(d["name"])
                // Schema allows "itemListElement" or "step" as child container
                let children = d["itemListElement"] ?? d["step"]
                if let children { return flatSteps(children, section: secName, pos: &pos) }
                return []
            }
            // HowToStep or bare dict — prefer "text", fall back to "name"
            let raw = string(d["text"]) ?? string(d["name"])
            guard let text = raw else { return [] }
            pos += 1
            let stepName = string(d["name"])
            return [
                InstructionStep(
                    position: pos,
                    sectionName: section,
                    name: stepName != text ? stepName : nil,
                    text: text,
                    imageURL: imageURLs(d["image"]).first,
                    url: anyURL(d["url"])
                )
            ]
        }
        if let s = raw as? String, let text = string(s) {
            pos += 1
            return [
                InstructionStep(
                    position: pos,
                    sectionName: section,
                    name: nil,
                    text: text,
                    imageURL: nil,
                    url: nil
                )
            ]
        }
        return []
    }

    private static func nutritionInfo(_ v: Any?) -> NutritionInfo? {
        guard let d = v as? JSON else {
            if v != nil { warn("nutrition", "expected a NutritionInformation object, got \(type(of: v!)) — skipping") }
            return nil
        }
        let info = NutritionInfo(
            servingSize: string(d["servingSize"]),
            calories: string(d["calories"]),
            proteinContent: string(d["proteinContent"]),
            fatContent: string(d["fatContent"]),
            saturatedFatContent: string(d["saturatedFatContent"]),
            unsaturatedFatContent: string(d["unsaturatedFatContent"]),
            transFatContent: string(d["transFatContent"]),
            carbohydrateContent: string(d["carbohydrateContent"]),
            fiberContent: string(d["fiberContent"]),
            sugarContent: string(d["sugarContent"]),
            sodiumContent: string(d["sodiumContent"]),
            cholesterolContent: string(d["cholesterolContent"])
        )
        return info.isEmpty ? nil : info
    }

    private static func aggregateRating(_ v: Any?) -> AggregateRating? {
        guard let d = v as? JSON else { return nil }
        guard let rv = anyDouble(d["ratingValue"]) else {
            warn("aggregateRating", "present but missing or non-numeric 'ratingValue' — skipping")
            return nil
        }
        let best = anyDouble(d["bestRating"]) ?? 5
        let worst = anyDouble(d["worstRating"]) ?? 0
        if rv < worst || rv > best {
            warn("aggregateRating", "ratingValue \(rv) is outside [\(worst), \(best)] — using as-is")
        }
        return AggregateRating(
            ratingValue: rv,
            ratingCount: anyInt(d["ratingCount"]) ?? 0,
            reviewCount: anyInt(d["reviewCount"]) ?? 0,
            bestRating: best,
            worstRating: worst
        )
    }

    private static func videoInfo(_ v: Any?) -> VideoInfo? {
        guard let d = v as? JSON else { return nil }
        let info = VideoInfo(
            name: string(d["name"]),
            thumbnailURL: anyURL(d["thumbnailUrl"] ?? d["thumbnail"]),
            contentURL: anyURL(d["contentUrl"]),
            embedURL: anyURL(d["embedUrl"]),
            duration: isoDuration(d["duration"]),
            uploadDate: string(d["uploadDate"])
        )
        // Suppress empty VideoInfo (dict present but none of the useful fields populated)
        guard
            info.name != nil || info.thumbnailURL != nil
                || info.contentURL != nil || info.embedURL != nil
        else { return nil }
        return info
    }

    private static func keywordList(_ v: Any?) -> [String] {
        if let a = v as? [Any] {
            return a.compactMap { string($0 as? String ?? "") }
        }
        if let s = v as? String {
            return s.split(separator: ",")
                .compactMap { string(String($0)) }
        }
        return []
    }

    private static func dietList(_ v: Any?) -> [DietType] {
        let raw: [String]
        if let s = v as? String {
            raw = [s]
        } else if let a = v as? [String] {
            raw = a
        } else if let a = v as? [Any] {
            raw = a.compactMap { $0 as? String }
        } else {
            return []
        }
        return raw.compactMap { string($0) }.map { s -> DietType in
            let diet = DietType(rawOrURI: s)
            if case .unknown(let val) = diet {
                warn("suitableForDiet", "unknown diet type \"\(val)\" — preserved as .unknown")
            }
            return diet
        }
    }
}

// MARK: - Private typealias

private typealias JSON = [String: Any]

// MARK: - CustomStringConvertible

extension JSONParsedRecipe: CustomStringConvertible {
    public var description: String {
        var lines = ["╔══ \(name) ══"]

        // -- Identity --
        if let d = schemaDescription { lines.append("│ 📝 \(d)") }
        if let u = url { lines.append("│ 🔗 \(u.absoluteString)") }
        if let a = author { lines.append("│ 👤 \(a)") }
        if let p = datePublished { lines.append("│ 📅 Published: \(p)") }
        if let m = dateModified { lines.append("│ 📅 Modified:  \(m)") }
        if let c = recipeCuisine { lines.append("│ 🌍 \(c)") }
        if let c = recipeCategory { lines.append("│ 🏷️  \(c)") }
        if let m = cookingMethod { lines.append("│ 🔥 \(m)") }
        if !suitableForDiet.isEmpty {
            lines.append("│ 🥦 \(suitableForDiet.map(\.rawValue).joined(separator: ", "))")
        }

        // -- Images --
        if let img = image { lines.append("│ 🖼️  \(img.absoluteString)") }

        // -- Video --
        if let v = video {
            lines.append("│")
            lines.append("│ 🎬 Video: \(v.name ?? "(untitled)")")
            if let u = v.contentURL { lines.append("│    Content:   \(u.absoluteString)") }
            if let u = v.embedURL { lines.append("│    Embed:     \(u.absoluteString)") }
            if let u = v.thumbnailURL { lines.append("│    Thumbnail: \(u.absoluteString)") }
            if let d = v.duration { lines.append("│    Duration:  \(d.formatted)") }
            if let p = v.uploadDate { lines.append("│    Uploaded:  \(p)") }
        }

        // -- Times & yield --
        lines += ["│", "│ ⏱️  Times:"]
        if let t = prepTime { lines.append("│    Prep:   \(t.formatted)") }
        if let t = cookTime { lines.append("│    Cook:   \(t.formatted)") }
        if let t = performTime { lines.append("│    Active: \(t.formatted)") }
        if let t = totalTime { lines.append("│    Total:  \(t.formatted)") }
        if let y = recipeYield { lines.append("│    Yield:  \(y)") }

        // -- Ingredients --
        if !recipeIngredient.isEmpty {
            lines += ["│", "│ 🛒 Ingredients:"]
            recipeIngredient.forEach { lines.append("│    • \($0.displayText)") }
        }

        // -- Instructions --
        if !recipeInstructions.isEmpty {
            lines += ["│", "│ 👨\u{200d}🍳 Instructions:"]
            var lastSection: String? = nil
            for step in recipeInstructions {
                if step.sectionName != lastSection, let sec = step.sectionName {
                    lines.append("│    ── \(sec) ──")
                    lastSection = sec
                }
                let prefix = step.name.map { "\($0): " } ?? ""
                lines.append("│    \(step.position). \(prefix)\(step.text)")
                if let img = step.imageURL { lines.append("│       🖼️  \(img.absoluteString)") }
            }
        }

        // -- Nutrition --
        if let n = nutrition {
            lines += ["│", "│ 🥗 Nutrition (per \(n.servingSize ?? "serving")):"]
            let fields: [(String, String?)] = [
                ("Calories", n.calories),
                ("Protein", n.proteinContent),
                ("Fat", n.fatContent),
                ("Sat. Fat", n.saturatedFatContent),
                ("Unsat. Fat", n.unsaturatedFatContent),
                ("Trans Fat", n.transFatContent),
                ("Carbs", n.carbohydrateContent),
                ("Fiber", n.fiberContent),
                ("Sugar", n.sugarContent),
                ("Sodium", n.sodiumContent),
                ("Cholesterol", n.cholesterolContent),
            ]
            for (label, value) in fields where value != nil {
                let padded = (label + ":").padding(toLength: 14, withPad: " ", startingAt: 0)
                lines.append("│    \(padded) \(value!)")
            }
        }

        // -- Rating --
        if let r = aggregateRating {
            lines.append("│")
            let rating = (r.ratingValue * 10).rounded() / 10
            lines.append("│ ⭐ \(rating)/\(Int(r.bestRating)) – \(r.ratingCount) ratings, \(r.reviewCount) reviews")
        }

        // -- Keywords --
        if !keywords.isEmpty {
            lines += ["│", "│ 🔖 \(keywords.joined(separator: ", "))"]
        }

        lines.append("╚══")
        return lines.joined(separator: "\n")
    }
}
