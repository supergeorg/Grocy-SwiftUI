//
//  GrocyDemoServers.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 18.02.21.
//

import Foundation

struct GrocyAPP {
    //    The app plans to support the newest Grocy version as well as the version included in Home Assistant
    static let supportedVersions: [String] = ["3.1.3"]
    
    enum DemoServers: String, CaseIterable, Identifiable {
        case noLanguage = "https://demo.grocy.info"
        case english = "https://en.demo.grocy.info"
        case german = "https://de.demo.grocy.info"
        case french = "https://fr.demo.grocy.info"
        case polish = "https://pl.demo.grocy.info"
        case develop = "https://test-xjixc1minhzshgy6o142.demo.grocy.info"
        
        var id: Int {
            self.hashValue
        }
        
        var description: String {
            switch self {
            case .noLanguage:
                return "Default Grocy server (english)"
            case .english:
                return "English Grocy server"
            case .german:
                return "German Grocy server"
            case .french:
                return "French Grocy server"
            case .polish:
                return "Polish Grocy server"
            case .develop:
                return "Private demo instance used for development"
            }
        }
    }
}

