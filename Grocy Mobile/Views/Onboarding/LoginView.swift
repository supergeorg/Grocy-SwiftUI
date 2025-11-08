//
//  LoginView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 18.02.21.
//

import AVFoundation
import SwiftUI

enum LoginViewState {
    case start, demoServer, ownServer, logginIn
}

struct LoginStartView: View {
    @Binding var showDemoServer: Bool
    @Binding var showOwnServer: Bool

    var animation: Namespace.ID

    var body: some View {
        VStack(spacing: 20) {
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

            Button(
                action: {
                    showDemoServer.toggle()
                },
                label: {
                    Label("Demo server", systemImage: "server.rack")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .padding()
                        .glassEffect(.regular.tint(.orange).interactive())
                        .matchedGeometryEffect(id: "demoServer", in: animation)
                }
            )
            .accessibilityLabel("Use demo server")

            Button(
                action: {
                    showOwnServer.toggle()
                },
                label: {
                    Label("Own server", systemImage: "house")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .padding()
                        .glassEffect(.regular.tint(.GrocyColors.grocyGreen).interactive())
                        .matchedGeometryEffect(id: "ownServer", in: animation)
                }
            )
            .accessibilityLabel("Use your own server")
        }
        .padding(10.0)
    }
}

struct LoginDemoServerView: View {
    @Binding var loginViewState: LoginViewState
    @Binding var passDemoMode: Bool?
    @Binding var showDemoServer: Bool
    var animation: Namespace.ID

    @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue

    var body: some View {
        Form {
            Picker(
                selection: $demoServerURL,
                label: Text("Demo server"),
                content: {
                    ForEach(
                        GrocyAPP.DemoServers.allCases,
                        content: { demoServer in
                            Text(demoServer.description).tag(demoServer.rawValue)
                        }
                    )
                }
            )
        }
        .navigationTitle("Demo server")
        .formStyle(.grouped)
        .toolbar(content: {
            ToolbarItem(
                placement: .cancellationAction,
                content: {
                    Button(
                        role: .cancel,
                        action: {
                            showDemoServer = false
                        }
                    )
                }
            )
            ToolbarItem(
                placement: .confirmationAction,
                content: {
                    Button(
                        role: .confirm,
                        action: {
                            passDemoMode = true
                            loginViewState = .logginIn
                        }
                    )
                }
            )
        })
    }
}

struct LoginOwnServerView: View {
    @Binding var loginViewState: LoginViewState
    @Binding var passDemoMode: Bool?
    @Binding var showOwnServer: Bool
    var animation: Namespace.ID

    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""

    // Home Assistant
    @AppStorage("useHassIngress") var useHassIngress: Bool = false
    @AppStorage("hassToken") var hassToken: String = ""

    #if os(iOS)
        @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
        @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

        @State private var isShowingGrocyScanner: Bool = false
        func handleGrocyScan(result: Result<CodeScannerViewLegacy.ScanResult, CodeScannerViewLegacy.ScanError>) {
            self.isShowingGrocyScanner = false
            switch result {
            case .success(let code):
                let grocyServerData = code.string.components(separatedBy: "|")
                guard grocyServerData.count == 2 else { return }

                let serverURL = grocyServerData[0]
                let apiKey = grocyServerData[1]

                if apiKey.count == 50 {
                    grocyServerURL = serverURL
                    grocyAPIKey = apiKey
                    passDemoMode = false
                }
            case .failure(let error):
                print("Scanning failed")
                print(error)
            }
        }

        @State private var isShowingTokenScanner: Bool = false
        func handleTokenScan(result: Result<CodeScannerViewLegacy.ScanResult, CodeScannerViewLegacy.ScanError>) {
            self.isShowingTokenScanner = false
            switch result {
            case .success(let scannedHassToken):
                hassToken = scannedHassToken.string
            case .failure(let error):
                print("Scanning failed")
                print(error)
            }
        }
    #endif

