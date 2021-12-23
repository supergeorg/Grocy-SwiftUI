//
//  LoginView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 18.02.21.
//

import SwiftUI

enum LoginViewState {
    case start, demoServer, ownServer, logginIn
}

struct LoginInfoView: View {
    @State private var showAbout: Bool = false
    @State private var showSettings: Bool = false
    
    var body: some View {
        CardView{
            HStack(spacing: 20){
                Link(destination: URL(string: "https://github.com/supergeorg/Grocy-SwiftUI")!, label: {
                    Image(systemName: MySymbols.api)
                })
                
                Image(systemName: MySymbols.info)
                    .onTapGesture {
                        showAbout.toggle()
                    }
                    .sheet(isPresented: $showAbout, content: {
#if os(iOS)
                        NavigationView {
                            AboutView()
                                .toolbar(content: {
                                    ToolbarItem(placement: .cancellationAction, content: {
                                        Button(LocalizedStringKey("str.close"))
                                        { showAbout = false }})
                                })
                        }
#else
                        AboutView()
                            .padding()
                            .toolbar(content: {
                                ToolbarItem(placement: .cancellationAction, content: {
                                    Button(LocalizedStringKey("str.close"))
                                    { showAbout = false }})
                            })
#endif
                    })
                
                Link(destination: URL(string: "https://www.grocy.info")!, label: {
                    Image(systemName: "network")
                })
                
                Image(systemName: "gear")
                    .onTapGesture {
                        showSettings.toggle()
                    }
                    .sheet(isPresented: $showSettings, content: {
#if os(iOS)
                        NavigationView {
                            SettingsView()
                                .toolbar(content: {
                                    ToolbarItem(placement: .cancellationAction, content: {
                                        Button(LocalizedStringKey("str.close"))
                                        { showSettings = false }})
                                })
                        }
#else
                        SettingsView()
                            .padding()
                            .toolbar(content: {
                                ToolbarItem(placement: .cancellationAction, content: {
                                    Button(LocalizedStringKey("str.close"))
                                    { showSettings = false }})
                            })
#endif
                    })
            }
            .foregroundColor(.primary)
        }
    }
}

struct LoginStartView: View {
    @Binding var loginViewState: LoginViewState
    
    var animation: Namespace.ID
    
    var body: some View {
        CardView{
            VStack{
                Text(LocalizedStringKey("str.login.info"))
                Spacer()
                Text(LocalizedStringKey("str.login.select"))
                HStack {
                    Button(LocalizedStringKey("str.login.demoServer"), action: {
                        loginViewState = .demoServer
                    })
                        .buttonStyle(BorderButtonStyle())
                        .matchedGeometryEffect(id: "demoServer", in: animation)
                    
                    Button(LocalizedStringKey("str.login.ownServer"), action: {
                        loginViewState = .ownServer
                    })
                        .buttonStyle(FilledButtonStyle())
                        .matchedGeometryEffect(id: "ownServer", in: animation)
                }
            }
        }
        .padding()
    }
}

struct LoginDemoServerView: View {
    @Binding var loginViewState: LoginViewState
    @Binding var passDemoMode: Bool?
    var animation: Namespace.ID
    
    @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue
    
    var body: some View {
        VStack{
            CardView{
                VStack{
                    Text(LocalizedStringKey("str.login.demoServer.info"))
                    
#if os(iOS)
                    Menu {
                        Picker(selection: $demoServerURL, label: CardView{
                            HStack(alignment: .center){
                                Text(LocalizedStringKey("str.login.demoServer \(GrocyAPP.DemoServers.init(rawValue: demoServerURL)?.description ?? demoServerURL)"))
                                Image(systemName: MySymbols.menuPick)
                            }
                        }, content: {
                            ForEach(GrocyAPP.DemoServers.allCases, content: { demoServer in
                                Text(demoServer.description).tag(demoServer.rawValue)
                            })
                        })
                            .labelsHidden()
                    } label: {
                        HStack(alignment: .center){
                            Text(LocalizedStringKey("str.login.demoServer \(GrocyAPP.DemoServers.init(rawValue: demoServerURL)?.description ?? demoServerURL)"))
                            Image(systemName: MySymbols.menuPick)
                        }
                    }
#elseif os(macOS)
                    Picker(selection: $demoServerURL, label: Text(LocalizedStringKey("str.login.demoServer \("")")), content: {
                        ForEach(GrocyAPP.DemoServers.allCases, content: { demoServer in
                            Text(demoServer.description).tag(demoServer.rawValue)
                        })
                    })
#endif
                    
                    Spacer()
                    
                    HStack{
                        Button(LocalizedStringKey("str.back"), action: {
                            loginViewState = .start
                        })
                            .buttonStyle(BorderButtonStyle())
                        Button(LocalizedStringKey("str.login.demoServer.use"), action: {
                            passDemoMode = true
                            loginViewState = .logginIn
                        })
                            .buttonStyle(FilledButtonStyle())
                            .matchedGeometryEffect(id: "login", in: animation)
                    }
                }
            }
            .matchedGeometryEffect(id: "demoServer", in: animation)
            .padding()
        }
    }
}

