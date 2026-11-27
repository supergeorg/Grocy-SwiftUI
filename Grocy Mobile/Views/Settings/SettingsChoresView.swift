//
//  SettingsChoreView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.12.25.
//

import SwiftUI

struct SettingsChoresView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var body: some View {
        Form {
            Section("Chores overview") {
                ServerSettingsIntStepper(
                    settingKey: GrocyUserSettings.CodingKeys.choresDueSoonDays.rawValue,
                    description: "Due soon days",
                    descriptionInfo: "Set to 0 to hide due soon filters/highlighting",
                    icon: MySymbols.date
                )
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.choresOverviewSwapTrackingButtons.rawValue,
                    description: "Swap track next schedule / track now buttons",
                    icon: MySymbols.choreTrackNext
                )
            }
            ReminderSyncSection(
                target: .chores,
                footer:
                    "Mirrors the chores to a list in Reminders, with their next due dates. Checking off a chore there tracks it in Grocy, and the reminder comes back with the next due date. It syncs when the chores or their reminders change, every few minutes while the app is open, and from time to time in the background."
            )
        }
        .formStyle(.grouped)
        .navigationTitle("Chores")
        .onDisappear(perform: {
            Task {
                await grocyVM.requestData(additionalObjects: [.user_settings])
            }
        })
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        SettingsChoresView()
    }
}
