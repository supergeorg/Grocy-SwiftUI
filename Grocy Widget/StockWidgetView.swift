//
//  StockWidgetView.swift
//  Grocy Widget
//
//  Created by Georg Meissner on 06.12.25.
//

import SwiftUI
import WidgetKit

/// One of the four stock counts shown by the widget.
private struct StockStatusItem: Identifiable {
    let status: ProductStatus
    let count: Int
    let color: Color
    let background: Color

    var id: String { status.caseName }
    var url: URL { WidgetDeepLink.stock(filter: status.caseName) }
}

struct StockWidgetView: View {
    let entry: Provider.Entry
    @Environment(\.widgetFamily) private var widgetFamily

    private var summary: WidgetStockSummary {
        entry.summary ?? .placeholder
    }

    private var items: [StockStatusItem] {
        [
            StockStatusItem(
                status: .expiringSoon,
                count: summary.dueSoon,
                color: Color(.GrocyColors.grocyYellow),
                background: Color(.GrocyColors.grocyYellowBackground)
            ),
            StockStatusItem(
                status: .overdue,
                count: summary.overdue,
                color: Color(.GrocyColors.grocyGray),
                background: Color(.GrocyColors.grocyGrayBackground)
            ),
            StockStatusItem(status: .expired, count: summary.expired, color: Color(.GrocyColors.grocyRed), background: Color(.GrocyColors.grocyRedBackground)),
            StockStatusItem(
                status: .belowMinStock,
                count: summary.belowMinStock,
                color: Color(.GrocyColors.grocyBlue),
                background: Color(.GrocyColors.grocyBlueBackground)
            ),
        ]
    }

    private var configuredFilter: ConfigurationAppIntent.StockFilter {
        entry.configuration.defaultFilter
    }

    private var configuredURL: URL {
        WidgetDeepLink.stock(filter: configuredFilter.caseName)
    }

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            grid(style: .compact)
                .widgetURL(configuredURL)
        case .systemMedium:
            grid(style: .regular)
        #if os(iOS)
            case .accessoryCircular:
                circularWidget
            case .accessoryRectangular:
                rectangularWidget
            case .accessoryInline:
                inlineWidget
        #endif
        default:
            grid(style: .expanded)
        }
    }

    // MARK: - Home Screen

    private func grid(style: StockStatusCell.Style) -> some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            GridRow {
                cell(items[0], style: style)
                cell(items[1], style: style)
            }
            GridRow {
                cell(items[2], style: style)
                cell(items[3], style: style)
            }
        }
    }

    @ViewBuilder
    private func cell(_ item: StockStatusItem, style: StockStatusCell.Style) -> some View {
        if style == .compact {
            // Links don't work in small widgets, the whole widget opens `widgetURL` instead.
            StockStatusCell(item: item, style: style)
        } else {
            Link(destination: item.url) {
                StockStatusCell(item: item, style: style)
            }
            .accessibilityHint(Text("Opens the stock overview with this filter"))
        }
    }

    // MARK: - Lock Screen

    /// The count of the configured filter. "All" shows the products that need attention: due soon, overdue and expired.
    private var configuredCount: Int {
        switch configuredFilter {
        case .expiringSoon: summary.dueSoon
        case .overdue: summary.overdue
        case .expired: summary.expired
        case .belowMinStock: summary.belowMinStock
        case .all: summary.dueSoon + summary.overdue + summary.expired
        }
    }

    private var configuredSymbol: String {
        switch configuredFilter {
        case .expiringSoon: MySymbols.expiringSoon
        case .overdue: MySymbols.overdue
        case .expired: MySymbols.expired
        case .belowMinStock: MySymbols.belowMinStock
        case .all: MySymbols.stockOverview
        }
    }

    private var configuredTitle: LocalizedStringKey {
        switch configuredFilter {
        case .expiringSoon: ProductStatus.expiringSoon.rawValue
        case .overdue: ProductStatus.overdue.rawValue
        case .expired: ProductStatus.expired.rawValue
        case .belowMinStock: ProductStatus.belowMinStock.rawValue
        case .all: "Due, overdue or expired"
        }
    }

    private var circularWidget: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: configuredSymbol)
                    .font(.body)
                    .widgetAccentable()
                Text(configuredCount, format: .number)
                    .font(.title3.bold())
                    .minimumScaleFactor(0.6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(configuredTitle))
        .accessibilityValue(Text(configuredCount, format: .number))
        .widgetURL(configuredURL)
    }

    private var rectangularWidget: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Stock overview")
                .font(.headline)
                .widgetAccentable()
                .lineLimit(1)
            HStack(spacing: 8) {
                ForEach(items) { item in
                    HStack(spacing: 2) {
                        Image(systemName: item.status.getIconName())
                        Text(item.count, format: .number)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(item.status.rawValue))
                    .accessibilityValue(Text(item.count, format: .number))
                }
            }
            .font(.body)
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(configuredURL)
    }

    private var inlineWidget: some View {
        Label {
            Text("\(Text(configuredTitle)): \(configuredCount)")
        } icon: {
            Image(systemName: configuredSymbol)
        }
        .widgetURL(configuredURL)
    }
}

// MARK: - Cell

private struct StockStatusCell: View {
    enum Style {
        /// Symbol and count (small widget).
        case compact
        /// Symbol, count and status (medium widget).
        case regular
        /// Symbol, count and a description (large widget).
        case expanded
    }

    let item: StockStatusItem
    let style: Style

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        content
            .padding(style == .compact ? 6 : 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: style == .compact ? .center : .leading)
            .background(background, in: ContainerRelativeShape())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(item.status.rawValue))
            .accessibilityValue(Text(item.count, format: .number))
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .compact:
            HStack(spacing: 4) {
                icon
                count
            }
            .font(.title3)
        case .regular:
            HStack(spacing: 6) {
                icon
                    .font(.title3)
                count
                    .font(.title3)
                Text(item.status.rawValue)
                    .font(.caption)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .multilineTextAlignment(.trailing)
            }
        case .expanded:
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    icon
                    count
                }
                .font(.title)
                Spacer(minLength: 0)
                Text(item.status.getDescription(amount: item.count))
                    .font(.subheadline)
                    .lineLimit(3)
            }
        }
    }

    private var icon: some View {
        Image(systemName: item.status.getIconName())
            .foregroundStyle(renderingMode == .fullColor ? item.color : .primary)
            .widgetAccentable()
            .accessibilityHidden(true)
    }

    private var count: some View {
        Text(item.count, format: .number)
            .fontWeight(.semibold)
            .monospacedDigit()
            .contentTransition(.numericText())
            .minimumScaleFactor(0.6)
            .lineLimit(1)
    }

    /// The tinted background in full color. In the accented and vibrant modes the system tints everything,
    /// so a neutral fill keeps the text readable.
    private var background: AnyShapeStyle {
        renderingMode == .fullColor ? AnyShapeStyle(item.background) : AnyShapeStyle(.fill.secondary)
    }
}

#Preview("Small", as: .systemSmall) {
    Grocy_Widget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), summary: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    Grocy_Widget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), summary: .placeholder)
}

#Preview("Large", as: .systemLarge) {
    Grocy_Widget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), summary: .placeholder)
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), summary: nil)
}

#if os(iOS)
    #Preview("Lock Screen", as: .accessoryRectangular) {
        Grocy_Widget()
    } timeline: {
        SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), summary: .placeholder)
    }
#endif
