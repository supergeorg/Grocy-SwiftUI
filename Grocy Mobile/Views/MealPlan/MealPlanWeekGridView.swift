//
//  MealPlanWeekGridView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftUI

/// The bounds of each day's column, taken from its header, to draw the columns behind the grid.
private struct MealPlanDayColumnKey: PreferenceKey {
    static let defaultValue: [Date: Anchor<CGRect>] = [:]

    static func reduce(value: inout [Date: Anchor<CGRect>], nextValue: () -> [Date: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

/// The week as a grid, as in the Grocy web app: a column per day, a row per section. For wide windows (iPad, Mac).
struct MealPlanWeekGridView: View {
    let days: [Date]
    let sections: MDMealPlanSections
    let entriesByDay: [String: MealPlanEntries]
    let lookup: MealPlanLookup
    let showsShoppingList: Bool
    let onSelect: (MealPlanEntry) -> Void
    let onAdd: (Date, Int) -> Void
    let onCopy: (Date) -> Void
    let perform: (MealPlanEntryAction, MealPlanEntry) -> Void

    private func entries(on day: Date) -> MealPlanEntries {
        entriesByDay[MealPlanNames.dayName(for: day)] ?? []
    }

    private func entries(on day: Date, in section: MDMealPlanSection) -> MealPlanEntries {
        entries(on: day).filter { entry in
            // Entries of a deleted section are shown without a section.
            let sectionID = lookup.sectionsByID[entry.sectionID] == nil ? MDMealPlanSection.noSectionID : entry.sectionID
            return sectionID == section.id
        }
    }

    var body: some View {
        ScrollView {
            Grid(alignment: .topLeading, horizontalSpacing: Spacing.medium, verticalSpacing: Spacing.medium) {
                GridRow {
                    Color.clear
                        .frame(width: Sizes.mealPlanSectionLabelWidth, height: 0)
                    ForEach(days, id: \.self) { day in
                        MealPlanGridDayHeaderView(
                            day: day,
                            lookup: lookup,
                            hasEntries: !entries(on: day).isEmpty,
                            onAdd: { onAdd(day, MDMealPlanSection.noSectionID) },
                            onCopy: { onCopy(day) }
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .anchorPreference(key: MealPlanDayColumnKey.self, value: .bounds) { [day: $0] }
                    }
                }

                ForEach(sections, id: \.id) { section in
                    Divider()
                    GridRow {
                        sectionLabel(section)
                            .frame(width: Sizes.mealPlanSectionLabelWidth, alignment: .leading)
                        ForEach(days, id: \.self) { day in
                            cell(day: day, section: section)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    }
                }
            }
            .backgroundPreferenceValue(MealPlanDayColumnKey.self) { columns in
                GeometryReader { proxy in
                    columnBackground(columns.mapValues { proxy[$0] }, height: proxy.size.height)
                }
            }
            .padding(Spacing.large)
        }
    }

    /// Today's column is tinted; hairlines between the days keep the columns apart without boxing every cell.
    @ViewBuilder
    private func columnBackground(_ columns: [Date: CGRect], height: CGFloat) -> some View {
        let frames = days.compactMap { columns[$0] }
        ZStack(alignment: .topLeading) {
            if let today = days.first(where: { Calendar.current.isDateInToday($0) }), let frame = columns[today] {
                RoundedRectangle(cornerRadius: Sizes.mealPlanCardCornerRadius)
                    .fill(Color.accentColor.opacity(0.06))
                    .frame(width: frame.width + 2 * Spacing.xSmall, height: height + 2 * Spacing.xSmall)
                    .offset(x: frame.minX - Spacing.xSmall, y: -Spacing.xSmall)
            }
            ForEach(Array(zip(frames, frames.dropFirst()).enumerated()), id: \.offset) { _, pair in
                Rectangle()
                    .fill(.separator)
                    .frame(width: 1, height: height)
                    .offset(x: (pair.0.maxX + pair.1.minX) / 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    private func sectionLabel(_ section: MDMealPlanSection) -> some View {
        VStack(alignment: .leading, spacing: Spacing.hairline) {
            Text(section.isNoSection ? String(localized: "No section") : section.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(section.isNoSection ? .secondary : .primary)
            if !section.timeInfo.isEmpty {
                Text(section.timeInfo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func cell(day: Date, section: MDMealPlanSection) -> some View {
        let cellEntries = entries(on: day, in: section)
        if cellEntries.isEmpty {
            Button {
                onAdd(day, section.id)
            } label: {
                Label("Add to meal plan", systemImage: MySymbols.new)
                    .labelStyle(.iconOnly)
                    // A faint plus without a fill, so the planned entries stand out in a mostly empty week.
                    .foregroundStyle(.quaternary)
                    .frame(maxWidth: .infinity, minHeight: Sizes.minimumHitTarget)
                    .contentShape(.rect(cornerRadius: Sizes.mealPlanCardCornerRadius))
            }
            .buttonStyle(.plain)
            #if os(iOS)
                .hoverEffect(.highlight)
            #endif
            .accessibilityLabel(Text("Add to meal plan"))
        } else {
            VStack(alignment: .leading, spacing: Spacing.small) {
                ForEach(cellEntries, id: \.id) { entry in
                    Button {
                        onSelect(entry)
                    } label: {
                        MealPlanEntryRowView(entry: entry, lookup: lookup, showsSection: false, compact: true)
                    }
                    .buttonStyle(.plain)
                    #if os(iOS)
                        .hoverEffect(.lift)
                    #endif
                    .contextMenu {
                        MealPlanEntryActionsView(entry: entry, lookup: lookup, showsShoppingList: showsShoppingList) { action in
                            perform(action, entry)
                        }
                    }
                }
            }
        }
    }
}

/// A day's column header in the week grid, like the Calendar app's week view: the weekday and the day of the month,
/// today's in a filled circle. It opens the day's menu (plan something, copy the day).
struct MealPlanGridDayHeaderView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.locale) private var locale

    let day: Date
    let lookup: MealPlanLookup
    let hasEntries: Bool
    let onAdd: () -> Void
    let onCopy: () -> Void

    @ScaledMetric(relativeTo: .title3) private var badgeSize: CGFloat = Sizes.mealPlanDayBadge

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    private var summary: String? {
        guard hasEntries, let fulfillment = lookup.dayFulfillment(for: day) else { return nil }
        var parts: [String] = []
        if lookup.showsCosts, let costs = fulfillment.costs, costs > 0 {
            parts.append(grocyVM.getFormattedCurrency(amount: costs))
        }
        if let calories = fulfillment.calories, calories > 0 {
            parts.append("\(calories.formatted(.number.precision(.fractionLength(0)).locale(locale))) \(lookup.energyUnit)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var accessibilityTitle: String {
        let date = day.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
        return isToday ? "\(String(localized: "Today")), \(date)" : date
    }

    var body: some View {
        Menu {
            Button(action: onAdd) {
                Label("Add to meal plan", systemImage: MySymbols.new)
            }
            Button(action: onCopy) {
                Label("Copy this day", systemImage: MySymbols.copyDay)
            }
            .disabled(!hasEntries)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                HStack(spacing: Spacing.xSmall) {
                    Text(day.formatted(.dateTime.weekday(.abbreviated).locale(locale)))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isToday ? Color.accentColor : .secondary)
                    Text(day.formatted(.dateTime.day().locale(locale)))
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                        // Today is marked by the shape too, not only by its color.
                        .foregroundStyle(isToday ? Color.white : Color.primary)
                        .frame(minWidth: badgeSize, minHeight: badgeSize)
                        .background {
                            if isToday {
                                Circle().fill(Color.accentColor)
                            }
                        }
                    Image(systemName: MySymbols.dayMenu)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                Text(summary ?? " ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    // Keeps every header the same height, with or without a summary.
                    .accessibilityHidden(summary == nil)
            }
            .frame(maxWidth: .infinity, minHeight: Sizes.minimumHitTarget, alignment: .leading)
            .contentShape(.rect)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        #if os(iOS)
            .hoverEffect(.highlight)
        #endif
        .accessibilityLabel(accessibilityTitle)
        .accessibilityHint(Text("Shows the day's actions"))
    }
}

#Preview(traits: .previewData) {
    let lookup = MealPlanLookup(recipes: [], fulfillments: [], products: [], quantityUnits: [], stock: [], sections: [], systemConfig: nil)
    let days = Calendar.current.daysOfWeek(startingAt: Calendar.current.startOfWeek(for: Date()))
    MealPlanWeekGridView(
        days: days,
        sections: [MDMealPlanSection(id: MDMealPlanSection.noSectionID), MDMealPlanSection(id: 1, name: "Breakfast", timeInfo: "07:30")],
        entriesByDay: [:],
        lookup: lookup,
        showsShoppingList: true,
        onSelect: { _ in },
        onAdd: { _, _ in },
        onCopy: { _ in },
        perform: { _, _ in }
    )
}
