//
//  HTMLtoAttributedString.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 13.01.23.
//

import Foundation
import WebKit

@Sendable func HTMLtoAttributedString(html: String?) async -> AttributedString {
    if let html = html {
        do {
            let attributedString = try await NSAttributedString.fromHTML(html)
            return AttributedString(attributedString.0)
        } catch {
            return AttributedString(html)
        }
    }
    return AttributedString("")
}