    var body: some View {
        Form {
            Section("Server") {
                MyTextField(
                    textToEdit: $grocyServerURL,
                    description: "Server URL",
                    isCorrect: Binding.constant(true),
                    leadingIcon: "network",
                    helpText: "Server-URL of your Grocy Instance (if you use Home Assistant Ingress, this can be accessed via right click on REST API Browser in the web interface)"
                )
                MyTextField(
                    textToEdit: $grocyAPIKey,
                    description: "Valid API key",
                    isCorrect: Binding.constant(true),
                    leadingIcon: "key",
                    helpText: "API key for the user which is shown in the Manage API keys webview. If none exist, you need to create a new one."
                )
                if let manageKeysURL = URL(string: "\(grocyServerURL)/manageapikeys") {
                    Link(
                        destination: manageKeysURL,
                        label: {
                            Label("Create API key", systemImage: "key")
                        }
                    )
                }
                #if os(iOS)
                    Button(
                        action: {
                            isShowingGrocyScanner.toggle()
                        },
                        label: {
                            Label("QR-Scan", systemImage: MySymbols.qrScan)
                        }
                    )
                    .sheet(
                        isPresented: $isShowingGrocyScanner,
                        content: {
                            CodeScannerViewLegacy(
                                codeTypes: [.qr],
                                scanMode: .once,
                                simulatedData: "http://192.168.178.40:8123/api/hassio_ingress/ckgy-GNrulcboPPwZyCnOn181YpRqOr6vIC8G2lijqU/api|tkYf677yotIwTibP0ko1lZxn8tj4cgoecWBMropiNc1MCjup8p",
                                completion: self.handleGrocyScan
                            )
                        }
                    )
                #endif
            }
            Section("Home Assistant Ingress") {
                MyToggle(isOn: $useHassIngress, description: "Use Home Assistant Ingress", icon: "house")
                if useHassIngress {
                    HStack {
                        MyTextField(
                            textToEdit: $hassToken,
                            description: "Long-Term-Token for Home Assistant",
                            isCorrect: Binding.constant(true),
                            leadingIcon: "key",
                            helpText:
                                "This token has to be generated out of your Home Assistant Web interface. To do this, open your Home Assistant Profile page, scroll down to Long-Lived Access Tokens and create one. Name it and copy the resulting Token in the App or create a QR Code and scan it (iOS)."
                        )
                        #if os(iOS)
                            Button(
                                action: {
                                    isShowingTokenScanner.toggle()
                                },
                                label: {
                                    Image(systemName: MySymbols.qrScan)
                                }
                            )
                            .sheet(
                                isPresented: $isShowingTokenScanner,
                                content: {
                                    CodeScannerViewLegacy(
                                        codeTypes: [.qr],
                                        scanMode: .once,
                                        simulatedData: "670f7d46391db7b42d382ebc9ea667f3aac94eb90219b9e32c7cd71cd37d13833109113270b327fac08d77d9b038a9cb3ab6cfd8dc8d0e3890d16e6434d10b3d",
                                        completion: self.handleTokenScan
                                    )
                                }
                            )
                        #endif
                    }
                }
                Link(
                    destination: URL(string: "https://github.com/supergeorg/Grocy-SwiftUI/blob/main/Guides/Home%20Assistant%20Ingress/HomeAssistantIngressGuide.md")!,
                    label: {
                        Label("Guide (English)", systemImage: "questionmark.circle")
                    }
                )
            }
        }
        .navigationTitle("Own server")
        .formStyle(.grouped)
        .toolbar(content: {
            ToolbarItem(
                placement: .cancellationAction,
                content: {
                    Button(
                        role: .cancel,
                        action: {
                            showOwnServer = false
                        }
                    )
                }
            )
            ToolbarItem(
                placement: .confirmationAction,
                content: {
                    Button(
                        role: .confirm,
                        action: {
                            passDemoMode = false
                            loginViewState = .logginIn
                        }
                    )
                }
            )
        })
    }
}

struct LoginStatusView: View {
    @Binding var loginViewState: LoginViewState
    @Binding var isDemoMode: Bool?

    enum LoginState {
        case loading, success, fail, unsupportedVersion
    }
    @State var loginState: LoginState
    var animation: Namespace.ID

    @Environment(GrocyViewModel.self) private var grocyVM

    @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue
    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""

    @State private var errorMessage: String?
    @State private var unsupportedVersion: String?

    private func tryLogin() async {
        if let isDemoMode = isDemoMode {
            do {
                try await grocyVM.checkServer(baseURL: isDemoMode ? demoServerURL : grocyServerURL, apiKey: isDemoMode ? nil : grocyAPIKey, isDemoMode: isDemoMode)
                if GrocyAPP.supportedVersions.contains(grocyVM.systemInfo?.grocyVersion.version ?? "") {
                    loginState = .success
                    isDemoMode ? grocyVM.setDemoModus() : await grocyVM.setLoginModus()
                } else {
                    loginState = .unsupportedVersion
                }
            } catch {
                loginState = .fail
                errorMessage = error.localizedDescription
            }
        }
    }

