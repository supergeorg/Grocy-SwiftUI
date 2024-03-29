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
            HStack {
                Text(LocalizedStringKey("str.settings.info.grocyVersion \(systemInfo.grocyVersion.version)"))
                Label(LocalizedStringKey(GrocyAPP.supportedVersions.contains(systemInfo.grocyVersion.version) ? "str.settings.about.version.supported" : "str.settings.about.version.notSupported"), systemImage: GrocyAPP.supportedVersions.contains(systemInfo.grocyVersion.version) ? MySymbols.success : MySymbols.failure)
                    .foregroundColor(GrocyAPP.supportedVersions.contains(systemInfo.grocyVersion.version) ? Color.grocyGreen : Color.grocyRed)
            }
            Text(LocalizedStringKey("str.settings.info.grocyRLSDate \(formatDateOutput(systemInfo.grocyVersion.releaseDate) ?? formatTimestampOutput(systemInfo.grocyVersion.releaseDate, localizationKey: localizationKey) ?? "")"))
            Text(LocalizedStringKey("str.settings.info.grocyPHPVersion \(systemInfo.phpVersion)"))
            Text(LocalizedStringKey("str.settings.info.grocySQLiteVersion \(systemInfo.sqliteVersion)"))
            if let os = systemInfo.os {
                Text(os)
            }
            if let client = systemInfo.client {
                Text(client)
            }
            Link(destination: URL(string: isDemoModus ? demoServerURL : grocyServerURL)!, label: {
                Text(LocalizedStringKey("str.settings.info.openInBrowser"))
            })
        }
        .navigationTitle("Grocy")
#if os(macOS)
        .frame(minWidth: Constants.macOSSettingsWidth, minHeight: Constants.macOSSettingsHeight)
#endif
    }
}

struct GrocyInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView(){
            GrocyInfoView(systemInfo: SystemInfo(grocyVersion: SystemInfo.GrocyVersion(version: "version", releaseDate: "date"), phpVersion: "php", sqliteVersion: "sqlite", os: "iOS", client: "Grocy Mobile"))
        }
    }
}
