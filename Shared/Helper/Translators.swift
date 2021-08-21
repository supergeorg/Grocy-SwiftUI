//
//  Translators.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 21.08.21.
//

import Foundation

struct Language: Hashable {
    var name: String
    var flag: String
    var translators: String
}

struct Translators {
    static let german = Language(name: "Deutsch", flag: "🇩🇪", translators: "Georg Meißner")
    static let english = Language(name: "English", flag: "🇬🇧", translators: "Georg Meißner")
    static let polish = Language(name: "Polish", flag: "🇵🇱", translators: "Paweł Klebba")
    
    static let languages: Set<Language> = [english, german, polish]
}
