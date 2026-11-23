//
//  LoginStatusView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.25.
//

import SwiftData
import SwiftUI

struct LoginStatusView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var isDemoMode: Bool = false

    enum LoginState {
        case loading, success, fail, unsupportedVersion
    }

    @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue
    @AppStorage(ServerVersionWarning.storageKey) private var serverVersionWarningShown: String = ""

    @State var loginState: LoginState = .loading
    @State private var isLoading: Bool = true
    @State var errorMessage: String? = nil
    @State var unsupportedVersion: String? = nil

    /// Explains why the server isn't supported: an outdated server should be updated, a newer one hasn't been tested yet.
    private var unsupportedVersionMessage: LocalizedStringKey {
        let serverVersion = grocyVM.systemInfo?.grocyVersion.version ?? "?"
        let supportedVersions = GrocyAPP.supportedVersions.formatted(.list(type: .or))
        switch GrocyAPP.compatibility(of: grocyVM.systemInfo?.grocyVersion.version) {
        case .outdated:
            return
                "This server runs Grocy \(serverVersion). Grocy Mobile requires Grocy \(supportedVersions). Please update your server. You can continue anyway, but many features won't work."
        case .newer:
            return
                "This server runs Grocy \(serverVersion), which hasn't been tested with Grocy Mobile yet. The app supports Grocy \(supportedVersions). You can continue anyway, but some features might not work."
        case .supported, .unknown:
            return
                "The server version \(serverVersion) is currently unsupported by the app. You can use it anyways, but there can be problems."
        }
    }

    private func tryLogin() async {
        isLoading = true
        do {
            if isDemoMode {
                try await grocyVM.checkServer(
                    baseURL: demoServerURL,
                    apiKey: "",
                    useHassIngress: false,
                    hassToken: "",
                    isDemoMode: true,
                    customHeaders: []
                )
            } else if let profile = grocyVM.selectedServerProfile {
                try await grocyVM.checkServer(
                    baseURL: profile.grocyServerURL,
                    apiKey: profile.grocyAPIKey,
                    useHassIngress: profile.useHassIngress,
                    hassToken: profile.hassToken,
                    isDemoMode: false,
                    customHeaders: profile.customHeaders ?? []
                )
            }
            await grocyVM.requestData(additionalObjects: [.current_user])
            grocyVM.selectedServerProfile?.userName = grocyVM.currentUser?.username ?? ""
            grocyVM.selectedServerProfile?.displayName = grocyVM.currentUser?.displayName ?? ""
            if let pictureFileName = grocyVM.currentUser?.pictureFileName,
                let base64Encoded = pictureFileName.data(using: .utf8)?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)),
                let pictureData = try await grocyVM.getUserPicture(fileName: base64Encoded)
            {
                grocyVM.selectedServerProfile?.profilePicture = pictureData
            }
            try grocyVM.selectedServerProfile?.modelContext?.save()
            if GrocyAPP.supportedVersions.contains(grocyVM.systemInfo?.grocyVersion.version ?? "") {
                loginState = .success
                isDemoMode ? grocyVM.setDemoModus() : await grocyVM.setLoginModus()
            } else {
                loginState = .unsupportedVersion
            }
        } catch {
            loginState = .fail
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    var body: some View {
        switch loginState {
        case .loading:
            ProgressView()
                .scaleEffect(2.0, anchor: .center)
                .progressViewStyle(.circular)
                .task({
                    await tryLogin()
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaBar(
                    edge: .bottom,
                    content: {
                        Button(
                            action: {
                                grocyVM.cancelAllURLSessionTasks()
                                dismiss()
                            },
                            label: {
                                Label("Cancel", systemImage: MySymbols.cancel)
                                    .frame(maxWidth: .infinity)
                            }
                        )
                        // Cancelling isn't destructive, so it uses the standard (not a red) glass style.
                        .buttonStyle(.glass)
                        .controlSize(.large)
                    }
                )
        case .success:
            Label("Success", systemImage: MySymbols.success)
                .font(.title2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.green)
        case .fail:
            ContentUnavailableView(
                label: {
                    Text("Connection to server failed.")
                },
                description: {
                    Text(isDemoMode ? demoServerURL : grocyVM.selectedServerProfile?.grocyServerURL ?? "?")
                        .italic()
                    Text(errorMessage ?? "")
                },
                actions: {
                    Button(
                        action: {
                            Task {
                                await tryLogin()
                            }
                        },
                        label: {
                            Label("Try again", systemImage: MySymbols.reload)
                                .symbolEffect(.rotate, isActive: isLoading)
                                .frame(maxWidth: .infinity)
                        }
                    )
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                }
            )
            .background(.red.opacity(colorScheme == .dark ? 0.3 : 1.0))
        case .unsupportedVersion:
            ContentUnavailableView(
                label: {
                    Label("Incompatible server", systemImage: MySymbols.warning)
                },
                description: {
                    Text(unsupportedVersionMessage)
                },
                actions: {
                    Button(
                        action: {
                            // The user saw the warning here, so don't repeat it when the app opens.
                            serverVersionWarningShown = ServerVersionWarning.shownKey(
                                appVersion: WhatsNew.appVersion,
                                serverVersion: grocyVM.systemInfo?.grocyVersion.version ?? ""
                            )
                            Task {
                                if isDemoMode {
                                    grocyVM.setDemoModus()
                                } else {
                                    await grocyVM.setLoginModus()
                                }
                            }
                        },
                        label: {
                            HStack(alignment: .center) {
                                Text("Continue anyway")
                                Image(systemName: MySymbols.forward)
                                    .accessibilityHidden(true)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    )
                    .buttonStyle(.glass)
                    .controlSize(.large)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.yellow.opacity(colorScheme == .dark ? 0.3 : 1.0))
        }
    }
}

#Preview("Loading", traits: .previewData) {
    LoginStatusView(loginState: .loading)
}

#Preview("Success", traits: .previewData) {
    LoginStatusView(loginState: .success)
}

#Preview("Fail", traits: .previewData) {
    LoginStatusView(loginState: .fail, errorMessage: "Error message")
}

#Preview("UnsupportedVersion", traits: .previewData) {
    LoginStatusView(loginState: .unsupportedVersion)
}
