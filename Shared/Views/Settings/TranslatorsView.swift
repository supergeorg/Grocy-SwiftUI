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
    var languageTranslators: String
    var body: some View {
        HStack{
            Text(languageFlag).font(.title)
            VStack(alignment: .leading) {
                Text(languageName).font(.title3)
                Text(languageTranslators).font(.body)
            }
        }
    }
}

struct TranslatorsView: View {
    var body: some View {
        Form() {
            ForEach(Array(Translators.languages).sorted { $0.name < $1.name },id: \.self, content: { language in
                TranslatorLineView(languageName: language.name, languageFlag: language.flag, languageTranslators: language.translators)
            })
        }
        .navigationTitle("str.settings.about.translators")
    }
}

struct TranslatorsView_Previews: PreviewProvider {
    static var previews: some View {
        TranslatorsView()
    }
}
