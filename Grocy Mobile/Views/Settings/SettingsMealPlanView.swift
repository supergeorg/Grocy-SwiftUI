//
//  SettingsMealPlanView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import SwiftData
import SwiftUI

/// Settings of the meal plan that only this app uses.
struct SettingsMealPlanView: View {
    @Environment(\.locale) private var locale
    @AppStorage("localizationKey") private var localizationKey: String = "en"
    @AppStorage(MealPlanNames.firstWeekdayKey) private var firstWeekday: Int = MealPlanNames.serverFirstWeekday

    @Query private var systemConfigList: [SystemConfig]

    private var systemConfig: SystemConfig? { systemConfigList.first }

    /// The first day the server sets: the meal plan's, the calendar's, or the language's.
    private var serverWeekday: Int {
        MealPlanNames.calendar(
            mealPlanFirstDayOfWeek: systemConfig?.mealPlanFirstDayOfWeek,
            calendarFirstDayOfWeek: systemConfig?.calendarFirstDayOfWeek,
            locale: Locale(identifier: localizationKey)
        )
        .firstWeekday
    }

    /// The server's day by name, or "Today" when the server starts the week on the current day.
    private var serverDayName: String {
        MealPlanNames.startsOnToday(mealPlanFirstDayOfWeek: systemConfig?.mealPlanFirstDayOfWeek)
            ? String(localized: "Today") : weekdayNames[serverWeekday - 1]
    }

    private var weekdayNames: [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar.standaloneWeekdaySymbols
    }

    /// The weekdays from the server's first day on, so the list reads like a week.
    private var orderedWeekdays: [Int] {
        (0..<7).map { (serverWeekday - 1 + $0) % 7 + 1 }
    }

    var body: some View {
        Form {
            Section {
                Picker(selection: $firstWeekday) {
                    Text("Server default (\(serverDayName))")
                        .tag(MealPlanNames.serverFirstWeekday)
                    Divider()
                    ForEach(orderedWeekdays, id: \.self) { weekday in
                        Text(weekdayNames[weekday - 1])
                            .tag(weekday)
                    }
                } label: {
                    Label("First day of the week", systemImage: MySymbols.date)
                        .foregroundStyle(.primary)
                }
            } footer: {
                Text("The server default is the first day set on your Grocy server for the meal plan or the calendar, or else the app's language.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Meal plan")
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        SettingsMealPlanView()
    }
}
