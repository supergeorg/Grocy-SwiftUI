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
    var content: String? = nil

    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: iconName).font(.title)
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(caption)).font(.title3)
                if let content = content {
                    Text(content).font(.body)
                }
            }
        }
    }
}

struct AboutView: View {
    @AppStorage("onboardingNeeded") var onboardingNeeded: Bool = true
#if os(macOS)
    @State private var showTranslators: Bool = false
#endif
    
    var body: some View {
        Form(){
            Section{
                Text(LocalizedStringKey("str.settings.about.thanks"))
                    .lineLimit(.none)
                
                AboutLineView(iconName: MySymbols.info, caption: "str.settings.about.version", content: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Version number not found")
                
                AboutLineView(iconName: "person.circle", caption: "str.settings.about.developer", content: "Georg Meißner")
                
                Link(destination: URL(string: "https://github.com/supergeorg/Grocy-SwiftUI")!, label: {
                    AboutLineView(iconName: "chevron.left.forwardslash.chevron.right", caption: "Github", content: "supergeorg/Grocy-SwiftUI")
                })
                    .foregroundColor(.primary)
                
                Link(destination: URL(string: "https://github.com/grocy/grocy")!, label: {
                    AboutLineView(iconName: MySymbols.purchase, caption: "Grocy", content: "Copyright (MIT License) 2017 Bernd Bestel")
                })
                    .foregroundColor(.primary)
                
#if os(iOS)
                NavigationLink(destination: TranslatorsView(), label: {
                    AboutLineView(iconName: "flag", caption: "str.settings.about.translators")
                })
#else
                AboutLineView(iconName: "flag", caption: "str.settings.about.translators")
                    .onTapGesture {
                        showTranslators.toggle()
                    }
                if showTranslators {
                    TranslatorsView()
                }
#endif
                Link(destination: URL(string: "https://github.com/twostraws/CodeScanner")!, label: {
                    AboutLineView(iconName: MySymbols.barcodeScan, caption: "CodeScanner", content: "Copyright (MIT License) 2019 Paul Hudson")
                })
                    .foregroundColor(.primary)
                
                Link(destination: URL(string: "https://github.com/g-mark/NullCodable")!, label: {
                    AboutLineView(iconName: MySymbols.upload, caption: "Null Codable", content: "Copyright (Apache License 2.0) 2020 Steven Grosmark")
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
