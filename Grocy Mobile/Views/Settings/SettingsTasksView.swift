//
//  SettingsTasksView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import SwiftUI

/// Grocy's tasks settings: when a task counts as "due soon" in the tasks overview.
struct SettingsTasksView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var body: some View {
        Form {
            Section("Tasks overview") {
                ServerSettingsIntStepper(
                    settingKey: GrocyUserSettings.CodingKeys.tasksDueSoonDays.rawValue,
                    description: "Due soon days",
                    descriptionInfo: "Set to 0 to hide due soon filters/highlighting",
                    icon: MySymbols.date
                )
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Tasks settings")
        .onDisappear {
            Task {
                await grocyVM.requestData(additionalObjects: [.user_settings])
            }
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        SettingsTasksView()
    }
}
