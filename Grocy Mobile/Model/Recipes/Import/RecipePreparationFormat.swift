//
//  RecipePreparationFormat.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 14.11.26.
//

import Foundation

/// One step of a recipe's preparation.
nonisolated struct RecipePreparationStep: Equatable, Sendable {
    /// The name of the section the step belongs to (e.g. "Dough", "Sauce"), or `nil`.
    var section: String?
    /// A short title of the step, or `nil`.
    var title: String?
    /// The step's instructions as plain text.
    var text: String
}

/// The HTML format the app uses for a recipe's preparation (Grocy's recipe `description`),
/// so it can be split into steps again, e.g. for a step-by-step cooking mode.
///
/// The format is plain HTML, so it renders in Grocy's web UI and can still be edited in the rich text editor:
///
/// ```html
/// <p>An optional introduction.</p>
/// <h3>Section name</h3>          <!-- optional, before each section's list -->
/// <ol>
///   <li><p><strong>Optional step title</strong></p><p>Step text.</p></li>
///   <li><p>Next step.</p></li>
/// </ol>
/// <p><a href="https://example.com/recipe">Source</a></p>
/// ```
///
/// - Each `<li>` of an `<ol>` is one step, numbered across all sections.
/// - An `<h3>` names the section of the `<ol>` that follows it.
/// - Text outside of `<ol>` (introduction, source) is not part of any step.
nonisolated enum RecipePreparationFormat {

    // MARK: Building

    /// Builds the preparation HTML from imported instruction steps.
    static func html(introduction: String? = nil, steps: [RecipePreparationStep], sourceURL: URL? = nil) -> String {
        var parts: [String] = []

        if let introduction = introduction?.strippingHTML.collapsingWhitespace, !introduction.isEmpty {
            parts.append("<p>\(introduction.escapedHTML)</p>")
        }

        // Steps of the same section go into one list
        var currentSection: String?
        var openList = false
        for step in steps {
            if !openList || currentSection != step.section {
                if openList { parts.append("</ol>") }
                if let section = step.section, !section.isEmpty {
                    parts.append("<h3>\(section.escapedHTML)</h3>")
                }
                parts.append("<ol>")
                openList = true
                currentSection = step.section
            }
            var item = "<li>"
            if let title = step.title, !title.isEmpty {
                item += "<p><strong>\(title.escapedHTML)</strong></p>"
            }
            let paragraphs = step.text
                .components(separatedBy: "\n")
                .map(\.collapsingWhitespace)
                .filter { !$0.isEmpty }
            item += paragraphs.map { "<p>\($0.escapedHTML)</p>" }.joined()
            item += "</li>"
            parts.append(item)
        }
        if openList { parts.append("</ol>") }

        if let sourceURL {
            let link = sourceURL.absoluteString.escapedHTML
            let host = (sourceURL.host() ?? sourceURL.absoluteString).escapedHTML
            parts.append("<p><a href=\"\(link)\">\(host)</a></p>")
        }

        return parts.joined(separator: "\n")
    }

    /// Converts the instructions of a parsed website recipe into steps.
    ///
    /// Websites sometimes put all instructions into one text. Such a text is split at its line breaks,
    /// so each paragraph becomes a step.
    static func steps(from instructions: [InstructionStep]) -> [RecipePreparationStep] {
        instructions.flatMap { instruction -> [RecipePreparationStep] in
            let text = instruction.text.strippingHTML
            let title = instruction.name?.strippingHTML.collapsingWhitespace
            let paragraphs = text
                .components(separatedBy: .newlines)
                .map(\.collapsingWhitespace)
                .filter { !$0.isEmpty }

            if instructions.count == 1, paragraphs.count > 1 {
                return paragraphs.map { RecipePreparationStep(section: instruction.sectionName, title: nil, text: $0) }
            }
            guard !paragraphs.isEmpty else { return [] }
            return [
                RecipePreparationStep(
                    section: instruction.sectionName?.strippingHTML.collapsingWhitespace,
                    title: title == paragraphs.joined(separator: " ") ? nil : title,
                    text: paragraphs.joined(separator: "\n")
                )
            ]
        }
    }

    // MARK: Splitting

    /// Splits preparation HTML into its steps.
    ///
    /// Each `<li>` of an `<ol>` is one step. HTML without an `<ol>` (e.g. written in Grocy's web UI)
    /// is split into its paragraphs instead, so every recipe can be shown step by step.
    static func steps(fromHTML html: String) -> [RecipePreparationStep] {
        let listSteps = orderedListSteps(in: html)
        if !listSteps.isEmpty { return listSteps }

        return blocks(in: html, tags: ["p", "div", "li"])
            .map { $0.strippingHTML.collapsingWhitespace }
            .filter { !$0.isEmpty }
            .map { RecipePreparationStep(section: nil, title: nil, text: $0) }
    }

    private static func orderedListSteps(in html: String) -> [RecipePreparationStep] {
        // Headings and ordered lists, in the order they appear
        let pattern = #"<h[1-6][^>]*>([\s\S]*?)</h[1-6]>|<ol[^>]*>([\s\S]*?)</ol>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        let nsHTML = html as NSString

        var steps: [RecipePreparationStep] = []
        var section: String?
        for match in regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length)) {
            if match.range(at: 1).location != NSNotFound {
                let heading = nsHTML.substring(with: match.range(at: 1)).strippingHTML.collapsingWhitespace
                section = heading.isEmpty ? nil : heading
            } else if match.range(at: 2).location != NSNotFound {
                let list = nsHTML.substring(with: match.range(at: 2))
                for item in blocks(in: list, tags: ["li"]) {
                    if let step = step(fromListItem: item, section: section) {
                        steps.append(step)
                    }
                }
            }
        }
        return steps
    }

    private static func step(fromListItem item: String, section: String?) -> RecipePreparationStep? {
        var title: String?
        var body = item
        // A leading "<p><strong>Title</strong></p>" is the step's title
        let titlePattern = #"^\s*<p[^>]*>\s*<(strong|b)>([\s\S]*?)</(strong|b)>\s*</p>"#
        if let regex = try? NSRegularExpression(pattern: titlePattern, options: .caseInsensitive),
            let match = regex.firstMatch(in: item, range: NSRange(location: 0, length: (item as NSString).length))
        {
            let nsItem = item as NSString
            title = nsItem.substring(with: match.range(at: 2)).strippingHTML.collapsingWhitespace
            body = nsItem.substring(from: match.range.location + match.range.length)
        }

        let paragraphs = blocks(in: body, tags: ["p"])
        let lines = (paragraphs.isEmpty ? [body] : paragraphs)
            .map { $0.strippingHTML.collapsingWhitespace }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty || title?.isEmpty == false else { return nil }
        return RecipePreparationStep(section: section, title: title?.isEmpty == true ? nil : title, text: lines.joined(separator: "\n"))
    }

    /// The inner HTML of every element with one of `tags`, in document order.
    private static func blocks(in html: String, tags: [String]) -> [String] {
        let names = tags.joined(separator: "|")
        let pattern = "<(\(names))(?:\\s[^>]*)?>([\\s\\S]*?)</\\1>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        let nsHTML = html as NSString
        return regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length)).map {
            nsHTML.substring(with: $0.range(at: 2))
        }
    }
}

nonisolated extension String {
    /// Escapes the characters that have a meaning in HTML.
    var escapedHTML: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
