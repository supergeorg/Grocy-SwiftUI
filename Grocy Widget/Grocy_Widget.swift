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
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), summary: nil)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, summary: WidgetStockSummary.load())
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

struct Grocy_WidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        if entry.summary != nil {
            StockWidgetView(entry: entry)
        } else {
            VStack {
                Image(systemName: "exclamationmark.circle")
                    .font(.title)
                Text("Unable to load data")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }
}

struct Grocy_Widget: Widget {
    let kind: String = WidgetStockSummary.widgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Grocy_WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}
