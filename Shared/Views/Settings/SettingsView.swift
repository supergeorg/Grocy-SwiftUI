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
    @State var showLog: Bool = false
    
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
            if isLoggedIn {
                Section(header: Text("Grocy")){
                    NavigationLink(
                        destination: GrocyInfoView(systemInfo: grocyVM.systemInfo ?? SystemInfo(grocyVersion: SystemInfo.GrocyVersion(version: "version", releaseDate: "date"), phpVersion: "php", sqliteVersion: "sqlite")),
                        label: {
                            Label(LocalizedStringKey("str.settings.info"), systemImage: "info.circle")
                                .foregroundColor(.primary)
                        })
                    if let currentUser = grocyVM.currentUser.first {
                        NavigationLink(destination: GrocyUserInfoView(grocyUser: currentUser), label: {
                            Label(LocalizedStringKey("str.settings.loggedInAs \(grocyVM.currentUser.first?.displayName ?? "ERROR")"), systemImage: "person")
                                .foregroundColor(.primary)
                        })
                    }
                    Button(action: {
                        isLoggedIn = false
                        grocyVM.deleteAllCachedData()
                        updateData()
                    }, label: { Label(LocalizedStringKey("str.settings.logout"), systemImage: "square.and.arrow.up").foregroundColor(.primary)})
                    Button(action: {grocyVM.deleteAllCachedData()}, label: {Label(LocalizedStringKey("str.settings.resetCache"), systemImage: "trash")})
                }
            }
            Section(header: Text("App")){
                MyToggle(isOn: $simplifiedStockView, description: "str.settings.simplifiedStockView", descriptionInfo: nil, icon: "tablecells")
                Picker(selection: $localizationKey, label: Label(LocalizedStringKey("str.settings.appLanguage"), systemImage: "flag").foregroundColor(.primary), content: {
                    Text("🇬🇧 English").tag("en")
                    Text("🇩🇪 Deutsch").tag("de")
                })
                NavigationLink(
                    destination: AboutView(),
                    label: {
                        Label(LocalizedStringKey("str.settings.about"), systemImage: "info.circle")
                            .foregroundColor(.primary)
                    })
                //                NavigationLink(
                //                    destination: LogView(),
                //                    label: {
                //                        Label(LocalizedStringKey("LOG"), systemImage: "tag")
                //                            .foregroundColor(.primary)
                //                    })
            }
        }
        .onAppear(perform: {
            updateData()
        })
        .navigationTitle(LocalizedStringKey("str.settings"))
    }
    #endif
    
    var contentMac: some View {
        VStack {
            VStack(alignment: .leading) {
                Text(LocalizedStringKey("str.settings.info"))
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
                Button(action: {
                    isLoggedIn = false
                    grocyVM.deleteAllCachedData()
                    updateData()
                }, label: { Label(LocalizedStringKey("str.settings.logout"), systemImage: "square.and.arrow.up").foregroundColor(.primary)})
                Button(action: {grocyVM.deleteAllCachedData()}, label: {Label(LocalizedStringKey("str.settings.resetCache"), systemImage: "trash")})
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
            
            //            Button(action: {
            //                showLog.toggle()
            //            }, label: {
            //                Label(LocalizedStringKey("SHOW LOG"), systemImage: "tag")
            //            })
            //            .popover(isPresented: $showLog, content: {
            //                LogView()
            //                    .frame(width: 500, height: 500)
            //            })
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
