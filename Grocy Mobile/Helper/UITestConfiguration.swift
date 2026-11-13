//
//  UITestConfiguration.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 13.11.26.
//

import Foundation

#if DEBUG
    /// Lets UI tests run the app against a Grocy test server (see `TestServer/README.md`)
    /// without touching the user's stored data, login or iCloud-synced server profiles.
    ///
    /// Active only in debug builds, and only when the UI test passes `GROCY_UITEST_SERVER_URL`
    /// in the launch environment. Then both SwiftData stores are kept in memory and the app logs in
    /// directly, without creating a `ServerProfile`. The UI test passes `-isLoggedIn YES` and
    /// `-onboardingNeeded NO` as launch arguments, which UserDefaults doesn't persist.
    enum UITestConfiguration {
        static let serverURLKey = "GROCY_UITEST_SERVER_URL"
        static let apiKeyKey = "GROCY_UITEST_API_KEY"

        static var serverURL: String? {
            guard let value = ProcessInfo.processInfo.environment[serverURLKey], !value.isEmpty else { return nil }
            return value
        }

        static var apiKey: String {
            ProcessInfo.processInfo.environment[apiKeyKey] ?? ""
        }

        static var isActive: Bool { serverURL != nil }
    }
#endif
