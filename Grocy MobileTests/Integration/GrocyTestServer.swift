//
//  GrocyTestServer.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 11.11.26.
//

import Foundation
import SwiftData
import Testing

@testable import Grocy_Mobile

extension Tag {
    /// Tests that talk to a real Grocy server (see `TestServer/README.md`).
    @Tag static var integration: Self
}

/// Configuration for the Grocy server the integration tests run against.
///
/// Start one with `TestServer/grocy-test-server.sh start`, then pass the URL to the test runner:
/// - command line: `TestServer/run-integration-tests.sh`, or `xcodebuild test` with
///   `TEST_RUNNER_GROCY_TEST_SERVER_URL=http://localhost:9290` in the environment
/// - Xcode: add `GROCY_TEST_SERVER_URL` to the test action's environment variables
///
/// Without `GROCY_TEST_SERVER_URL`, all integration suites are skipped.
enum GrocyTestServer {
    static let urlEnvironmentKey = "GROCY_TEST_SERVER_URL"
    static let apiKeyEnvironmentKey = "GROCY_TEST_API_KEY"
    static let defaultAPIKey = "grocy-mobile-integration-tests"

    static var url: String? {
        guard let value = ProcessInfo.processInfo.environment[urlEnvironmentKey], !value.isEmpty else { return nil }
        return value
    }

    static var apiKey: String {
        ProcessInfo.processInfo.environment[apiKeyEnvironmentKey].flatMap { $0.isEmpty ? nil : $0 } ?? defaultAPIKey
    }

    static var isConfigured: Bool { url != nil }

    static let notConfiguredComment: Comment = "Set GROCY_TEST_SERVER_URL to run integration tests against a Grocy server (see TestServer/README.md)."

    /// A `GrocyViewModel` with empty in-memory stores, logged in to the test server.
    ///
    /// The containers are returned as well, because the view model only holds their contexts.
    @MainActor
    static func makeLoggedInViewModel() async throws -> (viewModel: GrocyViewModel, container: ModelContainer, profileContainer: ModelContainer) {
        let url = try #require(url, notConfiguredComment)

        let container = try ModelContainer(
            for: Schema(PreviewContainer.modelTypes),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let profileContainer = try ModelContainer(
            for: Schema([ServerProfile.self, LoginCustomHeader.self]),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )

        let viewModel = GrocyViewModel(modelContext: container.mainContext, profileModelContext: profileContainer.mainContext)
        try await viewModel.checkServer(baseURL: url, apiKey: apiKey, isDemoMode: false)
        return (viewModel, container, profileContainer)
    }
}
