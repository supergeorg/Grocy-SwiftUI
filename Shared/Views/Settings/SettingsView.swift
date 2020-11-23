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
    @State var showAbout: Bool = false
    
    @AppStorage("isDemoModus") var isDemoModus: Bool = true
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""
    
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
        .navigationTitle("str.settings")
    }
    
    var container: some View {
        VStack{
            //        ZStack {
            //            ScrollView {
            #if os(iOS)
            contentiOS
            #else
            contentMac
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            #endif
            //            }
            //                        VisualEffectBlur()
            //                            .ignoresSafeArea()
            //                            .opacity(selectedIngredientID != nil ? 1 : 0)
        }
    }
    
    var contentiOS: some View {
        Form() {
            Section(header: Text("Grocy")){
                if isLoggedIn {
                    NavigationLink(
                        destination: GrocyInfoView(systemInfo: grocyVM.systemInfo ?? SystemInfo(grocyVersion: SystemInfo.GrocyVersion(version: "version", releaseDate: "date"), phpVersion: "php", sqliteVersion: "sqlite")),
                        label: {
                            Text("Infos zu Grocy-Server")
                        })
                    Button("Logout aus Grocy-Server") {
                        isLoggedIn = false
                    }
                } else {
                    MyTextField(textToEdit: $grocyServerURL, description: "Grocy Server URL", isCorrect: Binding.constant(true), leadingIcon: "network")
                    MyTextField(textToEdit: $grocyAPIKey, description: "Valid API Key", isCorrect: Binding.constant(true), leadingIcon: "key")
                    Button("Login") {
                        grocyVM.setLoginModus()
                        grocyVM.checkLoginInfo(baseURL: grocyServerURL, apiKey: grocyAPIKey)
                    }
                    Button("Demo") {
                        grocyVM.setDemoModus()
                    }
                }
            }
            Section(header: Text("App")){
                NavigationLink(
                    destination: AboutView(),
                    label: {
                        Text("Infos zur App")
                    })
            }
        }
        .onAppear(perform: {
            grocyVM.getSystemInfo()
        })
        .navigationTitle("Settings")
    }
    
    var contentMac: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text("Server")
                    .font(Font.title).bold()
                    .foregroundColor(.secondary)
                if isLoggedIn {
                    Button(action: {
                        showGrocyVersion.toggle()
                    }, label: {
                        HStack{
                            Text("str.settings.version \(grocyVM.systemInfo?.grocyVersion.version ?? "Error")")
                        }
                    })
                    .popover(isPresented: $showGrocyVersion, content: {
                        GrocyInfoView(systemInfo: grocyVM.systemInfo ?? SystemInfo(grocyVersion: SystemInfo.GrocyVersion(version: "version", releaseDate: "date"), phpVersion: "php", sqliteVersion: "sqlite")).padding()
                    })
                    Button("str.settings.logout") {
                        isLoggedIn = false
                    }
                } else {
                    MyTextField(textToEdit: $grocyServerURL, description: "Grocy Server URL", isCorrect: Binding.constant(true), leadingIcon: "network")
                    //                                    .onChange(of: grocyServerURL, perform: { value in
                    //                                        checkGrocyURL()
                    //                                    })
                    MyTextField(textToEdit: $grocyAPIKey, description: "Valid API Key", isCorrect: Binding.constant(true), leadingIcon: "key")
                    //                                    .onChange(of: grocyAPIKey, perform: { value in
                    //                                        checkAPIKey()
                    //                                    })
                    HStack{
                        Button("Login") {
                            grocyVM.setLoginModus()
                            grocyVM.checkLoginInfo(baseURL: grocyServerURL, apiKey: grocyAPIKey)
                        }
                        Spacer()
                        Button("Demo") {
                            grocyVM.setDemoModus()
                        }
                    }
                }
                Button(action: {
                    showAbout.toggle()
                }, label: {
                    HStack{
                        Text("About")
                    }
                })
                .popover(isPresented: $showAbout, content: {
                    AboutView().padding()
                })
            }
            .padding()   
        }
        .padding(.bottom, 90)
        .onAppear(perform: {
            grocyVM.getSystemInfo()
        })
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
