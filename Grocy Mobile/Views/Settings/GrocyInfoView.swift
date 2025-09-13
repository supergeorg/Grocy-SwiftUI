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
    var releaseDate: String {
        if let systemInfo = systemInfo {
            return formatDateOutput(systemInfo.grocyVersion.releaseDate) ?? formatTimestampOutput(systemInfo.grocyVersion.releaseDate, localizationKey: localizationKey) ?? ""
        } else {
            return ""
        }
    }

    var body: some View {
        Form {
            if isDemoModus {
                Link(
                    destination: URL(string: demoServerURL)!,
                    label: {
                        Label("Grocy Server Demo URL: \(demoServerURL)", systemImage: "safari")
                    }
                )
            } else {
                Link(
                    destination: URL(string: grocyServerURL)!,
                    label: {
                        Label("Grocy Server URL: \(grocyServerURL)", systemImage: "safari")
                    }
                )
            }
            if let systemInfo = systemInfo {
                if isSupportedServer {
                    Label("Supported server version: \(systemInfo.grocyVersion.version)", systemImage: MySymbols.success)
                        .foregroundStyle(.green)
                } else {
                    Label("Unsupported server version: \(systemInfo.grocyVersion.version)", systemImage: MySymbols.failure)
                        .foregroundStyle(.red)
                }
                Label("Release date: \(releaseDate)", systemImage: MySymbols.date)
                    .foregroundStyle(.primary)
                Label("PHP version: \(systemInfo.phpVersion)", systemImage: "chevron.left.forwardslash.chevron.right")
                    .foregroundStyle(.primary)
                Label("SQLite version: \(systemInfo.sqliteVersion)", systemImage: "cylinder.split.1x2")
                    .foregroundStyle(.primary)
                if let os = systemInfo.os {
                    Label("OS: \(os)", systemImage: "server.rack")
                        .foregroundStyle(.primary)
                }
                if let client = systemInfo.client {
                    Label("Client information: \(client)", systemImage: "ipad.and.iphone")
                        .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle("Information about Grocy Server")
        .formStyle(.grouped)
    }
}

#Preview {
    GrocyInfoView(systemInfo: SystemInfo(grocyVersion: SystemInfo.GrocyVersion(version: "version", releaseDate: "date"), phpVersion: "php", sqliteVersion: "sqlite", os: "iOS", client: "Grocy Mobile"))
}
