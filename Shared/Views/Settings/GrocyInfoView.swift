//
//  GrocyInfoView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 12.10.20.
//

import SwiftUI

struct GrocyInfoView: View {
    var systemInfo: SystemInfo
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    @AppStorage("isDemoModus") var isDemoModus: Bool = false
    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue
    
    var body: some View {
        List{
            if isDemoModus {
                Text(demoServerURL)
            } else {
                Text(grocyServerURL)
            }
            Text(LocalizedStringKey("str.settings.info.grocyVersion \(systemInfo.grocyVersion.version)"))
            Text(LocalizedStringKey("str.settings.info.grocyRLSDate \(formatDateOutput(systemInfo.grocyVersion.releaseDate) ?? formatTimestampOutput(systemInfo.grocyVersion.releaseDate, localizationKey: localizationKey) ?? "")"))
            Text(LocalizedStringKey("str.settings.info.grocyPHPVersion \(systemInfo.phpVersion)"))
            Text(LocalizedStringKey("str.settings.info.grocySQLiteVersion \(systemInfo.sqliteVersion)"))
            if let os = systemInfo.os {
                Text(os)
            }
            if let client = systemInfo.client {
                Text(client)
            }
        }
        .navigationTitle("Grocy")
    }
}

struct GrocyInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView(){
            GrocyInfoView(systemInfo: SystemInfo(grocyVersion: SystemInfo.GrocyVersion(version: "version", releaseDate: "date"), phpVersion: "php", sqliteVersion: "sqlite", os: "iOS", client: "Grocy Mobile"))
        }
    }
}
