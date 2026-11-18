//
//  TranslatorsView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 21.08.21.
//

import SwiftUI

struct TranslatorLineView: View {
    var languageName: String
    var languageFlag: String
    var languageMaintainers: String
    var languageContributors: [String]

    var body: some View {
        DisclosureGroup(
            content: {
                ForEach(languageContributors, id: \.self) { contributor in
                    Text(contributor)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
            },
            label: {
                Label {
                    VStack(alignment: .leading, spacing: Spacing.hairline) {
                        Text(languageName)
                        if !languageMaintainers.isEmpty {
                            Text(languageMaintainers)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Text(languageFlag)
                        .accessibilityHidden(true)
                }
            }
        )
    }
}

struct TranslatorsView: View {
    var body: some View {
        Form {
            ForEach(
                Array(Translators.languages).sorted { $0.name < $1.name },
                id: \.self,
                content: { language in
                    TranslatorLineView(
                        languageName: language.name,
                        languageFlag: language.flag,
                        languageMaintainers: language.maintainers,
                        languageContributors: language.contributors
                    )
                }
            )
        }
        .formStyle(.grouped)
        .navigationTitle("Translators")
    }
}

#Preview {
    NavigationStack {
        TranslatorsView()
    }
}
