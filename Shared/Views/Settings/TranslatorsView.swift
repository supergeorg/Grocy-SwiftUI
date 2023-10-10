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
        DisclosureGroup(content: {
            Group {
                ForEach(languageContributors, id: \.self) { contributor in
                    Text(contributor)
                        .font(.caption)
                }
            }
        }, label: {
            Label {
                VStack(alignment: .leading) {
                    Text(languageName)
                        .font(.title)
                    Text(languageMaintainers)
                        .font(.body)
                }
            } icon: {
                VStack {
                    Text(languageFlag).font(.title)
                }
            }
//            HStack {
//                Text(languageFlag).font(.title)
//                VStack(alignment: .leading) {
//                    Text(languageName).font(.title3)
//                    Text(languageMaintainers).font(.body)
//                }
//            }
        })
    }
}

struct TranslatorsView: View {
    var body: some View {
        Form {
            ForEach(Array(Translators.languages).sorted { $0.name < $1.name }, id: \.self, content: { language in
                TranslatorLineView(
                    languageName: language.name,
                    languageFlag: language.flag,
                    languageMaintainers: language.maintainers,
                    languageContributors: language.contributors
                )
            })
        }
        .navigationTitle("Translators")
    }
}

struct TranslatorsView_Previews: PreviewProvider {
    static var previews: some View {
        TranslatorsView()
    }
}
