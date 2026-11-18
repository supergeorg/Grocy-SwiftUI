//
//  DueItemRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// A compact row of the due agenda: kind, name, who or where, and when it's due.
struct DueItemRowView: View {
    var item: DueItem
    var user: GrocyUser?
    /// The stock quantity unit, for products below their minimum stock amount.
    var quantityUnit: MDQuantityUnit?

    @AppStorage("localizationKey") var localizationKey: String = "en"
    @ScaledMetric(relativeTo: .headline) private var iconWidth: CGFloat = Sizes.rowIconWidth

    private var detail: String? {
        switch item.source {
        case .product:
            nil
        case .belowMinStock(_, _, let amountMissing):
            "\(amountMissing.formattedAmount) \(quantityUnit?.getName(amount: amountMissing) ?? "")".trimmingCharacters(in: .whitespaces)
        case .chore, .task:
            user?.displayName
        case .battery(let battery):
            battery.usedIn.isEmpty ? nil : battery.usedIn
        }
    }

    /// Tasks can have a due time; chores and batteries are shown by day.
    private var showsTime: Bool {
        if case .task = item.source { return item.date?.hasTimeComponent ?? false }
        return false
    }

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: item.kind.icon)
                .foregroundStyle(item.urgency.color)
                .frame(width: iconWidth)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(item.name)
                    .font(.headline)
                Group {
                    if case .belowMinStock = item.source, let detail {
                        Text("Missing: \(detail)")
                    } else if let detail {
                        Text("\(Text(item.kind.singularTitle)) · \(detail)")
                    } else {
                        Text(item.kind.singularTitle)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if let date = item.date {
                VStack(alignment: .trailing, spacing: Spacing.hairline) {
                    Text(getRelativeDateAsText(date, localizationKey: localizationKey) ?? "")
                        .font(.subheadline)
                    Text(formatDateAsString(date, showTime: showsTime, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        // The urgency is announced, not only shown by the color.
        .accessibilityValue(Text(item.urgency.title))
    }
}

#Preview(traits: .previewData) {
    List {
        DueItemRowView(
            item: DueItem(
                source: .task(GrocyTask(name: "Take out the trash", dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)),
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                urgency: .overdue
            ),
            user: GrocyUser(id: 1, displayName: "Test User")
        )
        .listRowBackground(DueUrgency.overdue.backgroundColor)
        DueItemRowView(
            item: DueItem(source: .battery(Battery(batteryName: "Remote", usedIn: "Living room", chargeIntervalDays: 30)), date: Date(), urgency: .dueToday)
        )
        .listRowBackground(DueUrgency.dueToday.backgroundColor)
    }
}
