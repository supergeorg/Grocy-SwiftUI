//
//  WidgetComponents.swift
//  Grocy Widget
//
//  Created by Georg Meißner on 15.11.26.
//

import SwiftUI
import WidgetKit

// MARK: - Header

/// The title row at the top of a widget: symbol, title and an optional count.
///
/// VoiceOver reads the title, then `countDescription` (for example "4 overdue or due today"), because a bare number doesn't say what it counts.
struct WidgetHeaderView: View {
    let title: Text
    let systemImage: String
    var count: Int? = nil
    var countDescription: Text? = nil
    var tint: Color = .accentColor

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Label {
                title
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .widgetAccentable()
            }
            .font(.headline)
            Spacer(minLength: 4)
            if let count {
                Text(count, format: .number)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityCount)
        .accessibilityAddTraits(.isHeader)
    }

    private var accessibilityCount: Text {
        if let countDescription {
            return countDescription
        }
        if let count {
            return Text(count, format: .number)
        }
        return Text(verbatim: "")
    }
}

// MARK: - Messages

/// A centered message, used for empty lists and for missing data.
struct WidgetMessageView: View {
    let systemImage: String
    let title: LocalizedStringKey
    var message: LocalizedStringKey? = nil

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)
                .widgetAccentable()
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Shown when the app hasn't written any data for the widget yet, for example before the first login.
struct WidgetNoDataView: View {
    var body: some View {
        WidgetMessageView(
            systemImage: MySymbols.widgetNoData,
            title: "No data yet",
            message: "Open Grocy Mobile to load your data."
        )
    }
}

// MARK: - Accessory backgrounds

extension View {
    /// The container background used by all Grocy widgets.
    func grocyWidgetBackground() -> some View {
        containerBackground(.fill.tertiary, for: .widget)
    }
}
