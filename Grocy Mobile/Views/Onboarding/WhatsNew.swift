//
//  WhatsNew.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftUI

/// The highlights of each release, shown once after an update (`WhatsNewView`).
///
/// Releases are keyed by major and minor version, so a bug-fix update (3.4.1) shows the highlights of its release (3.4)
/// only if they weren't shown yet. Add the highlights of a new release here, from its changelog in `Changelogs/`.
/// A release without highlights shows nothing.
enum WhatsNew {
    /// The app version whose highlights were last shown, or that was installed fresh.
    static let storageKey = "whatsNewLastVersion"

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    static let releases: [String: [IntroductionFeature]] = [
        "3.4": [
            IntroductionFeature(
                symbol: MySymbols.widgets,
                tint: Color(.GrocyColors.grocyBlue),
                title: "New widgets",
                text: "Widgets for the shopping list, chores and tasks, also on the Lock Screen. The stock widget works better with VoiceOver and larger text."
            ),
            IntroductionFeature(
                symbol: MySymbols.batteries,
                tint: Color(.GrocyColors.grocyGreen),
                title: "Batteries",
                text: "An overview with due filters, charge cycle tracking and a journal with undo."
            ),
            IntroductionFeature(
                symbol: MySymbols.equipment,
                tint: .orange,
                title: "Equipment",
                text: "Read instruction manuals (PDF) and keep notes for your equipment."
            ),
            IntroductionFeature(
                symbol: MySymbols.filter,
                tint: Color(.GrocyColors.grocyTurquoise),
                title: "Filters at a glance",
                text: "A badge shows how many filters are applied."
            ),
            IntroductionFeature(
                symbol: MySymbols.serverOS,
                tint: Color(.GrocyColors.grocyGray),
                title: "Grocy 4.7.1 and iOS 27",
                text: "Support for the newest Grocy versions, built for iOS 27, and fixes for data parsing problems."
            ),
        ],
        "3.5": [
            IntroductionFeature(
                symbol: MySymbols.smartNavigation,
                tint: Color(.GrocyColors.grocyBlue),
                title: "A new navigation on iPhone",
                text: "Choose the smart navigation, your own tabs or the sidebar. Search finds stock, products, recipes and master data."
            ),
            IntroductionFeature(
                symbol: MySymbols.due,
                tint: Color(.GrocyColors.grocyRed),
                title: "Everything that's due",
                text: "Products that are expired, due soon or running low, and due chores, tasks and batteries in one list, with swipe actions."
            ),
            IntroductionFeature(
                symbol: MySymbols.recipe,
                tint: Color(.GrocyColors.grocyGreen),
                title: "Recipes",
                text: "All ingredients with their stock status, a list or gallery layout, and import from websites."
            ),
            IntroductionFeature(
                symbol: MySymbols.cooking,
                tint: .orange,
                title: "Cooking mode",
                text: "Check off the ingredients, follow one step per page, and consume everything when you're done."
            ),
            IntroductionFeature(
                symbol: MySymbols.appleIntelligence,
                tint: Color(.GrocyColors.grocyTurquoise),
                title: "Apple Intelligence",
                text: "Suggestions for the location, product group and unit of new products, and for the products of imported ingredients."
            ),
        ],
    ]

    /// "3.4.1" → "3.4"
    nonisolated static func releaseKey(of version: String) -> String {
        version.split(separator: ".").prefix(2).joined(separator: ".")
    }

    static func features(for version: String) -> [IntroductionFeature] {
        releases[releaseKey(of: version)] ?? []
    }

    /// Whether to show the highlights of `appVersion` to someone who last saw those of `lastShownVersion`.
    /// An empty `lastShownVersion` is a user of a version before What's New existed, so they see it too.
    static func shouldShow(lastShownVersion: String, appVersion: String) -> Bool {
        !appVersion.isEmpty
            && releaseKey(of: lastShownVersion) != releaseKey(of: appVersion)
            && !features(for: appVersion).isEmpty
    }
}
