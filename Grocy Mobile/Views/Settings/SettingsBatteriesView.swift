//
//  SettingsBatteriesView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftUI

/// Grocy's batteries settings: when a battery counts as "due soon" in the batteries overview.
struct SettingsBatteriesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var body: some View {
        Form {
            Section("Batteries overview") {
                ServerSettingsIntStepper(
                    settingKey: GrocyUserSettings.CodingKeys.batteriesDueSoonDays.rawValue,
                    description: "Due soon days",
                    descriptionInfo: "Set to 0 to hide due soon filters/highlighting",
                    icon: MySymbols.date
                )
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Batteries settings")
        .onDisappear {
            Task {
                await grocyVM.requestData(additionalObjects: [.user_settings])
            }
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        SettingsBatteriesView()
    }
}
