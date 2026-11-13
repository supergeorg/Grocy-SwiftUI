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

    #if os(iOS)
        @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
        @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    #endif

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image("grocy-logo")
                .resizable()
                .scaledToFit()
                .padding()
            ScrollView {
                Text("Welcome to Grocy Mobile")
                    .font(.largeTitle).bold()
                    .multilineTextAlignment(.center)
                Text(
                    "This is a companion app and requires access to a running Grocy instance (for example on your server). If you just want to try the app, use one of the demo servers provided by the Grocy developer. Do not use demo servers for your personal data — they are not persistent."
                )
                .font(.body)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
            }
            .padding(.horizontal)

            Text("Select a server type:")
                .font(.title3)
                .foregroundColor(.primary)
                .padding(.top, 4)

            NavigationLink(
                value: LoginDestinationType.demoServer,
                label: {
                    Label("Demo server", systemImage: "server.rack")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .padding()
                }
            )
            .glassEffect(.regular.tint(.orange).interactive())
            .contentShape(Capsule())
            .accessibilityLabel("Use demo server")

            NavigationLink(
                value: LoginDestinationType.ownServer,
                label: {
                    Label("Own server", systemImage: "house")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .padding()
                }
            )
            .glassEffect(.regular.tint(.GrocyColors.grocyGreen).interactive())
            .contentShape(Capsule())
            .accessibilityLabel("Use your own server")
        }
        .background(Color(.GrocyColors.grocyBlueBackground))
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

#Preview {
    NavigationStack {
        LoginView()
    }
}
