//
//  MealPlanNames.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import Foundation

/// The names of the internal recipes Grocy keeps for the meal plan, and the calendar the meal plan's weeks use.
///
/// Grocy sums up the meal plan in recipes of its own (`RecipeType.mealplanDay`, `.mealplanWeek`, `.mealplanShadow`):
/// their fulfillment holds the costs, calories and missing ingredients of a day, a week or one recipe entry.
nonisolated enum MealPlanNames {
    /// `YYYY-MM-DD`, the day of a meal plan entry and the name of the day's internal recipe.
    static func dayName(for date: Date) -> String {
        date.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day().dateSeparator(.dash))
    }

    /// The internal recipe of a recipe entry, `YYYY-MM-DD#<entry id>`.
    static func shadowRecipeName(day: Date, entryID: Int) -> String {
        "\(dayName(for: day))#\(entryID)"
    }

    /// The week's internal recipe: SQLite's `LTRIM(STRFTIME('%Y-%W', day), '0')`. `%W` counts weeks starting on Monday;
    /// the days before the year's first Monday are week 00.
    static func weekName(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let year = calendar.component(.year, from: date)
        let dayOfYear = (calendar.ordinality(of: .day, in: .year, for: date) ?? 1) - 1
        // 0 = Monday … 6 = Sunday
        let weekdayFromMonday = (calendar.component(.weekday, from: date) + 5) % 7
        let week = (dayOfYear + 7 - weekdayFromMonday) / 7
        let name = "\(year)-\(week < 10 ? "0" : "")\(week)"
        return String(name.drop(while: { $0 == "0" }))
    }

    /// The app setting of the meal plan's first day of the week: a `Calendar` weekday (`1` = Sunday … `7` = Saturday),
    /// or `serverFirstWeekday` to follow the Grocy server.
    static let firstWeekdayKey = "mealPlanFirstWeekday"
    static let serverFirstWeekday = 0

    /// A calendar whose weeks start on the meal plan's first day: the app setting (`Calendar` weekday, `1` = Sunday),
    /// else the server's, resolved like the Grocy web app does: `MEAL_PLAN_FIRST_DAY_OF_WEEK`, else
    /// `CALENDAR_FIRST_DAY_OF_WEEK`, else the locale's. Grocy counts `0` = Sunday … `6` = Saturday; the meal plan's `-1`
    /// starts the week on today.
    static func calendar(
        firstWeekday: Int = serverFirstWeekday,
        mealPlanFirstDayOfWeek: String?,
        calendarFirstDayOfWeek: String?,
        locale: Locale,
        today: Date = Date()
    ) -> Calendar {
        var calendar = Calendar.current
        calendar.locale = locale
        if (1...7).contains(firstWeekday) {
            calendar.firstWeekday = firstWeekday
        } else if startsOnToday(mealPlanFirstDayOfWeek: mealPlanFirstDayOfWeek) {
            calendar.firstWeekday = calendar.component(.weekday, from: today)
        } else if let day = mealPlanFirstDayOfWeek.flatMap({ Int($0) }), (0...6).contains(day) {
            calendar.firstWeekday = day + 1
        } else if let day = calendarFirstDayOfWeek.flatMap({ Int($0) }), (0...6).contains(day) {
            calendar.firstWeekday = day + 1
        } else {
            calendar.firstWeekday = locale.calendar.firstWeekday
        }
        return calendar
    }

    /// Grocy's `MEAL_PLAN_FIRST_DAY_OF_WEEK` `-1`: the week starts on today.
    static func startsOnToday(mealPlanFirstDayOfWeek: String?) -> Bool {
        mealPlanFirstDayOfWeek.flatMap { Int($0) } == -1
    }
}

extension Calendar {
    /// The first day of the week that contains `date`.
    func startOfWeek(for date: Date) -> Date {
        dateInterval(of: .weekOfYear, for: date)?.start ?? startOfDay(for: date)
    }

    /// The seven days of the week that starts at `weekStart`.
    func daysOfWeek(startingAt weekStart: Date) -> [Date] {
        (0..<7).compactMap { date(byAdding: .day, value: $0, to: weekStart) }
    }
}
