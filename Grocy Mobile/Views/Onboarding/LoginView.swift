//
//  LoginStartView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.25.
//

import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    @State private var showAbout: Bool = false
    @State private var showSettings: Bool = false

    @ScaledMetric(relativeTo: .largeTitle) private var logoHeight: CGFloat = Sizes.introductionLogoHeight

    static let features: [IntroductionFeature] = [
        IntroductionFeature(
            symbol: MySymbols.ownServer,
            tint: Color(.GrocyColors.grocyGreen),
            title: "Your own server",
            text: "Connect to your Grocy server with its address and an API key, also through Home Assistant."
        ),
        IntroductionFeature(
            symbol: MySymbols.serverProfiles,
            tint: Color(.GrocyColors.grocyBlue),
            title: "Saved in iCloud",
            text: "Your servers are saved as profiles and synced to your other devices."
        ),
        IntroductionFeature(
            symbol: MySymbols.demoServer,
            tint: .orange,
            title: "Demo server",
            text: "Try the app with sample data. Demo servers are reset regularly, so don't use them for your personal data."
        ),
    ]

    var body: some View {
        IntroductionLayout(
            title: "Connect to Grocy",
            subtitle: "Grocy Mobile is a companion app and needs a running Grocy server.",
            features: Self.features
        ) {
            Image("grocy-logo")
                .resizable()
                .scaledToFit()
                .frame(height: logoHeight)
                .accessibilityLabel("Grocy")
        } actions: {
            NavigationLink(value: LoginDestinationType.ownServer) {
                Label("Own server", systemImage: MySymbols.ownServer)
                    .frame(maxWidth: .infinity)
            }
            .introductionButton(tint: Color(.GrocyColors.grocyGreen))
            .accessibilityLabel("Use your own server")

            NavigationLink(value: LoginDestinationType.demoServer) {
                Label("Demo server", systemImage: MySymbols.demoServer)
                    .frame(maxWidth: .infinity)
            }
            .introductionButton(tint: .orange, isProminent: false)
            .accessibilityLabel("Use demo server")
        }
        .navigationDestination(
            for: LoginDestinationType.self,
            destination: { destination in
                switch destination {
                case .demoServer:
                    LoginDemoServerView()
                case .ownServer:
                    ServerSelectionView()
                }
            }
        )
        .navigationDestination(
            for: ServerProfile.self,
            destination: { serverProfile in
                ServerProfileFormView(serverProfile: serverProfile)
            }
        )
        .navigationDestination(
            for: LoginDestination.self,
            destination: { destination in
                switch destination.type {
                case .demoServer:
                    LoginStatusView(isDemoMode: true)
                case .ownServer:
                    LoginStatusView(isDemoMode: false)
                }
            }
        )
        .toolbar(content: {
            #if os(iOS)
                ToolbarItem(
                    placement: .topBarLeading,
                    content: {
                        Link(
                            destination: URL(string: "https://github.com/supergeorg/Grocy-SwiftUI")!,
                            label: {
                                Label("Github", systemImage: MySymbols.api)
                            }
                        )
                    }
                )
                ToolbarItem(
                    placement: .topBarLeading,
                    content: {
                        Link(
                            destination: URL(string: "https://www.grocy.info")!,
                            label: {
                                // The toolbar already draws the glass; a second glass effect inside it would stack.
                                Label("Grocy", systemImage: MySymbols.website)
                            }
                        )
                    }
                )
                ToolbarItem(
                    placement: .topBarTrailing,
                    content: {
                        // A real button (not a tap gesture), so it has a proper hit area and a VoiceOver label.
                        Button {
                            showAbout.toggle()
                        } label: {
                            Label("About this app", systemImage: MySymbols.info)
                        }
                        .sheet(
                            isPresented: $showAbout,
                            content: {
                                NavigationStack {
                                    AboutView()
                                        .toolbar(content: {
                                            ToolbarItem(
                                                placement: .cancellationAction,
                                                content: {
                                                    Button(
                                                        role: .cancel,
                                                        action: {
                                                            showAbout = false
                                                        }
                                                    )
                                                }
                                            )
                                        })
                                }
                            }
                        )
                    }
                )
                ToolbarItem(
                    placement: .topBarTrailing,
                    content: {
                        Button {
                            showSettings.toggle()
                        } label: {
                            Label("Settings", systemImage: MySymbols.settings)
                        }
                        .sheet(
                            isPresented: $showSettings,
                            content: {
                                NavigationStack {
                                    SettingsView()
                                        .toolbar(content: {
                                            ToolbarItem(
                                                placement: .cancellationAction,
                                                content: {
                                                    Button(
                                                        role: .cancel,
                                                        action: {
                                                            showSettings = false
                                                        }
                                                    )
                                                }
                                            )
                                        })
                                }
                            }
                        )
                    }
                )
            #endif
        })
    }
}

enum LoginDestinationType: Hashable {
    case demoServer
    case ownServer
}

struct LoginDestination: Hashable {
    let id = UUID()
    let type: LoginDestinationType

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LoginDestination, rhs: LoginDestination) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        LoginView()
    }
}
