//
//  SettingsAppView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 10.06.22.
//

import SwiftData
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
    @AppStorage("useAppleIntelligence") var useAppleIntelligence: Bool = true

    #if os(iOS)
        @AppStorage(PhoneNavigationStyle.storageKey) var phoneNavigationStyle: PhoneNavigationStyle = .smart
        @AppStorage("iPadTabNavigation") var iPadTabNavigation: Bool = false
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    let refreshIntervals: [Int] = [3, 5, 10, 30, 60, 300]

    var body: some View {
        Form {
            Picker(
                selection: $localizationKey,
                label: Label("App language", systemImage: MySymbols.language).foregroundStyle(.primary),
                content: {
                    Group {
                        Text("🇺🇸 English").tag("en")
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
                        Text("🇩🇰 Dansk (Danish)").tag("da")
                        Text("🇭🇺 Magyar (Hungarian)").tag("hu")
                        Text("🇹🇼 漢文 (Chinese Traditional)").tag("zh-Hant")
                    }
                    Group {
                        Text("🇫🇮 Suomi (Finnish)").tag("fi")
                        Text("🇯🇵 日本語 (Japanese)").tag("ja")
                        Text("🇺🇦 Українська (Ukrainian)").tag("uk")
                        Text("🏴󠁥󠁳󠁣󠁴󠁿 Català (Catalan)").tag("ca")
                        Text("🇬🇷 Ellinika (Greek)").tag("el")
                        Text("🇬🇧 British English").tag("en-GB")
                        Text("🇪🇪 Eesti Keel (Estonian)").tag("et")
                    }
                    Group {
                        Text("🇮🇱 עִבְרִית (Hebrew)").tag("he")
                        Text("🇰🇷 한국어 (Korean)").tag("ko")
                        Text("🇷🇴 Românește (Romanian)").tag("ro")
                        Text("🇸🇰 Slovenčina (Slovak)").tag("sk")
                        Text("🇸🇮 Slovenščina (Slovenian)").tag("sl")
                        Text("🇹🇷 Türkçe (Turkish)").tag("tr")
                        Text("🇱🇹 Lietuvių (Lithuanian)").tag("lt")
                    }
                    Group {
                        Text("🇮🇳 தமிழ் (Tamil)").tag("ta")
                    }
                }
            )
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
                        Label("Barcode settings", systemImage: MySymbols.barcodeScan)
                            .foregroundStyle(.primary)
                    }
                )

                if PhoneNavigationStyle.applies(in: horizontalSizeClass) {
                    Picker(selection: $phoneNavigationStyle) {
                        ForEach(PhoneNavigationStyle.allCases) { style in
                            Label(style.title, systemImage: style.icon)
                                .tag(style)
                        }
                    } label: {
                        Label("iPhone navigation", systemImage: MySymbols.iPhoneTabNavigation)
                            .foregroundStyle(.primary)
                    }
                    if phoneNavigationStyle == .tabs {
                        // Value-based, so the editor stays open when the tab bar is rebuilt after a change.
                        NavigationLink(value: SettingsNavigationItem.phoneTabs) {
                            Label("Tabs", systemImage: MySymbols.chooseTabs)
                                .foregroundStyle(.primary)
                        }
                    }
                } else {
                    MyToggle(isOn: $iPadTabNavigation, description: "iPad: Tab navigation", icon: MySymbols.iPadTabNavigation)
                }
            #endif
            MyToggle(isOn: $devMode, description: "DEV MODE", icon: MySymbols.devMode)
            #if os(iOS)
                if PhoneNavigationStyle.applies(in: horizontalSizeClass) {
                    Section {
                        DueKindToggles()
                    } header: {
                        Text("Due")
                    } footer: {
                        Text("What the due tab shows.")
                    }
                }
            #else
                // The due list is in the Mac's sidebar; its kinds are set here like on the iPhone.
                Section {
                    DueKindToggles()
                } header: {
                    Text("Due")
                } footer: {
                    Text("What the due list shows.")
                }
            #endif
            #if os(iOS)
                Section("\(Text("Quick Scan")) \(Text("Settings"))") {
                    MyToggle(isOn: $quickScanActionAfterAdd, description: "Do selected action after assigning a barcode", icon: MySymbols.barcodeScan)
                }
            #endif
            Section("Data fetching settings") {
                MyToggle(isOn: $autoReload, description: "Auto reload on external changes", icon: MySymbols.reload)
                    // Apply the change right away, not only after the next launch (#112).
                    .onChange(of: autoReload) {
                        if grocyVM.isLoggedIn { grocyVM.setUpdateTimer() }
                    }
                    .onChange(of: autoReloadInterval) {
                        if grocyVM.isLoggedIn { grocyVM.setUpdateTimer() }
                    }
                if autoReload {
                    Picker(
                        selection: $autoReloadInterval,
                        content: {
                            Text("").tag(0)
                            ForEach(
                                refreshIntervals,
                                id: \.self,
                                content: { interval in
                                    if !isDemoModus {
                                        Text("\(interval.formatted())s").tag(interval)
                                    } else {
                                        // Add factor to reduce server load on demo servers
                                        Text("\((interval * 2).formatted())s").tag(interval * 2)
                                    }
                                }
                            )
                        },
                        label: {
                            Label("Reload interval", systemImage: MySymbols.timedRefresh)
                                .foregroundStyle(.primary)
                        }
                    )
                }
            }
            if AppleIntelligenceStatus.isAppleIntelligenceAvailable {
                Section("Apple Intelligence") {
                    MyToggle(isOn: $useAppleIntelligence, description: "Apple Intelligence", icon: MySymbols.appleIntelligence)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        SettingsAppView()
    }
}
