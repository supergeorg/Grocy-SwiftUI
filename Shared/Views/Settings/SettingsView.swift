//
//  SettingsView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 28.10.20.
//

import SwiftUI

struct SettingsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State var showGrocyVersion: Bool = false
    @State var showUserInfo: Bool = false
    @State var showAbout: Bool = false
    
    @AppStorage("isDemoModus") var isDemoModus: Bool = true
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""
    @AppStorage("simplifiedStockView") var simplifiedStockView: Bool = false
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    func updateData() {
        grocyVM.getSystemInfo()
        grocyVM.getUser()
    }
    
    #if os(iOS)
    @State private var isShowingScanner = false
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
                
                grocyVM.setLoginModus()
                grocyVM.checkLoginInfo(baseURL: grocyServerURL, apiKey: grocyAPIKey)
            }
        case .failure(let error):
            print("Scanning failed")
            print(error)
        }
    }
    #endif
    
    var body: some View {
        Group {
            #if os(iOS)
            container
            #else
            container
                .frame(minWidth: 500, idealWidth: 700, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            #endif
        }
        .background(Rectangle().fill(BackgroundStyle()).ignoresSafeArea())
        .navigationTitle(LocalizedStringKey("str.settings"))
    }
    
    var container: some View {
        VStack{
            #if os(iOS)
            contentiOS
            #else
            contentMac
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            #endif
        }
    }
    
    #if os(iOS)
    var contentiOS: some View {
        Form() {
            Section(header: Text("Grocy")){
                NavigationLink(
                    destination: GrocyInfoView(systemInfo: grocyVM.systemInfo ?? SystemInfo(grocyVersion: SystemInfo.GrocyVersion(version: "version", releaseDate: "date"), phpVersion: "php", sqliteVersion: "sqlite")),
                    label: {
                        Label(LocalizedStringKey("str.settings.info"), systemImage: "info.circle")
                    })
                if let currentUser = grocyVM.currentUser.first {
                    NavigationLink(destination: GrocyUserInfoView(grocyUser: currentUser), label: {
                        Label(LocalizedStringKey("str.settings.loggedInAs \(grocyVM.currentUser.first?.displayName ?? "ERROR")"), systemImage: "person")
                    })
                }
                Button(LocalizedStringKey("str.settings.logout")) {
                    isLoggedIn = false
                }
            }
            Section(header: Text("App")){
                MyToggle(isOn: $simplifiedStockView, description: "str.settings.simplifiedStockView", descriptionInfo: nil, icon: "tablecells")
                Picker(selection: $localizationKey, label: Label(LocalizedStringKey("str.settings.appLanguage"), systemImage: "flag"), content: {
                    Text("🇬🇧 English").tag("en")
                    Text("🇩🇪 Deutsch").tag("de")
                })
                NavigationLink(
                    destination: AboutView(),
                    label: {
                        Label(LocalizedStringKey("str.settings.about"), systemImage: "info.circle")
                    })
            }
        }
        .onAppear(perform: {
            updateData()
        })
        .navigationTitle(LocalizedStringKey("str.settings"))
    }
    #endif
    
    var contentMac: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text(LocalizedStringKey("str.settings.grocy.server"))
                    .font(Font.title).bold()
                    .foregroundColor(.secondary)
                Button(action: {
                    showGrocyVersion.toggle()
                }, label: {
                    Label(LocalizedStringKey("str.settings.info.version \(grocyVM.systemInfo?.grocyVersion.version ?? "Error")"), systemImage: "info.circle")
                })
                .popover(isPresented: $showGrocyVersion, content: {
                    GrocyInfoView(systemInfo: grocyVM.systemInfo ?? SystemInfo(grocyVersion: SystemInfo.GrocyVersion(version: "version", releaseDate: "date"), phpVersion: "php", sqliteVersion: "sqlite")).padding()
                })
                Button(action: {
                    showUserInfo.toggle()
                }, label: {
                    Label(LocalizedStringKey("str.settings.loggedInAs \(grocyVM.currentUser.first?.displayName ?? "ERROR")"), systemImage: "person")
                })
                .popover(isPresented: $showUserInfo, content: {
                    if let currentUser = grocyVM.currentUser.first {
                        GrocyUserInfoView(grocyUser: currentUser)
                            .padding()
                    } else {Text("cant load user data")}
                })
                Text(LocalizedStringKey(isDemoModus ? "str.settings.grocy.demoServer" : grocyServerURL))
                Button(LocalizedStringKey("str.settings.logout")) {
                    isLoggedIn = false
                }
            }
            Toggle(LocalizedStringKey("str.settings.simplifiedStockView"), isOn: $simplifiedStockView)
            Picker(selection: $localizationKey, label: Label(LocalizedStringKey("str.settings.appLanguage"), systemImage: "flag"), content: {
                Text("🇬🇧 English").tag("en")
                Text("🇩🇪 Deutsch").tag("de")
            })
            Button(action: {
                showAbout.toggle()
            }, label: {
                HStack{
                    Text(LocalizedStringKey("str.settings.about"))
                }
            })
            .popover(isPresented: $showAbout, content: {
                AboutView().padding()
            })
        }
        .padding(.bottom, 90)
        .onAppear(perform: {
            updateData()
        })
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
