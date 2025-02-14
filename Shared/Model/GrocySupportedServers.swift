//
//  GrocyDemoServers.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 18.02.21.
//

import Foundation

struct GrocyAPP {
    //    The app plans to support the newest Grocy version as well as the version included in Home Assistant
    static let supportedVersions: [String] = ["4.0.2", "4.0.3", "4.1.0", "4.2.0"]
    
    enum DemoServers: String, CaseIterable, Identifiable {
        case noLanguage = "https://demo.grocy.info"
        case english = "https://en.demo.grocy.info"
        case german = "https://de.demo.grocy.info"
        case french = "https://fr.demo.grocy.info"
        case dutch = "https://nl.demo.grocy.info"
        case polish = "https://pl.demo.grocy.info"
        case czech = "https://cs.demo.grocy.info"
        case italian = "https://it.demo.grocy.info"
        case danish = "https://da.demo.grocy.info"
        case norwegian = "https://no.demo.grocy.info"
        case hungarian = "https://hu.demo.grocy.info"
        case chinese_hans = "https://zh-cn.demo.grocy.info"
        case chinese_hant = "https://zh-tw.demo.grocy.info"
        case portuguese_pt = "https://pt-pt.demo.grocy.info"
        case portuguese_br = "https://pt-br.demo.grocy.info"
        case finish = "https://fi.demo.grocy.info"
        case japanese = "https://ja.demo.grocy.info"
        case ukranian = "https://uk.demo.grocy.info"
        case catalan = "https://ca.demo.grocy.info"
        case greek = "https://el.demo.grocy.info"
        case estonian = "https://et.demo.grocy.info"
        case korean = "https://ko.demo.grocy.info"
        case romanian = "https://ro.demo.grocy.info"
        case slovak = "https://sk.demo.grocy.info"
        case slovenian = "https://sl.demo.grocy.info"
        case turkish = "https://tr.demo.grocy.info"
        case lithuanian = "https://lt.demo.grocy.info"
        case tamil = "https://ta.demo.grocy.info"
        case develop = "https://test-iwz5eqdtrrwco5or26tvo.demo.grocy.info"
        case developOld = "https://test-xjixc1minhzshgy6o142.demo.grocy.info"
        
        var id: Int {
            self.hashValue
        }
        
        var description: String {
            switch self {
            case .noLanguage:
                return "🏳️ Default Grocy server (english)"
            case .english:
                return "🇬🇧 English Grocy server"
            case .german:
                return "🇩🇪 German Grocy server"
            case .french:
                return "🇫🇷 French Grocy server"
            case .dutch:
                return "🇳🇱 Dutch Grocy server"
            case .polish:
                return "🇵🇱 Polish Grocy server"
            case .czech:
                return "🇨🇿 Czech Grocy server"
            case .italian:
                return "🇮🇹 Italian Grocy server"
            case .danish:
                return "🇩🇰 Danish Grocy server"
            case .norwegian:
                return "🇳🇴 Norwegian Grocy server"
            case .hungarian:
                return "🇭🇺 Hungarian Grocy server"
            case .chinese_hans:
                return "🇨🇳 Chinese (Simplified) Grocy server"
            case .chinese_hant:
                return "🇹🇼 Chinese (Traditional) Grocy server"
            case .portuguese_pt:
                return "🇵🇹 Português (Portuguese Portugal) Grocy Server"
            case .portuguese_br:
                return "🇧🇷 Português Brasileiro (Portuguese Brazil) Grocy Server"
            case .finish:
                return "🇫🇮 Finnish Grocy server"
            case .japanese:
                return "🇯🇵 Japanese Grocy server"
            case .ukranian:
                return "🇺🇦 Ukranian Grocy server"
            case .catalan:
                return "🏴󠁥󠁳󠁣󠁴󠁿 Catalan Grocy server"
            case .greek:
                return "🇬🇷 Greek Grocy server"
            case .estonian:
                return "🇪🇪 Estonian Grocy server"
            case .korean:
                return "🇰🇷 Korean Grocy server"
            case .romanian:
                return "🇷🇴 Romanian Grocy server"
            case .slovak:
                return "🇸🇰 Slovak Grocy server"
            case .slovenian:
                return "🇸🇮 Slovenian Grocy server"
            case .turkish:
                return "🇹🇷 Turkish Grocy server"
            case .lithuanian:
                return "🇱🇹 Lithuanian Grocy server"
            case .tamil:
                return "🇮🇳 Tamil Grocy server"
            case .develop:
                return "Private demo instance used for development"
            case .developOld:
                return "Old private demo instance used for development"
            }
        }
    }
}

