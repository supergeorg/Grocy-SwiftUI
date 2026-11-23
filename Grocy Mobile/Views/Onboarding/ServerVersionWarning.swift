//
//  ServerVersionWarning.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 23.11.26.
//

import SwiftUI

/// Warns a user who is already logged in when their server runs a Grocy version the app doesn't support.
///
/// New logins already explain this in `LoginStatusView`. This covers users who stay connected while the app is
/// updated to a version that needs a newer Grocy. The warning never blocks the app, and it's shown once per app
/// version and server version, so it comes back after the next app update or server change if the server is
/// still unsupported.
enum ServerVersionWarning {
    /// The app version and server version the warning was last shown for (`appVersion|serverVersion`).
    static let storageKey = "serverVersionWarningShown"

    nonisolated static func shownKey(appVersion: String, serverVersion: String) -> String {
        "\(appVersion)|\(serverVersion)"
    }

    /// Whether to warn about `serverVersion` in `appVersion`, given the key the warning was last shown for.
    static func shouldWarn(serverVersion: String?, appVersion: String, lastShownKey: String) -> Bool {
        guard let serverVersion, !appVersion.isEmpty else {
            return false
        }
        let compatibility = GrocyAPP.compatibility(of: serverVersion)
        guard compatibility == .outdated || compatibility == .newer else {
            return false
        }
        return lastShownKey != shownKey(appVersion: appVersion, serverVersion: serverVersion)
    }
}

extension View {
    /// Warns once after an update if the connected server's Grocy version isn't supported (see `ServerVersionWarning`).
    func serverVersionWarning() -> some View {
        modifier(ServerVersionWarningModifier())
    }
}

private struct ServerVersionWarningModifier: ViewModifier {
    @Environment(GrocyViewModel.self) private var grocyVM

    @AppStorage(ServerVersionWarning.storageKey) private var lastShownKey: String = ""
    @AppStorage(WhatsNew.storageKey) private var whatsNewLastVersion: String = ""
    @AppStorage("isDemoModus") private var isDemoModus: Bool = false

    @State private var isPresented: Bool = false
    @State private var serverVersion: String = ""

    private var message: LocalizedStringKey {
        let supportedVersions = GrocyAPP.supportedVersions.formatted(.list(type: .or))
        if GrocyAPP.compatibility(of: serverVersion) == .outdated {
            return
                "Your server runs Grocy \(serverVersion). This version of Grocy Mobile requires Grocy \(supportedVersions). Please update your server, otherwise many features won't work."
        } else {
            return
                "Your server runs Grocy \(serverVersion), which hasn't been tested with Grocy Mobile yet. The app supports Grocy \(supportedVersions). Some features might not work."
        }
    }

    func body(content: Content) -> some View {
        content
            // Runs again when What's New is dismissed, so the alert never competes with its sheet.
            .task(id: whatsNewLastVersion) {
                #if DEBUG
                    if UITestConfiguration.isActive { return }
                #endif
                // The demo servers aren't the user's to update.
                guard !isDemoModus else { return }
                await grocyVM.waitForLogin()
                guard !WhatsNew.shouldShow(lastShownVersion: whatsNewLastVersion, appVersion: WhatsNew.appVersion) else { return }
                let version = grocyVM.systemInfo?.grocyVersion.version
                if ServerVersionWarning.shouldWarn(serverVersion: version, appVersion: WhatsNew.appVersion, lastShownKey: lastShownKey), let version {
                    serverVersion = version
                    isPresented = true
                }
            }
            .alert(
                "Unsupported server version",
                isPresented: $isPresented,
                actions: {
                    Button("OK", role: .cancel) {
                        lastShownKey = ServerVersionWarning.shownKey(appVersion: WhatsNew.appVersion, serverVersion: serverVersion)
                    }
                },
                message: {
                    Text(message)
                }
            )
    }
}
