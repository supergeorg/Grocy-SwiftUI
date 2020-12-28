//
//  Localization.swift
//  grocy-ios
//
//  Created by Georg Meissner on 09.11.20.
//

import Foundation

extension String {
    var localized: String {
        let language = Locale.current.languageCode
        let path = Bundle.main.path(forResource: language, ofType: "lproj")!
        let bundle = Bundle(path: path)!
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
}
