//
//  AboutView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 26.10.20.
//

import SwiftUI

struct AboutLineView: View {
    var iconName: String
    var caption: String
    var content: String
    var body: some View {
        HStack{
            Image(systemName: iconName).font(.title)
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(caption)).font(.title3)
                Text(content).font(.body)
            }
        }
    }
}

struct AboutView: View {
    @AppStorage("onboardingNeeded") var onboardingNeeded: Bool = true
    var body: some View {
        Form(){
            Section{
                Text(LocalizedStringKey("str.settings.about.thanks"))
                    .lineLimit(.none)
                
                AboutLineView(iconName: "info.circle", caption: "str.settings.about.version", content: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Version number not found")
                
                AboutLineView(iconName: "person.circle", caption: "str.settings.about.developer", content: "Georg Meißner")
                
                Link(destination: URL(string: "https://github.com/twostraws/CodeScanner")!, label: {
                    AboutLineView(iconName: MySymbols.barcodeScan, caption: "CodeScanner", content: "Copyright (c) 2019 Paul Hudson")
                })
                .foregroundColor(.primary)
                
                Link(destination: URL(string: "https://github.com/dmytro-anokhin/url-image")!, label: {
                    AboutLineView(iconName: "photo", caption: "URLImage", content: "Copyright (c) 2020 Dmytro Anokhin")
                })
                .foregroundColor(.primary)
                
                Link(destination: URL(string: "https://github.com/SwiftyBeaver/SwiftyBeaver")!, label: {
                    AboutLineView(iconName: MySymbols.logFile, caption: "SwiftyBeaver", content: "Copyright (c) 2015 Sebastian Kreutzberger")
                })
                .foregroundColor(.primary)
                
                Link(destination: URL(string: "https://github.com/g-mark/NullCodable")!, label: {
                    AboutLineView(iconName: MySymbols.upload, caption: "Null Codable", content: "Copyright (c) 2020 Steven Grosmark")
                })
                .foregroundColor(.primary)
            }
            Button(action: {
                self.onboardingNeeded = true
            }, label: {
                Text(LocalizedStringKey("str.settings.about.showOnboarding"))
            })
        }
        .navigationTitle(LocalizedStringKey("str.settings.about"))
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView() {
            AboutView()
        }
    }
}