struct LoginOwnServerView: View {
    @Binding var loginViewState: LoginViewState
    @Binding var passDemoMode: Bool?
    var animation: Namespace.ID
    
    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""
    
    // Home Assistant
    @AppStorage("useHassIngress") var useHassIngress: Bool = false
    @AppStorage("hassToken") var hassToken: String = ""
    
    @AppStorage("devMode") private var devMode: Bool = false
    
#if os(iOS)
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    @State private var isShowingGrocyScanner: Bool = false
    func handleGrocyScan(result: Result<String, CodeScannerView.ScanError>) {
        self.isShowingGrocyScanner = false
        switch result {
        case .success(let code):
            let grocyServerData = code.components(separatedBy: "|")
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
    func handleTokenScan(result: Result<String, CodeScannerView.ScanError>) {
        self.isShowingTokenScanner = false
        switch result {
        case .success(let scannedHassToken):
            hassToken = scannedHassToken
        case .failure(let error):
            print("Scanning failed")
            print(error)
        }
    }
#endif
    
    var body: some View {
        CardView{
            VStack{
                MyTextField(textToEdit: $grocyServerURL, description: "str.login.ownServer.manual.serverURL", isCorrect: Binding.constant(true), leadingIcon: "network", helpText: "str.login.ownServer.manual.serverURL.help")
                MyTextField(textToEdit: $grocyAPIKey, description: "str.login.ownServer.manual.APIKey", isCorrect: Binding.constant(true), leadingIcon: "key", helpText: "str.login.ownServer.manual.APIKey.help")
#if os(iOS)
                Button(action: {
                    isShowingGrocyScanner.toggle()
                }, label: {
                    Label(LocalizedStringKey("str.login.ownServer.qr"), systemImage: MySymbols.qrScan)
                })
                    .buttonStyle(FilledButtonStyle())
                    .sheet(isPresented: $isShowingGrocyScanner, content: {
                        CodeScannerView(codeTypes: [.qr], scanMode: .once, simulatedData: "http://192.168.178.40:8123/api/hassio_ingress/ckgy-GNrulcboPPwZyCnOn181YpRqOr6vIC8G2lijqU/api|tkYf677yotIwTibP0ko1lZxn8tj4cgoecWBMropiNc1MCjup8p", completion: self.handleGrocyScan)
                    })
#endif
                CardView {
                    VStack(spacing: 20) {
                        MyToggle(isOn: $useHassIngress, description: "str.login.hassIngress.use", icon: "house")
                        if useHassIngress {
                            HStack {
                                MyTextField(textToEdit: $hassToken, description: "str.login.hassIngress.token", isCorrect: Binding.constant(true), leadingIcon: "key", helpText: "str.login.hassIngress.token.help")
#if os(iOS)
                                Button(action: {
                                    isShowingTokenScanner.toggle()
                                }, label: {
                                    Image(systemName: MySymbols.qrScan)
                                })
                                    .sheet(isPresented: $isShowingTokenScanner, content: {
                                        CodeScannerView(codeTypes: [.qr], scanMode: .once, simulatedData: "670f7d46391db7b42d382ebc9ea667f3aac94eb90219b9e32c7cd71cd37d13833109113270b327fac08d77d9b038a9cb3ab6cfd8dc8d0e3890d16e6434d10b3d", completion: self.handleTokenScan)
                                    })
#endif
                            }
                        }
                        Link(destination: URL(string: "https://github.com/supergeorg/Grocy-SwiftUI/blob/main/Guides/Home%20Assistant%20Ingress/HomeAssistantIngressGuide.md")!, label: {
                            Label("Guide (English)", systemImage: "questionmark.circle")
                        })
                    }
                }
                Spacer()
                CardView{
                    VStack{
                        HStack{
                            Button(LocalizedStringKey("str.back"), action: {
                                loginViewState = .start
                            })
                                .buttonStyle(BorderButtonStyle())
                            if let manageKeysURL = URL(string: "\(grocyServerURL)/manageapikeys") {
                                Link(destination: manageKeysURL, label: {
                                    Text(LocalizedStringKey("str.login.ownServer.manual.APIKey.create"))
                                })
                                    .buttonStyle(BorderButtonStyle())
                            }
                        }
                        Button(LocalizedStringKey("str.login.ownServer.manual.login"), action: {
                            passDemoMode = false
                            loginViewState = .logginIn
                        })
                            .buttonStyle(FilledButtonStyle())
                            .frame(maxWidth: .infinity)
                            .matchedGeometryEffect(id: "login", in: animation)
                    }
                }
            }
        }
        .matchedGeometryEffect(id: "ownServer", in: animation)
        .padding()
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
    
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue
    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""
    
    @State private var errorMessage: String?
    @State private var unsupportedVersion: String?
    
    private func tryLogin() {
        if let isDemoMode = isDemoMode {
            grocyVM.checkServer(baseURL: isDemoMode ? demoServerURL : grocyServerURL, apiKey: isDemoMode ? nil : grocyAPIKey, isDemoModus: isDemoMode, completion: {result in
                switch result {
                case let .success(message):
                    if GrocyAPP.supportedVersions.contains(message) {
                        loginState = .success
                        isDemoMode ? grocyVM.setDemoModus() : grocyVM.setLoginModus()
                    } else {
                        unsupportedVersion = message
                        loginState = .unsupportedVersion
                    }
                case let .failure(error):
                    errorMessage = "\(error)"
                    loginState = .fail
                }
            })
        }
    }
    
    var body: some View {
        Group{
            switch loginState{
            case .loading:
                ProgressView()
                    .scaleEffect(1.5, anchor: .center)
                    .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                    .onAppear(perform: {tryLogin()})
            case .success:
                Text("success")
            case .fail:
                VStack{
                    CardView{
                        VStack(alignment: .leading){
                            Text(LocalizedStringKey("str.login.connect.fail"))
                            ScrollView {
                                Text(LocalizedStringKey("str.login.connect.fail.info \((isDemoMode ?? false) ? demoServerURL : grocyServerURL) \(errorMessage ?? "")"))
                            }
                        }
                    }
                    CardView{
                        HStack{
                            Button(LocalizedStringKey("str.back"), action: {
                                loginViewState = (isDemoMode ?? false) ? .demoServer : .ownServer
                            })
                                .buttonStyle(BorderButtonStyle())
                            Button(LocalizedStringKey("str.retry"), action: {
                                tryLogin()
                            })
                                .buttonStyle(FilledButtonStyle())
                        }
                    }
                }
            case .unsupportedVersion:
                VStack{
                    CardView{
                        Text(LocalizedStringKey("str.login.connect.unsupportedVersion \(unsupportedVersion ?? "?")"))
                    }
                    HStack{
                        Button(LocalizedStringKey("str.back"), action: {
                            loginViewState = (isDemoMode ?? false) ? .demoServer : .ownServer
                        })
                            .buttonStyle(BorderButtonStyle())
                        Button(LocalizedStringKey("str.login.connect.unsupportedVersion.confirm"), action: {
                            if isDemoMode ?? false {
                                grocyVM.setDemoModus()
                            } else {
                                grocyVM.setLoginModus()
                            }
                        })
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
        VStack{
            Spacer()
#if os(iOS)
            if horizontalSizeClass == .regular || verticalSizeClass == .regular {
                Image("grocy-logo")
            }
#else
            Image("grocy-logo")
#endif
            switch loginViewState {
            case .start:
                LoginStartView(loginViewState: $loginViewState, animation: animation)
            case .demoServer:
                LoginDemoServerView(loginViewState: $loginViewState, passDemoMode: $passDemoMode, animation: animation)
            case .ownServer:
                LoginOwnServerView(loginViewState: $loginViewState, passDemoMode: $passDemoMode, animation: animation)
            case .logginIn:
                LoginStatusView(loginViewState: $loginViewState, isDemoMode: $passDemoMode, loginState: .loading, animation: animation)
            }
            Spacer()
            LoginInfoView()
            Spacer()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            LoginView()
                .colorScheme(.light)
            LoginView()
                .colorScheme(.dark)
        }
    }
}