    var body: some View {
        Group {
            switch loginState {
            case .loading:
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5, anchor: .center)
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .task({
                            await tryLogin()
                        })
                    Button(
                        "Cancel",
                        action: {
                            grocyVM.cancelAllURLSessionTasks()
                        }
                    )
                    .buttonStyle(BorderButtonStyle())
                }
            case .success:
                Text("Success")
            case .fail:
                VStack {
                    CardView {
                        VStack(alignment: .leading) {
                            Text("Connection to server failed.")
                            ScrollView {
                                Text("Server: \((isDemoMode ?? false) ? demoServerURL : grocyServerURL) \(errorMessage ?? "")")
                            }
                        }
                    }
                    CardView {
                        HStack {
                            Button(
                                "Back",
                                action: {
                                    loginViewState = (isDemoMode ?? false) ? .demoServer : .ownServer
                                }
                            )
                            .buttonStyle(BorderButtonStyle())
                            Button(
                                "Try again",
                                action: {
                                    Task {
                                        await tryLogin()
                                    }
                                }
                            )
                            .buttonStyle(FilledButtonStyle())
                        }
                    }
                }
            case .unsupportedVersion:
                VStack {
                    CardView {
                        Text("The server version \(grocyVM.systemInfo?.grocyVersion.version ?? "?") is currently unsupported by the app. You can use it anyways, but there can be problems.")
                    }
                    HStack {
                        Button(
                            "Back",
                            action: {
                                loginViewState = (isDemoMode ?? false) ? .demoServer : .ownServer
                            }
                        )
                        .buttonStyle(BorderButtonStyle())
                        Button(
                            "Continue anyway",
                            action: {
                                Task {
                                    if isDemoMode ?? false {
                                        grocyVM.setDemoModus()
                                    } else {
                                        await grocyVM.setLoginModus()
                                    }
                                }
                            }
                        )
                        .buttonStyle(FilledButtonStyle())
                    }
                }
            }
        }
        .matchedGeometryEffect(id: "login", in: animation)
    }
}

struct LoginView: View {
    @Namespace private var animation
    @State private var loginViewState: LoginViewState = .start
    @State private var passDemoMode: Bool?

    @State private var showAbout: Bool = false
    @State private var showSettings: Bool = false
    @State private var showDemoServer: Bool = false
    @State private var showOwnServer: Bool = false

    #if os(iOS)
        @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
        @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    #endif

    var body: some View {
        content
            #if os(macOS)
                .frame(minWidth: 500, minHeight: 600)
            #endif
    }

    var content: some View {
        VStack {
            Spacer()
            Image("grocy-logo")
                .resizable()
                .scaledToFit()
                .padding()
            switch loginViewState {
            case .start:
                LoginStartView(showDemoServer: $showDemoServer, showOwnServer: $showOwnServer, animation: animation)
            case .demoServer:
                LoginDemoServerView(loginViewState: $loginViewState, passDemoMode: $passDemoMode, showDemoServer: $showDemoServer, animation: animation)
            case .ownServer:
                LoginOwnServerView(loginViewState: $loginViewState, passDemoMode: $passDemoMode, showOwnServer: $showOwnServer, animation: animation)
            case .logginIn:
                LoginStatusView(loginViewState: $loginViewState, isDemoMode: $passDemoMode, loginState: .loading, animation: animation)
            }
        }
        .background(Color(.GrocyColors.grocyBlueBackground))
        .sheet(
            isPresented: $showDemoServer,
            content: {
                NavigationStack {
                    LoginDemoServerView(
                        loginViewState: $loginViewState,
                        passDemoMode: $passDemoMode,
                        showDemoServer: $showDemoServer,
                        animation: animation
                    )
                    .presentationDetents([.medium, .large])
                }
            }
        )
        .sheet(
            isPresented: $showOwnServer,
            content: {
                NavigationStack {
                    LoginOwnServerView(
                        loginViewState: $loginViewState,
                        passDemoMode: $passDemoMode,
                        showOwnServer: $showOwnServer,
                        animation: animation
                    )
                    .presentationDetents([.large])
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
                                Image(systemName: MySymbols.api)
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
                                Image(systemName: "network")
                                    .glassEffect()
                            }
                        )
                    }
                )
                ToolbarItem(
                    placement: .topBarTrailing,
                    content: {
                        Image(systemName: MySymbols.info)
                            .onTapGesture {
                                showAbout.toggle()
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
                        Image(systemName: MySymbols.settings)

                            .onTapGesture {
                                showSettings.toggle()
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

#Preview("Default") {
    NavigationStack {
        LoginView()
            .colorScheme(.light)
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        LoginView()
            .colorScheme(.dark)
    }
}
