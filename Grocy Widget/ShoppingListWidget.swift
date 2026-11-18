//
//  ShoppingListWidget.swift
//  Grocy Widget
//
//  Created by Georg Meißner on 15.11.26.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline

struct ShoppingListEntry: TimelineEntry {
    let date: Date
    /// The selected list, or `nil` when the app hasn't written any shopping lists yet.
    let list: WidgetShoppingListSummary.List?
}

struct ShoppingListProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ShoppingListEntry {
        ShoppingListEntry(date: Date(), list: .placeholder)
    }

    func snapshot(for configuration: ShoppingListWidgetIntent, in context: Context) async -> ShoppingListEntry {
        let list = Self.list(for: configuration) ?? (context.isPreview ? .placeholder : nil)
        return ShoppingListEntry(date: Date(), list: list)
    }

    func timeline(for configuration: ShoppingListWidgetIntent, in context: Context) async -> Timeline<ShoppingListEntry> {
        // The app reloads the timeline after each shopping list sync.
        Timeline(entries: [ShoppingListEntry(date: Date(), list: Self.list(for: configuration))], policy: .never)
    }

    /// The configured list. Falls back to the first list, for example when the configured one was deleted.
    private static func list(for configuration: ShoppingListWidgetIntent) -> WidgetShoppingListSummary.List? {
        guard let summary = WidgetSharedStore.load(WidgetShoppingListSummary.self, forKey: WidgetSharedStore.shoppingListKey) else { return nil }
        if let id = configuration.shoppingList?.id, let list = summary.lists.first(where: { $0.id == id }) {
            return list
        }
        return summary.lists.first
    }
}

extension WidgetShoppingListSummary.List {
    static let placeholder = WidgetShoppingListSummary.List(
        id: 1,
        name: String(localized: "Shopping list"),
        items: [
            .init(id: 1, name: String(localized: "Apples"), amount: "6"),
            .init(id: 2, name: String(localized: "Bread"), amount: "1"),
            .init(id: 3, name: String(localized: "Milk"), amount: "2"),
            .init(id: 4, name: String(localized: "Tomatoes"), amount: "4"),
        ]
    )
}

// MARK: - Views

struct ShoppingListWidgetView: View {
    let entry: ShoppingListEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        Group {
            if let list = entry.list {
                content(for: list)
                    .widgetURL(WidgetDeepLink.shoppingList(id: list.id))
            } else {
                WidgetNoDataView()
                    .widgetURL(WidgetDeepLink.shoppingList(id: nil))
            }
        }
        .environment(\.locale, WidgetSharedStore.locale)
    }

    @ViewBuilder
    private func content(for list: WidgetShoppingListSummary.List) -> some View {
        switch widgetFamily {
        #if os(iOS)
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 0) {
                        Image(systemName: MySymbols.shoppingList)
                            .font(.body)
                            .widgetAccentable()
                        Text(list.items.count, format: .number)
                            .font(.title3.bold())
                            .minimumScaleFactor(0.6)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: list.name))
                .accessibilityValue(Text("\(list.items.count) items to buy"))
            case .accessoryInline:
                Label {
                    Text("\(Text(verbatim: list.name)): \(list.items.count)")
                } icon: {
                    Image(systemName: MySymbols.shoppingList)
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: list.name)
                        .font(.headline)
                        .widgetAccentable()
                    if list.items.isEmpty {
                        Text("All done")
                    } else {
                        Text(list.items.prefix(3).map(\.name).formatted(.list(type: .and, width: .narrow)))
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
        #endif
        default:
            VStack(alignment: .leading, spacing: 6) {
                WidgetHeaderView(
                    title: Text(verbatim: list.name),
                    systemImage: MySymbols.shoppingList,
                    count: widgetFamily == .systemSmall ? nil : list.items.count,
                    countDescription: Text("\(list.items.count) items to buy")
                )
                if list.items.isEmpty {
                    WidgetMessageView(systemImage: MySymbols.widgetAllDone, title: "All done", message: "Nothing left to buy.")
                } else {
                    itemList(list.items)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var maxItems: Int {
        switch widgetFamily {
        case .systemSmall: 4
        case .systemMedium: 4
        default: 10
        }
    }

    private func itemList(_ items: [WidgetShoppingListSummary.Item]) -> some View {
        let shown = items.prefix(maxItems)
        let hiddenCount = items.count - shown.count
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(shown) { item in
                ShoppingListWidgetRow(item: item, showsAmount: widgetFamily != .systemSmall)
            }
            if hiddenCount > 0 {
                Text("+ \(hiddenCount) more")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct ShoppingListWidgetRow: View {
    let item: WidgetShoppingListSummary.Item
    let showsAmount: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: MySymbols.undone)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(verbatim: item.name)
                .font(.subheadline)
                .lineLimit(1)
            if showsAmount {
                Spacer(minLength: 4)
                Text(verbatim: item.amount)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: item.name))
        .accessibilityValue(Text("\(Text("Amount")): \(item.amount)"))
    }
}

// MARK: - Widget

struct ShoppingListWidget: Widget {
    let kind: String = WidgetSharedStore.shoppingListKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ShoppingListWidgetIntent.self, provider: ShoppingListProvider()) { entry in
            ShoppingListWidgetView(entry: entry)
                .grocyWidgetBackground()
        }
        .configurationDisplayName("Shopping list")
        .description("Shows the items still to buy on a shopping list.")
        .supportedFamilies(Self.families)
    }

    private static var families: [WidgetFamily] {
        #if os(iOS)
            [.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline]
        #else
            [.systemSmall, .systemMedium, .systemLarge]
        #endif
    }
}

#Preview("Small", as: .systemSmall) {
    ShoppingListWidget()
} timeline: {
    ShoppingListEntry(date: .now, list: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    ShoppingListWidget()
} timeline: {
    ShoppingListEntry(date: .now, list: .placeholder)
    ShoppingListEntry(date: .now, list: WidgetShoppingListSummary.List(id: 1, name: String(localized: "Shopping list"), items: []))
}

#Preview("Large", as: .systemLarge) {
    ShoppingListWidget()
} timeline: {
    ShoppingListEntry(date: .now, list: .placeholder)
    ShoppingListEntry(date: .now, list: nil)
}

#if os(iOS)
    #Preview("Lock Screen", as: .accessoryRectangular) {
        ShoppingListWidget()
    } timeline: {
        ShoppingListEntry(date: .now, list: .placeholder)
    }
#endif
