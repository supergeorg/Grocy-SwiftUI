//
//  FA2SFSymbols.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 22.01.21.
//

import Foundation

func getSFSymbolForFA(faName: String) -> String {
    switch faName {
    case "fas fa-smile":
        return "face.smiling.fill"
    default:
        return "questionmark.circle.fill"
    }
}
