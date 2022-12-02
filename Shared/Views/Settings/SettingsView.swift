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
                Section(header: Text("Grocy")) {
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
                        grocyVM.deleteAllCachedData()
                    }, label: {
                        Label(LocalizedStringKey("str.settings.resetCache"), systemImage: MySymbols.delete)
                            .foregroundColor(.primary)
                    })
                    Button(action: {
                        grocyVM.logout()
                    }, label: {
                        Label(LocalizedStringKey("str.settings.logout"), systemImage: MySymbols.logout)
                            .foregroundColor(.red)
                    })
                }
            }
            Section(header: Text(LocalizedStringKey("str.settings.grocy"))) {
                NavigationLink(destination: SettingsAppView(), label: {
                    Label(LocalizedStringKey("str.settings.app"), systemImage: MySymbols.app)
                        .foregroundColor(.primary)
                })
                NavigationLink(destination: SettingsStockView(), label: {
                    Label(LocalizedStringKey("str.settings.stock"), systemImage: MySymbols.stockOverview)
                        .foregroundColor(.primary)
                })
                NavigationLink(destination: SettingsShoppingListView(), label: {
                    Label(LocalizedStringKey("str.settings.shoppingList"), systemImage: MySymbols.shoppingList)
                        .foregroundColor(.primary)
                })
            }
            Section(header: Text("App")) {
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
