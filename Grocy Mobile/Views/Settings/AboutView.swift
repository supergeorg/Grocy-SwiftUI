//
//  AboutView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 26.10.20.
//

import SwiftUI

struct AboutLineView: View {
    var iconName: String
    var caption: LocalizedStringKey
    var content: String? = nil

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(caption)
                if let content {
                    Text(content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: iconName)
        }
    }
}

struct AboutView: View {
    @AppStorage("onboardingNeeded") var onboardingNeeded: Bool = true

    @State private var showWhatsNew: Bool = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Version number not found"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    Text(appVersion)
                        .textSelection(.enabled)
                } label: {
                    Label("Version", systemImage: MySymbols.info)
                }
                LabeledContent {
                    Text("Georg Meißner")
                } label: {
                    Label("Developer", systemImage: MySymbols.developer)
                }
                if let gitHubURL = URL(string: "https://github.com/supergeorg/Grocy-SwiftUI") {
                    Link(destination: gitHubURL) {
                        AboutLineView(iconName: MySymbols.api, caption: "Github", content: "supergeorg/Grocy-SwiftUI")
                    }
                }
                #if os(iOS)
                    NavigationLink {
                        TranslatorsView()
                    } label: {
                        AboutLineView(iconName: MySymbols.language, caption: "Translators")
                    }
                #else
                    DisclosureGroup {
                        TranslatorsView()
                    } label: {
                        AboutLineView(iconName: MySymbols.language, caption: "Translators")
                    }
                #endif
                if let editorURL = URL(string: "https://github.com/Infomaniak/swift-rich-html-editor") {
                    Link(destination: editorURL) {
                        AboutLineView(iconName: MySymbols.richText, caption: "Infomaniak Rich HTML Editor", content: "Copyright (Apache 2.0 License) Infomaniak")
                    }
                }
            } header: {
                Text("Grocy Mobile")
            }
            .foregroundStyle(.primary)

            Section {
                Label {
                    Text("I want to thank Bernd Bestel for the development of Grocy. Without him, this app would be impossible.")
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: MySymbols.thanks)
                        .foregroundStyle(Color(.GrocyColors.grocyRed))
                        .accessibilityHidden(true)
                }
                .padding(.vertical, Spacing.xxSmall)
                if let grocyURL = URL(string: "https://github.com/grocy/grocy") {
                    Link(destination: grocyURL) {
                        AboutLineView(iconName: MySymbols.purchase, caption: "Grocy", content: "Copyright (MIT License) 2017 Bernd Bestel")
                    }
                }
            } header: {
                Text("Grocy")
            }
            .foregroundStyle(.primary)

            Section {
                Button("What's New in Grocy Mobile", systemImage: MySymbols.whatsNew) {
                    showWhatsNew = true
                }
                .disabled(WhatsNew.features(for: WhatsNew.appVersion).isEmpty)
                Button("Replay app onboarding", systemImage: MySymbols.reset) {
                    onboardingNeeded = true
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("About this app")
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewView()
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
