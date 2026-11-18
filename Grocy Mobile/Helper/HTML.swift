//
//  WebsiteCleaner.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 09.02.26.
//

import Foundation
import SwiftUI
import WebKit

extension String {
    func stripHTML() -> String {
        guard let data = self.data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        guard let attributedString = try? unsafe NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }

        return attributedString.string
    }

    func htmlToAttributedString() -> AttributedString {
        guard let data = self.data(using: .utf8) else {
            return AttributedString(self)
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        guard let nsAttributedString = try? unsafe NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return AttributedString(self)
        }

        return AttributedString(nsAttributedString)
    }

    /// Like `htmlToAttributedString()`, without blocking the main thread.
    func htmlToAttributedStringAsync() async -> AttributedString {
        guard let (nsAttributedString, _) = try? await NSAttributedString.fromHTML(self) else {
            return AttributedString(self)
        }
        return AttributedString(nsAttributedString)
    }

    func removeScriptsAndStyles() -> String {
        var cleaned = self

        // Remove script tags and their content
        cleaned = cleaned.replacingOccurrences(
            of: "<script[^>]*>[\\s\\S]*?</script>",
            with: "",
            options: .regularExpression,
            range: nil
        )

        // Remove style tags and their content
        cleaned = cleaned.replacingOccurrences(
            of: "<style[^>]*>[\\s\\S]*?</style>",
            with: "",
            options: .regularExpression,
            range: nil
        )

        // Remove comments
        cleaned = cleaned.replacingOccurrences(
            of: "<!--[\\s\\S]*?-->",
            with: "",
            options: .regularExpression,
            range: nil
        )

        return cleaned
    }

    func extractImageURL() -> String {
        // Try to find og:image meta tag first
        if let ogImagePattern = try? NSRegularExpression(pattern: "og:image\"\\s+content=\"([^\"]+)\"", options: []) {
            let range = NSRange(self.startIndex..., in: self)
            if let match = ogImagePattern.firstMatch(in: self, options: [], range: range),
                let urlRange = Range(match.range(at: 1), in: self)
            {
                return String(self[urlRange])
            }
        }

        // Fallback: look for image src in common recipe image patterns
        if let imgPattern = try? NSRegularExpression(pattern: "recipe.*?img.*?src=\"([^\"]+)\"", options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let range = NSRange(self.startIndex..., in: self)
            if let match = imgPattern.firstMatch(in: self, options: [], range: range),
                let urlRange = Range(match.range(at: 1), in: self)
            {
                return String(self[urlRange])
            }
        }

        return ""
    }
}

func fetchAndCleanWebsite(from urlString: String) async throws -> String {
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }

    let (data, _) = try await URLSession.shared.data(from: url)
    let html = String(decoding: data, as: UTF8.self)

    // First remove scripts and styles before converting to text
    let cleanedHTML = html.removeScriptsAndStyles()

    // Convert to plain text (removes all HTML tags)
    let plainText = cleanedHTML.stripHTML()

    // Trim whitespace and condense multiple newlines
    let trimmed =
        plainText
        .components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
        .joined(separator: " ")

    return trimmed
}
