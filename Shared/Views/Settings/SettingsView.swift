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
    
    @AppStorage("timeoutInterval") var timeoutInterval: Double = 60.0
    
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
                    if let currentUser = grocyVM.currentUser {
                        NavigationLink(destination: GrocyUserInfoView(grocyUser: currentUser), label: {
                            Label(LocalizedStringKey("str.settings.loggedInAs \(currentUser.displayName)"), systemImage: "person")
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
                NavigationLink(destination: SettingsShoppingListView(), label: {
                    Label(LocalizedStringKey("str.settings.shoppingList"), systemImage: MySymbols.shoppingList)
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
                MyDoubleStepper(amount: $timeoutInterval, description: "str.settings.serverTimeoutInterval", minAmount: 1.0, maxAmount: 1000.0, amountStep: 1.0, amountName: "s", systemImage: MySymbols.timeout)
                    .onChange(of: timeoutInterval, perform: { newTimeoutInterval in
                        grocyVM.grocyApi.setTimeoutInterval(timeoutInterval: newTimeoutInterval)
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
            grocyVM.requestData(additionalObjects: [.system_info, .current_user])
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
