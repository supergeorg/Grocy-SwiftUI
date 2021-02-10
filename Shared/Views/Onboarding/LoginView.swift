//
//  LoginView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.01.21.
//

import SwiftUI

struct LoginView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("isDemoModus") var isDemoModus: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""
    
    @State private var showAbout: Bool = false
    
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
        VStack{
            Image("grocy-logo")
            Spacer()
            #if os(iOS)
            Button(action: {isShowingScanner = true}, label: {
                Label(LocalizedStringKey("str.settings.loginQRcode.scan"), systemImage: MySymbols.qrScan)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.green)
                    )
                    .foregroundColor(.primary)
                    .animation(.spring())
            })
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.qr], scanMode: .once, simulatedData: "https://demo.grocy.info/api|vJQdTALB52YmBg4rhuMAdeYOcTqO4brIKHX7rGRwvWEdsActcl", completion: self.handleScan)
            }
            #endif
            MyTextField(textToEdit: $grocyServerURL, description: "str.settings.grocy.serverURL", isCorrect: Binding.constant(true), leadingIcon: "network")
            MyTextField(textToEdit: $grocyAPIKey, description: "str.settings.grocy.apiKey", isCorrect: Binding.constant(true), leadingIcon: "key")
            HStack{
                Link(destination: URL(string: "\(grocyServerURL)/manageapikeys")!, label: {
                    Text(LocalizedStringKey("str.settings.login.createAPIKey" ))
                        .padding(20)
                        .border(Color.green)
                        //                        .cornerRadius(10)
                        .foregroundColor(.primary)
                })
                Spacer()
                Button(action: {
                    grocyVM.setLoginModus()
                    grocyVM.checkLoginInfo(baseURL: grocyServerURL, apiKey: grocyAPIKey)
                }, label: {
                    #if os(iOS)
                    Text(LocalizedStringKey("str.settings.login"))
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.green)
                        )
                        .foregroundColor(.primary)
                    #else
                    Text(LocalizedStringKey("str.settings.login"))
                    #endif
                })
            }
            Divider()
            Button(action: {
                grocyVM.setDemoModus()
            }, label: {
                #if os(iOS)
                Text(LocalizedStringKey("str.settings.login.demo"))
                    .padding()
                #else
                Text(LocalizedStringKey("str.settings.login.demo"))
                #endif
            })
            Spacer()
            Group{
                HStack(spacing: 20){
                    Link(destination: URL(string: "https://github.com/supergeorg/Grocy-SwiftUI")!, label: {
                        Image(systemName: "chevron.left.slash.chevron.right")
                    })
                    Button(action: {
                        showAbout.toggle()
                    }, label: {
                        Image(systemName: "info.circle")
                    })
                    .sheet(isPresented: $showAbout, content: {
                        NavigationView {
                            AboutView()
                                .toolbar(content: {
                                    ToolbarItem(placement: .cancellationAction, content: {
                                                    Button(LocalizedStringKey("str.close"))
                                                    { showAbout = false }})
                                })
                        }
                    })
                    Link(destination: URL(string: "https://www.grocy.info")!, label: {
                        Image(systemName: "network")
                    })
                }
                Spacer()
            }
        }.padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
