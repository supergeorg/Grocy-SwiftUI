//
//  AboutView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 26.10.20.
//

import SwiftUI

struct AboutLineView: View {
    var iconName: String
    var caption: String
    var content: String? = nil
    
    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(caption)
                    .font(.title)
                if let content = content {
                    Text(content)
                        .font(.body)
                }
            }
        } icon: {
            VStack {
                Image(systemName: iconName)
                    .font(.title2)
            }
        }
    }
}

struct AboutView: View {
    @AppStorage("onboardingNeeded") var onboardingNeeded: Bool = true
    
    var body: some View {
#if os(macOS)
        ScrollView {
            content
        }
        .padding()
#else
        content
#endif
    }
    
    var content: some View {
        Form{
            Section{
                Text("I want to thank Bernd Bestel for the development of Grocy. Without him, this app would be impossible.")
                    .lineLimit(.none)
                AboutLineView(iconName: MySymbols.info, caption: "Version", content: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Version number not found")
                AboutLineView(iconName: "person.circle", caption: "Developer", content: "Georg Meißner")
                Link(destination: URL(string: "https://github.com/supergeorg/Grocy-SwiftUI")!, label: {
                    AboutLineView(iconName: "chevron.left.forwardslash.chevron.right", caption: "Github", content: "supergeorg/Grocy-SwiftUI")
                })
                Link(destination: URL(string: "https://github.com/grocy/grocy")!, label: {
                    AboutLineView(iconName: MySymbols.purchase, caption: "Grocy", content: "Copyright (MIT License) 2017 Bernd Bestel")
                })
                
#if os(iOS)
                NavigationLink(destination: TranslatorsView(), label: {
                    AboutLineView(iconName: MySymbols.language, caption: "Translators")
                })
#else
                DisclosureGroup(content: {
                    TranslatorsView()
                }, label: {
                    AboutLineView(iconName: MySymbols.language, caption: "Translators")
                })
#endif
                Link(destination: URL(string: "https://github.com/twostraws/CodeScanner")!, label: {
                    AboutLineView(iconName: MySymbols.barcodeScan, caption: "CodeScanner", content: "Copyright (MIT License) 2019 Paul Hudson")
                })                
            }
            .foregroundStyle(.primary)
            Button("Replay app onboarding", action: {
                self.onboardingNeeded = true
            })
        }
        .navigationTitle("About this app")
    }
}

#Preview {
    AboutView()
}
