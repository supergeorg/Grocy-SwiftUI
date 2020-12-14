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
            Text(LocalizedStringKey("str.settings.grocyVersion \(systemInfo.grocyVersion.version)"))
            Text(LocalizedStringKey("str.settings.grocyRLSDate \(formatDateOutput(systemInfo.grocyVersion.releaseDate) ?? "Release Date error")"))
            Text(LocalizedStringKey("str.settings.grocyPHPVersion \(systemInfo.phpVersion)"))
            Text(LocalizedStringKey("str.settings.grocySQLiteVersion \(systemInfo.sqliteVersion)"))
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
