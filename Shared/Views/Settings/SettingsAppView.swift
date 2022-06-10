//
//  SettingsAppView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 10.06.22.
//

import SwiftUI

struct SettingsAppView: View {
    @AppStorage("quickScanActionAfterAdd") private var quickScanActionAfterAdd: Bool = false
    
    var body: some View {
        Form {
#if os(iOS)
            Section(header: Text(LocalizedStringKey("str.settings.app.quickScan")).font(.title)) {
                MyToggle(isOn: $quickScanActionAfterAdd, description: "str.settings.app.quickScan.actionAfterAdd")
            }
#endif
        }
        .navigationTitle(LocalizedStringKey("str.settings.app"))
    }
}

struct SettingsAppView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAppView()
    }
}
