//
//  GrocyInfoView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 12.10.20.
//

import SwiftUI

struct GrocyInfoView: View {
    var systemInfo: SystemInfo? = nil
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    @AppStorage("isDemoModus") var isDemoModus: Bool = false
    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue
    
    var isSupportedServer: Bool {
        if let systemInfo = systemInfo {
            return GrocyAPP.supportedVersions.contains(systemInfo.grocyVersion.version)
        } else {
            return false
        }
    }
    
    var body: some View {
        Form {
            if isDemoModus {
                Text(demoServerURL)
            } else {
                Text(grocyServerURL)
            }
            if let systemInfo = systemInfo {
                HStack {
                    Text("str.settings.info.grocyVersion \(systemInfo.grocyVersion.version)")
                    Label(
                        isSupportedServer ? "str.settings.about.version.supported" : "str.settings.about.version.notSupported",
                        systemImage: isSupportedServer ? MySymbols.success : MySymbols.failure
                    )
//                    .foregroundStyle(isSupportedServer ? Color.grocyGreen : Color.grocyRed)
                }
                Text("str.settings.info.grocyRLSDate \(formatDateOutput(systemInfo.grocyVersion.releaseDate) ?? formatTimestampOutput(systemInfo.grocyVersion.releaseDate, localizationKey: localizationKey) ?? "")")
                Text("str.settings.info.grocyPHPVersion \(systemInfo.phpVersion)")
                Text("str.settings.info.grocySQLiteVersion \(systemInfo.sqliteVersion)")
                if let os = systemInfo.os {
                    Text(os)
                }
                if let client = systemInfo.client {
                    Text(client)
                }
                Link(destination: URL(string: isDemoModus ? demoServerURL : grocyServerURL)!, label: {
                    Text("str.settings.info.openInBrowser")
                })
            }
        }
#if os(macOS)
        .frame(minWidth: Constants.macOSSettingsWidth, minHeight: Constants.macOSSettingsHeight)
#endif
    }
}

#Preview {
    GrocyInfoView(systemInfo: SystemInfo(grocyVersion: SystemInfo.GrocyVersion(version: "version", releaseDate: "date"), phpVersion: "php", sqliteVersion: "sqlite", os: "iOS", client: "Grocy Mobile"))
}
