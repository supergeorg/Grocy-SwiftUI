//
//  SettingsView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 28.10.20.
//

import SwiftUI

struct SettingsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("isDemoModus") var isDemoModus: Bool = true
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    @AppStorage("devMode") private var devMode: Bool = false
    
    func updateData() {
        grocyVM.requestData(additionalObjects: [.system_info, .current_user])
    }
    
    var body: some View {
#if os(macOS)
        NavigationView {
            content
                .frame(minWidth: Constants.macOSNavWidth, maxWidth: .infinity)
                .padding()
        }
        .listStyle(.sidebar)
        .navigationTitle("str.settings")
        .frame(minWidth: Constants.macOSSettingsWidth, minHeight: Constants.macOSSettingsHeight)
#else
        Form {
            content
                .navigationTitle(LocalizedStringKey("str.settings"))
        }
#endif
    }
    
    
    
    var content: some View {
        List {
            if isLoggedIn {
                Section(header: Text("Grocy")){
                    NavigationLink(
                        destination: GrocyInfoView(systemInfo: grocyVM.systemInfo ?? SystemInfo(grocyVersion: SystemInfo.GrocyVersion(version: "version", releaseDate: "date"), phpVersion: "php", sqliteVersion: "sqlite", os: "iOS", client: "Grocy Mobile")),
                        label: {
                            Label(LocalizedStringKey("str.settings.info"), systemImage: MySymbols.info)
                                .foregroundColor(.primary)
                        })
                    if let currentUser = grocyVM.currentUser.first {
                        NavigationLink(destination: GrocyUserInfoView(grocyUser: currentUser), label: {
                            Label(LocalizedStringKey("str.settings.loggedInAs \(grocyVM.currentUser.first?.displayName ?? "ERROR")"), systemImage: "person")
                                .foregroundColor(.primary)
                        })
                    }
                    Button(action: {
                        grocyVM.logout()
                    }, label: { Label(LocalizedStringKey("str.settings.logout"), systemImage: "square.and.arrow.up").foregroundColor(.primary)})
                    Button(action: {grocyVM.deleteAllCachedData()}, label: {Label(LocalizedStringKey("str.settings.resetCache"), systemImage: "trash")})
                }
            }
            Section(header: Text(LocalizedStringKey("str.settings.grocy"))) {
                NavigationLink(destination: SettingsStockView(), label: {
                    Label(LocalizedStringKey("str.settings.stock"), systemImage: MySymbols.barcodeScan)
                        .foregroundColor(.primary)
                })
            }
            Section(header: Text("App")){
                Picker(selection: $localizationKey, label: Label(LocalizedStringKey("str.settings.appLanguage"), systemImage: "flag").foregroundColor(.primary), content: {
                    Text("🇬🇧 English").tag("en")
                    Text("🇩🇪 Deutsch").tag("de")
                    Text("🇫🇷 Français").tag("fr-FR")
                    Text("🇳🇱 Dutch").tag("nl")
                    Text("🇵🇱 Polska").tag("pl")
                })
#if os(iOS)
                NavigationLink(
                    destination: CodeTypeSelectionView(),
                    label: {
                        Label(LocalizedStringKey("str.settings.codeTypes"), systemImage: MySymbols.barcodeScan)
                            .foregroundColor(.primary)
                    })
#endif
                Toggle("DEV MODE", isOn: $devMode)
                NavigationLink(
                    destination: LogView(),
                    label: {
                        Label(LocalizedStringKey("str.settings.log"), systemImage: MySymbols.logFile)
                            .foregroundColor(.primary)
                    })
                NavigationLink(
                    destination: AboutView(),
                    label: {
                        Label(LocalizedStringKey("str.settings.about"), systemImage: MySymbols.info)
                            .foregroundColor(.primary)
                    })
            }
        }
        .onAppear(perform: {
            updateData()
        })
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
