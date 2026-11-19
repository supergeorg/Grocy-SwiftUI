//
//  MealPlanDayHeaderView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftUI

/// A day of the meal plan: its weekday and date, what everything planned costs and its calories,
/// and a menu to plan something or copy the day.
struct MealPlanDayHeaderView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.locale) private var locale

    let day: Date
    let lookup: MealPlanLookup
    let hasEntries: Bool
    let onAdd: () -> Void
    let onCopy: () -> Void

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

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(day.formatted(.dateTime.weekday(.wide).locale(locale)))
                    .font(.headline)
                    .foregroundStyle(isToday ? Color.accentColor : .primary)
                Text(isToday ? String(localized: "Today") : day.formatted(.dateTime.day().month(.abbreviated).locale(locale)))
                    .font(.subheadline)
                    .foregroundStyle(isToday ? Color.accentColor : .secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            if let summary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Menu {
                Button(action: onAdd) {
                    Label("Add to meal plan", systemImage: MySymbols.new)
                }
                Button(action: onCopy) {
                    Label("Copy this day", systemImage: MySymbols.copyDay)
                }
                .disabled(!hasEntries)
            } label: {
                Label("Day actions", systemImage: MySymbols.moreActions)
                    .labelStyle(.iconOnly)
                    .frame(minWidth: Sizes.minimumHitTarget, minHeight: Sizes.minimumHitTarget)
                    .contentShape(.rect)
            }
            .menuIndicator(.hidden)
            .buttonStyle(.borderless)
            .fixedSize()
        }
        .textCase(nil)
    }
}

#Preview(traits: .previewData) {
    let lookup = MealPlanLookup(recipes: [], fulfillments: [], products: [], quantityUnits: [], stock: [], sections: [], systemConfig: nil)
    List {
        Section {
            Text("Pizza")
        } header: {
            MealPlanDayHeaderView(day: Date(), lookup: lookup, hasEntries: true, onAdd: {}, onCopy: {})
        }
    }
}
