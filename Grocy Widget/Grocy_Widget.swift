//
//  Grocy_Widget.swift
//  Grocy Widget
//
//  Created by Georg Meißner on 06.12.25.
//

import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), summary: .placeholder)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        // The widget gallery shows the snapshot, so fall back to sample counts before the app wrote any.
        let summary = WidgetStockSummary.load() ?? (context.isPreview ? .placeholder : nil)
        return SimpleEntry(date: Date(), configuration: configuration, summary: summary)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        // The app reloads the timeline after each stock sync. The periodic refresh only picks up summaries written while the widget wasn't reloaded.
        let entry = SimpleEntry(date: Date(), configuration: configuration, summary: WidgetStockSummary.load())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let summary: WidgetStockSummary?
}

extension WidgetStockSummary {
    static let placeholder = WidgetStockSummary(dueSoon: 3, overdue: 1, expired: 2, belowMinStock: 4, updated: .now)
}

struct Grocy_WidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        Group {
            if entry.summary != nil {
                StockWidgetView(entry: entry)
            } else {
                WidgetNoDataView()
            }
        }
        .environment(\.locale, WidgetSharedStore.locale)
    }
}

struct Grocy_Widget: Widget {
    let kind: String = WidgetStockSummary.widgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Grocy_WidgetEntryView(entry: entry)
                .grocyWidgetBackground()
        }
        .configurationDisplayName("Stock overview")
        .description("Shows how many products are due soon, overdue, expired or below their minimum stock amount.")
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
