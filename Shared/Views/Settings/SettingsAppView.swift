//
//  SettingsAppView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 10.06.22.
//

import SwiftUI

struct SettingsAppView: View {
    @AppStorage("quickScanActionAfterAdd") private var quickScanActionAfterAdd: Bool = false
    @AppStorage("autoReload") private var autoReload: Bool = false
    @AppStorage("autoReloadInterval") private var autoReloadInterval: Int = 0
    @AppStorage("isDemoModus") var isDemoModus: Bool = true
    
    let refreshIntervals: [Int] = [3, 5, 10, 30, 60, 300]
    
    var body: some View {
        Form {
#if os(iOS)
            Section(header: Text(LocalizedStringKey("str.settings.app.quickScan")).font(.title)) {
                MyToggle(isOn: $quickScanActionAfterAdd, description: "str.settings.app.quickScan.actionAfterAdd")
            }
#endif
            Section(header: Text(LocalizedStringKey("str.settings.app.update")).font(.title)) {
                MyToggle(isOn: $autoReload, description: "str.settings.app.update.autoReload")
                Picker(selection: $autoReloadInterval, content: {
                    Text("").tag(0)
                    ForEach(refreshIntervals, id:\.self, content: { interval in
                        if !isDemoModus {
                            Text("\(interval.formatted())s").tag(interval)
                        } else {
                            // Add factor to reduce server load on demo servers
                            Text("\((interval * 2).formatted())s").tag(interval * 2)
                        }
                    })
                }, label: {
                    Label(title: {
                        Text(LocalizedStringKey("str.settings.app.update.autoReload.interval"))
                    }, icon: {
                        Image(systemName: MySymbols.timedRefresh)
                    })
                }
                )
                .disabled(!autoReload)
            }
        }
        .navigationTitle(LocalizedStringKey("str.settings.app"))
    }
}

struct SettingsAppView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAppView()
    }
}
