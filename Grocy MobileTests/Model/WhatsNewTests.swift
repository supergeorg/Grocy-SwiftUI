//
//  WhatsNewTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 18.11.26.
//

import Testing

@testable import Grocy_Mobile

@MainActor
@Suite("What's New")
struct WhatsNewTests {
    @Test("Release keys drop the bug-fix version", arguments: [("3.4.0", "3.4"), ("3.4.12", "3.4"), ("3.4", "3.4"), ("", "")])
    func releaseKey(version: String, expected: String) {
        #expect(WhatsNew.releaseKey(of: version) == expected)
    }

    @Test func showsAfterUpdateFromOlderRelease() {
        #expect(WhatsNew.shouldShow(lastShownVersion: "3.3.1", appVersion: "3.4.0"))
    }

    @Test func showsForUsersFromBeforeWhatsNew() {
        #expect(WhatsNew.shouldShow(lastShownVersion: "", appVersion: "3.4.0"))
    }

    @Test func hiddenOnceShownForTheRelease() {
        #expect(!WhatsNew.shouldShow(lastShownVersion: "3.4.0", appVersion: "3.4.0"))
        #expect(!WhatsNew.shouldShow(lastShownVersion: "3.4.0", appVersion: "3.4.1"))
    }

    @Test func hiddenForReleasesWithoutHighlights() {
        #expect(!WhatsNew.shouldShow(lastShownVersion: "3.4.0", appVersion: "99.0.0"))
    }

    @Test func everyReleaseHasUniqueFeatureIDs() {
        for (release, features) in WhatsNew.releases {
            #expect(Set(features.map(\.id)).count == features.count, "Duplicate feature IDs in \(release)")
        }
    }
}
