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
                    Image(systemName: "chevron.left.slash.chevron.right")
                })
                
                Image(systemName: "info.circle")
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
                HStack{
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
                    .foregroundColor(.primary)
                    .pickerStyle(MenuPickerStyle())
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
    @AppStorage("hassAPIPath") var hassAPIPath: String = ""
    
    @AppStorage("devMode") private var devMode: Bool = false
    
    #if os(iOS)
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    @State private var isShowingScanner = true
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        self.isShowingScanner = false
        switch result {
        case .success(let code):
            let grocyServerData = code.components(separatedBy: "|")
            guard grocyServerData.count == 2 else { return }
            
            var serverURL = grocyServerData[0]
            serverURL = serverURL.replacingOccurrences(of: "/api", with: "")
            let apiKey = grocyServerData[1]
            
            if apiKey.count == 50 {
                grocyServerURL = serverURL
                grocyAPIKey = apiKey
                passDemoMode = false
                loginViewState = .logginIn
            }
        case .failure(let error):
            print("Scanning failed")
            print(error)
        }
    }
    #else
    @State private var isShowingScanner = false
    #endif
    
    var body: some View {
        VStack{
            CardView{
                VStack{
                    #if os(iOS)
                    Picker("", selection: $isShowingScanner, content: {
                        Text(LocalizedStringKey("str.login.ownServer.qr")).tag(true)
                        Text(LocalizedStringKey("str.login.ownServer.manual")).tag(false)
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    #endif
                    
                    if isShowingScanner {
                        #if os(iOS)
                        if horizontalSizeClass == .regular || verticalSizeClass == .regular {
                            VStack{
                                Text(LocalizedStringKey("str.login.ownServer.qr.info"))
                                CodeScannerView(codeTypes: [.qr], scanMode: .once, simulatedData: "https://demo.grocy.info/api|vJQdTALB52YmBg4rhuMAdeYOcTqO4brIKHX7rGRwvWEdsActcl", completion: self.handleScan)
                                    .border(Color.gray, width: 5)
                                    .cornerRadius(3)
                                    .matchedGeometryEffect(id: "login", in: animation)
                            }
                        } else {
                            HStack{
                                CodeScannerView(codeTypes: [.qr], scanMode: .once, simulatedData: "https://demo.grocy.info/api|vJQdTALB52YmBg4rhuMAdeYOcTqO4brIKHX7rGRwvWEdsActcl", completion: self.handleScan)
                                    .border(Color.gray, width: 5)
                                    .cornerRadius(3)
                                    .matchedGeometryEffect(id: "login", in: animation)
                                Text(LocalizedStringKey("str.login.ownServer.qr.info"))
                            }
                        }
                        
                        #endif
                        Button(action: {
                            loginViewState = .start
                        }, label: {
                            HStack{
                                Spacer()
                                Text(LocalizedStringKey("str.back"))
                                Spacer()
                            }
                        })
                        .buttonStyle(BorderButtonStyle())
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack{
                            MyTextField(textToEdit: $grocyServerURL, description: "str.login.ownServer.manual.serverURL", isCorrect: Binding.constant(true), leadingIcon: "network")
                            MyTextField(textToEdit: $grocyAPIKey, description: "str.login.ownServer.manual.APIKey", isCorrect: Binding.constant(true), leadingIcon: "key")
                            if devMode {
                                MyToggle(isOn: $useHassIngress, description: "str.login.hassIngress.use", icon: "house")
                                if useHassIngress {
                                    MyTextField(textToEdit: $hassAPIPath, description: "str.login.hassIngress.apiPath", isCorrect: Binding.constant(true), leadingIcon: "network")
                                    MyTextField(textToEdit: $hassToken, description: "str.login.hassIngress.token", isCorrect: Binding.constant(true), leadingIcon: "key")
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
                                        Link(destination: URL(string: "\(grocyServerURL)/manageapikeys")!, label: {
                                            Text(LocalizedStringKey("str.login.ownServer.manual.APIKey.create"))
                                        })
                                        .buttonStyle(BorderButtonStyle())
                                    }
                                    Button(action: {
                                        passDemoMode = false
                                        loginViewState = .logginIn
                                    }, label: {
                                        HStack{
                                            Spacer()
                                            Text(LocalizedStringKey("str.login.ownServer.manual.login"))
                                            Spacer()
                                        }
                                    })
                                    .buttonStyle(FilledButtonStyle())
                                    .frame(maxWidth: .infinity)
                                    .matchedGeometryEffect(id: "login", in: animation)
                                }
                            }
                        }
                    }
                }
            }
            .matchedGeometryEffect(id: "ownServer", in: animation)
        }
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
        #if os(iOS)
        content
        #elseif os(macOS)
        content
            .frame(minWidth: 500, minHeight: 500)
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
        .animation(.default)
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
