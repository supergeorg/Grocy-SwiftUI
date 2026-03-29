//
//  CategoryMatcher.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.12.25.
//

import Foundation
import FoundationModels

// MARK: - Protocol Definition

/// Protocol for types that can be matched against by the AI categorizer
/// Note: Properties must be nonisolated to avoid actor isolation issues
/// Conforming types don't need to be Sendable; the matcher handles non-Sendable types like SwiftData models
public protocol Categorizable {
    /// The display name used for AI matching
    nonisolated var categoryName: String { get }
}

// MARK: - Category Matcher

/// A type-safe, concurrent-friendly category matcher using Apple's Foundation Models
public actor AICategoryMatcher {

    // MARK: - Error Types

    public enum MatchError: Error, Sendable {
        case modelUnavailable
        case noCategories
        case matchFailed(word: String, reason: String)
        case invalidResponse
        case schemaCreationFailed
        case lowConfidence(word: String, confidence: Double, threshold: Double)
    }

    // MARK: - Configuration

    public struct Configuration: Sendable {
        public let temperature: Double
        public let includeExamples: Bool
        public let fallbackToFuzzyMatch: Bool
        public let minimumConfidence: Double

        public init(
            temperature: Double = 0.1,
            includeExamples: Bool = true,
            fallbackToFuzzyMatch: Bool = true,
            minimumConfidence: Double = 0.0
        ) {
            self.temperature = temperature
            self.includeExamples = includeExamples
            self.fallbackToFuzzyMatch = fallbackToFuzzyMatch
            self.minimumConfidence = min(max(minimumConfidence, 0.0), 1.0) // Clamp between 0-1
        }

        public static var `default`: Configuration {
            Configuration()
        }

        /// Configuration that only accepts high-confidence matches (0.8+)
        public static var highConfidenceOnly: Configuration {
            Configuration(fallbackToFuzzyMatch: false, minimumConfidence: 0.8)
        }
    }

    // MARK: - Properties

    private let configuration: Configuration
    private let session: LanguageModelSession

    // MARK: - Initialization

    public init(configuration: Configuration = .default) {
        self.configuration = configuration

        let instructions = """
            You are a precise category classifier. Your task is to match a given word or phrase 
            to the most appropriate category from a provided list.

            CRITICAL Rules:
            1. ONLY match if there is a clear semantic or linguistic connection
            2. Respond with the EXACT category string from the list
            3. Include all prefixes, numbers, and special characters exactly as shown
            4. Do not modify, simplify, or paraphrase category names
            5. If no good match exists, return the closest match but set confidence < 0.5
            6. Calculate confidence based on match quality:
               - 0.9-1.0: Exact or near-exact match, very high semantic relevance
               - 0.7-0.89: Clear semantic match with minor differences
               - 0.5-0.69: Weak semantic connection but reasonable match
               - 0.0-0.49: Very weak or forced match, likely incorrect
            7. Return BOTH category name AND confidence score
            """

        self.session = LanguageModelSession { instructions }
    }

    // MARK: - Public Methods

    /// Match a word to the most appropriate category from the provided list
    /// - Parameters:
    ///   - word: The word or phrase to categorize
    ///   - categories: Array of categorizable objects to match against
    /// - Returns: The matched category object
    /// - Throws: MatchError if matching fails or confidence is too low
    public func match<T: Categorizable>(word: String, in categories: [T]) async throws -> T {
        guard SystemLanguageModel.default.isAvailable else {
            throw MatchError.modelUnavailable
        }

        guard !categories.isEmpty else {
            throw MatchError.noCategories
        }

        // Extract category names - now safe with nonisolated protocol requirement
        let categoryNames = categories.map { $0.categoryName }
        let result = try await performMatch(word: word, categoryNames: categoryNames)

        // Check confidence if minimum threshold is set
        if configuration.minimumConfidence > 0.0 {
            if result.confidence < configuration.minimumConfidence {
                throw MatchError.lowConfidence(
                    word: word,
                    confidence: result.confidence,
                    threshold: configuration.minimumConfidence
                )
            }
        }

        // Find the exact category object
        guard
            let category = categories.first(where: {
                $0.categoryName.lowercased() == result.category.lowercased()
            })
        else {
            if configuration.fallbackToFuzzyMatch {
                return try fuzzyMatch(matchedName: result.category, in: categories)
            }
            throw MatchError.matchFailed(
                word: word,
                reason: "Matched '\(result.category)' not found in category list"
            )
        }

        return category
    }

    /// Batch match multiple words to categories (sequential)
    /// - Parameters:
    ///   - words: Array of words to categorize
    ///   - categories: Array of categorizable objects to match against
    /// - Returns: Dictionary mapping words to their matched categories
    public func matchBatch<T: Categorizable>(
        words: [String],
        in categories: [T]
    ) async throws -> [String: T] {
        var results: [String: T] = [:]

        for word in words {
            let category = try await match(word: word, in: categories)
            results[word] = category
        }

        return results
    }

//    /// Match multiple words concurrently (faster but uses more resources)
//    /// - Parameters:
//    ///   - words: Array of words to categorize
//    ///   - categories: Array of categorizable objects to match against
//    /// - Returns: Dictionary mapping words to their matched categories
//    public func matchConcurrently<T: Categorizable>(
//        words: [String],
//        in categories: [T]
//    ) async throws -> [String: T] {
//        try await withThrowingTaskGroup(of: (String, T).self) { group in
//            for word in words {
//                group.addTask {
//                    let category = try await self.match(word: word, in: categories)
//                    return (word, category)
//                }
//            }
//
//            var results: [String: T] = [:]
//            for try await (word, category) in group {
//                results[word] = category
//            }
//            return results
//        }
//    }

    // MARK: - Public Types

    /// Result from matching operations - contains only Sendable data
    public struct MatchResultInfo: Sendable {
        public let categoryName: String
        public let confidence: Double
    }

    // MARK: - Private Types

    private struct MatchResult {
        let category: String
        let confidence: Double
    }

    // MARK: - Private Methods

    private func performMatch(
        word: String,
        categoryNames: [String]
    ) async throws -> MatchResult {
        let schema = try buildSchema()
        let prompt = buildPrompt(word: word, categoryNames: categoryNames)
        let options = GenerationOptions(temperature: configuration.temperature)

        let response = try await session.respond(
            to: prompt,
            schema: schema,
            options: options
        )

        guard let category = try? response.content.value(String.self, forProperty: "category") else {
            throw MatchError.invalidResponse
        }

        let confidence: Double
        if let rawConfidence = try? response.content.value(Double.self, forProperty: "confidence") {
            confidence = min(max(rawConfidence, 0.0), 1.0) // Clamp between 0-1
        } else {
            confidence = 0.5 // Default confidence if not provided
        }

        return MatchResult(
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            confidence: confidence
        )
    }

    private func buildSchema() throws -> GenerationSchema {
        let categorySchema = DynamicGenerationSchema(
            name: "CategoryResult",
            description: "The matched category result with confidence score",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "category",
                    description: "The exact category string from the provided list",
                    schema: DynamicGenerationSchema(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "confidence",
                    description: "Confidence score for the match (0.0 to 1.0, where 1.0 is highest confidence)",
                    schema: DynamicGenerationSchema(type: Double.self)
                )
            ]
        )

        do {
            return try GenerationSchema(root: categorySchema, dependencies: [])
        } catch {
            throw MatchError.schemaCreationFailed
        }
    }

    private func buildPrompt(word: String, categoryNames: [String]) -> String {
        var prompt = """
            Word to classify: "\(word)"

            Available categories:
            \(categoryNames.map { "- \($0)" }.joined(separator: "\n"))

            Task:
            1. Determine if there is a meaningful semantic match between the word and any category
            2. If there is a good match, return the category name
            3. Calculate your confidence (0.0 to 1.0) based on how certain you are:
               - High confidence (0.8+): Clear match or strong semantic relationship
               - Medium confidence (0.5-0.79): Reasonable match but some uncertainty
               - Low confidence (below 0.5): Weak or forced match
            4. Return BOTH the category and your confidence level

            Return the exact category name including all prefixes, numbers, and special characters.
            """

        if configuration.includeExamples && categoryNames.count >= 3 {
            let examples = categoryNames.prefix(3)
            prompt += """

            Examples of confident matches:
            \(examples.map { "- \"\($0.lowercased())\" → \($0) (confidence: 0.95)" }.joined(separator: "\n"))

            Examples of weak matches:
            - \"random-text\" → (no good match, confidence would be < 0.3)
            """
        }

        return prompt
    }

    private func fuzzyMatch<T: Categorizable>(matchedName: String, in categories: [T]) throws -> T {
        // Try exact substring match
        if let match = categories.first(where: {
            $0.categoryName.lowercased().contains(matchedName.lowercased())
        }) {
            return match
        }

        // Try reverse substring match
        if let match = categories.first(where: {
            matchedName.lowercased().contains($0.categoryName.lowercased())
        }) {
            return match
        }

        // Try matching without numeric prefixes
        let cleanedMatch = matchedName.replacingOccurrences(
            of: "^[0-9]+\\s*",
            with: "",
            options: .regularExpression
        )

        if let match = categories.first(where: {
            let cleanedCategory = $0.categoryName.replacingOccurrences(
                of: "^[0-9]+\\s*",
                with: "",
                options: .regularExpression
            )
            return cleanedCategory.lowercased() == cleanedMatch.lowercased()
        }) {
            return match
        }

        throw MatchError.matchFailed(
            word: matchedName,
            reason: "No fuzzy match found"
        )
    }
}

// MARK: - Convenience Extensions
extension AICategoryMatcher {
    /// Match using category names only - safe for passing across actor boundaries
    /// Extract category names before calling this method to avoid Sendable issues
    public func matchByNames(
        word: String,
        categoryNames: [String]
    ) async throws -> MatchResultInfo {
        let start = Date()
        let result = try await performMatch(word: word, categoryNames: categoryNames)
        let duration = Date().timeIntervalSince(start)

        print(unsafe "✅ Matched '\(word)' → '\(result.category)' in \(String(format: "%.2f", duration))s")

        return MatchResultInfo(categoryName: result.category, confidence: result.confidence)
    }
}
