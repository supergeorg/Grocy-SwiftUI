//
//  ServerCompatibilityTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 23.11.26.
//

import Testing

@testable import Grocy_Mobile

@MainActor
@Suite("Server compatibility")
struct ServerCompatibilityTests {
    @Test func onlyGrocy471IsSupported() {
        #expect(GrocyAPP.supportedVersions == ["4.7.1"])
    }

    @Test("Supported versions", arguments: GrocyAPP.supportedVersions)
    func supported(version: String) {
        #expect(GrocyAPP.compatibility(of: version) == .supported)
    }

    @Test("Older servers must be updated", arguments: ["4.7.0", "4.6.0", "4.4.0", "3.3.2", "4.7.0.1"])
    func outdated(version: String) {
        #expect(GrocyAPP.compatibility(of: version) == .outdated)
    }

    @Test("Newer servers aren't tested yet", arguments: ["4.7.2", "4.8.0", "4.10.0", "5.0.0"])
    func newer(version: String) {
        #expect(GrocyAPP.compatibility(of: version) == .newer)
    }

    @Test("Unreadable versions", arguments: [nil, "", "?", "unknown"] as [String?])
    func unknown(version: String?) {
        #expect(GrocyAPP.compatibility(of: version) == .unknown)
    }
}
