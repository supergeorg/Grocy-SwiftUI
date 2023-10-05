//
//  SettingsAppView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 10.06.22.
//

import SwiftUI

struct SettingsAppView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @AppStorage("devMode") private var devMode: Bool = false
    
    @AppStorage("quickScanActionAfterAdd") private var quickScanActionAfterAdd: Bool = false
    @AppStorage("autoReload") private var autoReload: Bool = false
    @AppStorage("autoReloadInterval") private var autoReloadInterval: Int = 0
    @AppStorage("isDemoModus") var isDemoModus: Bool = true
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @AppStorage("timeoutInterval") var timeoutInterval: Double = 60.0
    
    let refreshIntervals: [Int] = [3, 5, 10, 30, 60, 300]
    
    var body: some View {
        Form {
            Picker(
                selection: $localizationKey,
                label: Label("App language",systemImage: MySymbols.language).foregroundStyle(.primary),
                content: {
                    Group {
                        Text("🇬🇧 English").tag("en")
                        Text("🇩🇪 Deutsch (German)").tag("de")
                        Text("🇫🇷 Français (French)").tag("fr-FR")
                        Text("🇳🇱 Nederlands (Dutch)").tag("nl")
                        Text("🇵🇱 Polska (Polish)").tag("pl")
                        Text("🇨🇿 Česky (Czech)").tag("cs")
                        Text("🇮🇹 Italiano (Italian)").tag("it")
                    }
                    Group {
                        Text("🇨🇳 汉文 (Chinese Simplified)").tag("zh-Hans")
                        Text("🇵🇹 Português (Portuguese Portugal)").tag("pt-PT")
                        Text("🇧🇷 Português Brasileiro (Portuguese Brazil)").tag("pt-BR")
                        Text("🇳🇴 Norsk (Norwegian Bokmål)").tag("nb")
                    }
                    if devMode {
                        Group {
                            Text("🇩🇰 Dansk (Danish)").tag("da")
                            Text("🇭🇺 Magyar (Hungarian)").tag("hu")
                            Text("🇹🇼 漢文 (Chinese Traditional)").tag("zh-Hant")
                        }
                    }
                })
            MyDoubleStepper(
                amount: $timeoutInterval,
                description: "Server timeout interval",
                minAmount: 1.0,
                maxAmount: 1000.0,
                amountStep: 1.0,
                amountName: "s",
                systemImage: MySymbols.timeout
            )
            .onChange(of: timeoutInterval) {
                grocyVM.grocyApi.setTimeoutInterval(timeoutInterval: timeoutInterval)
            }
#if os(iOS)
            NavigationLink(
                destination: CodeTypeSelectionView(),
                label: {
                    Label(LocalizedStringKey("Barcode settings"), systemImage: MySymbols.barcodeScan)
                        .foregroundStyle(.primary)
                })
#endif
            MyToggle(isOn: $devMode, description: "DEV MODE", icon: MySymbols.devMode)
#if os(iOS)
            Section("QuickScan settings") {
                MyToggle(isOn: $quickScanActionAfterAdd, description: "Do selected action after assigning a barcode", icon: MySymbols.barcodeScan)
            }
#endif
            Section("Data fetching settings") {
                MyToggle(isOn: $autoReload, description: "Auto reload on external changes", icon: MySymbols.reload)
                if autoReload {
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
                        Label("Reload interval", systemImage: MySymbols.timedRefresh)
                            .foregroundStyle(.primary)
                    })
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("App settings")
    }
}

#Preview {
        SettingsAppView()
}
