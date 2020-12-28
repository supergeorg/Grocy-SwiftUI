//
//  GrocyInfoView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 12.10.20.
//

import SwiftUI

struct GrocyInfoView: View {
    var systemInfo: SystemInfo
    
    var body: some View {
        Form(){
            Text(LocalizedStringKey("str.settings.info.grocyVersion \(systemInfo.grocyVersion.version)"))
            Text(LocalizedStringKey("str.settings.info.grocyRLSDate \(formatDateOutput(systemInfo.grocyVersion.releaseDate) ?? formatTimestampOutput(systemInfo.grocyVersion.releaseDate))"))
            Text(LocalizedStringKey("str.settings.info.grocyPHPVersion \(systemInfo.phpVersion)"))
            Text(LocalizedStringKey("str.settings.info.grocySQLiteVersion \(systemInfo.sqliteVersion)"))
        }
        .navigationTitle("Grocy")
    }
}

struct GrocyInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView(){
            GrocyInfoView(systemInfo: SystemInfo(grocyVersion: SystemInfo.GrocyVersion(version: "version", releaseDate: "date"), phpVersion: "php", sqliteVersion: "sqlite"))
        }
    }
}
