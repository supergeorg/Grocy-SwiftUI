//
//  DueItemsWidget.swift
//  Grocy Widget
//
//  Created by Georg Meißner on 15.11.26.
//

import SwiftUI
import WidgetKit

// MARK: - Kind

/// The chores and tasks widgets share their layout. This describes what differs between them.
enum DueItemsKind: String {
    case chores
    case tasks

    var widgetKind: String {
        switch self {
        case .chores: WidgetSharedStore.choresKind
        case .tasks: WidgetSharedStore.tasksKind
        }
    }

    var storeKey: String {
        switch self {
        case .chores: WidgetSharedStore.choresKey
        case .tasks: WidgetSharedStore.tasksKey
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .chores: "Chores"
        case .tasks: "Tasks"
        }
    }

    var systemImage: String {
        switch self {
        case .chores: MySymbols.chores
        case .tasks: MySymbols.tasks
        }
    }

    var emptyTitle: LocalizedStringKey {
        switch self {
        case .chores: "No chores"
        case .tasks: "No open tasks"
        }
    }

    func url(filter: DueState?) -> URL {
        let filterName = filter?.caseName ?? "all"
        switch self {
        case .chores: return WidgetDeepLink.chores(filter: filterName)
        case .tasks: return WidgetDeepLink.tasks(filter: filterName)
        }
    }

    static let placeholder = WidgetDueSummary(
        items: [
            .init(id: 1, name: String(localized: "Water the plants"), dueDate: Calendar.current.date(byAdding: .day, value: -1, to: .now), assignedToMe: true),
            .init(id: 2, name: String(localized: "Take out the trash"), dueDate: .now, assignedToMe: false),
            .init(id: 3, name: String(localized: "Clean the kitchen"), dueDate: Calendar.current.date(byAdding: .day, value: 2, to: .now), assignedToMe: true),
            .init(
                id: 4,
                name: String(localized: "Change the bed sheets"),
                dueDate: Calendar.current.date(byAdding: .day, value: 9, to: .now),
                assignedToMe: false
            ),
        ],
        dueSoonDays: 5,
        updated: .now
    )
}

// MARK: - Due state

/// The due state of a chore or task, worked out when the widget renders.
///
/// It uses the same rules as the chores and tasks screens: "due soon" includes today.
enum DueState {
    case overdue
    case dueToday
    case dueSoon
    case later
    case noDueDate

    init(dueDate: Date?, referenceDate: Date, dueSoonDays: Int) {
        guard let days = DueState.days(from: referenceDate, to: dueDate) else {
            self = .noDueDate
            return
        }
        switch days {
        case ..<0: self = .overdue
        case 0: self = .dueToday
        default: self = days <= dueSoonDays ? .dueSoon : .later
        }
    }

    static func days(from referenceDate: Date, to date: Date?) -> Int? {
        guard let date else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: referenceDate), to: calendar.startOfDay(for: date)).day
    }

    /// The filter name used in the deep link (`ChoreStatus` / `TaskStatus` case names).
    var caseName: String {
        switch self {
        case .overdue: "overdue"
        case .dueToday: "dueToday"
        case .dueSoon: "dueSoon"
        case .later, .noDueDate: "all"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .overdue: "Overdue"
        case .dueToday: "Due today"
        case .dueSoon: "Due soon"
        case .later: "Later"
        case .noDueDate: "No due date"
        }
    }

    var systemImage: String {
        switch self {
        case .overdue: MySymbols.overdue
        case .dueToday: MySymbols.today
        case .dueSoon: MySymbols.soon
        case .later, .noDueDate: MySymbols.widgetNoDueDate
        }
    }

    var color: Color {
        switch self {
        case .overdue: Color(.GrocyColors.grocyRed)
        case .dueToday: Color(.GrocyColors.grocyBlue)
        case .dueSoon: Color(.GrocyColors.grocyYellow)
        case .later, .noDueDate: .secondary
        }
    }
}

// MARK: - Timeline

struct DueItemsEntry: TimelineEntry {
    let date: Date
    let summary: WidgetDueSummary?
    let onlyAssignedToMe: Bool

    /// The entries sorted by due date. Entries without a due date come last.
    var items: [WidgetDueSummary.Item] {
        (summary?.items ?? [])
            .filter { !onlyAssignedToMe || $0.assignedToMe }
            .sorted { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case (let lhsDate?, let rhsDate?):
                    return lhsDate == rhsDate ? lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending : lhsDate < rhsDate
                case (nil, _?):
                    return false
                case (_?, nil):
                    return true
                case (nil, nil):
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
            }
    }

    func state(of item: WidgetDueSummary.Item) -> DueState {
        DueState(dueDate: item.dueDate, referenceDate: date, dueSoonDays: summary?.dueSoonDays ?? 5)
    }

    /// The number of entries per filter, counted like the filter capsules in the app.
    func count(_ state: DueState) -> Int {
        let soonDays = summary?.dueSoonDays ?? 5
        return items.count { item in
            guard let days = DueState.days(from: date, to: item.dueDate) else { return false }
            switch state {
            case .overdue: return days < 0
            case .dueToday: return days == 0
            case .dueSoon: return (0...soonDays).contains(days)
            case .later, .noDueDate: return false
            }
        }
    }

    /// Overdue and due today: the entries that need doing now.
    var dueNowCount: Int {
        count(.overdue) + count(.dueToday)
    }
}

struct DueItemsProvider: AppIntentTimelineProvider {
    let kind: DueItemsKind

    func placeholder(in context: Context) -> DueItemsEntry {
        DueItemsEntry(date: Date(), summary: DueItemsKind.placeholder, onlyAssignedToMe: false)
    }

    func snapshot(for configuration: DueWidgetConfigurationIntent, in context: Context) async -> DueItemsEntry {
        let summary = load() ?? (context.isPreview ? DueItemsKind.placeholder : nil)
        return DueItemsEntry(date: Date(), summary: summary, onlyAssignedToMe: configuration.onlyAssignedToMe)
    }

    func timeline(for configuration: DueWidgetConfigurationIntent, in context: Context) async -> Timeline<DueItemsEntry> {
        // The app reloads the timeline after each sync. A second entry at midnight moves "due soon" to "due today" and "due today" to "overdue".
        let summary = load()
        let now = Date()
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now)
        let entries = [now, midnight].map { DueItemsEntry(date: $0, summary: summary, onlyAssignedToMe: configuration.onlyAssignedToMe) }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func load() -> WidgetDueSummary? {
        WidgetSharedStore.load(WidgetDueSummary.self, forKey: kind.storeKey)
    }
}

// MARK: - Views

struct DueItemsWidgetView: View {
    let kind: DueItemsKind
    let entry: DueItemsEntry

    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        Group {
            if entry.summary == nil {
                WidgetNoDataView()
            } else {
                content
            }
        }
        .widgetURL(kind.url(filter: entry.count(.overdue) > 0 ? .overdue : nil))
        .environment(\.locale, WidgetSharedStore.locale)
    }

    @ViewBuilder
    private var content: some View {
        switch widgetFamily {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 6) {
                WidgetHeaderView(title: Text(kind.title), systemImage: kind.systemImage)
                Spacer(minLength: 0)
                ForEach([DueState.overdue, .dueToday, .dueSoon], id: \.self) { state in
                    DueCountRow(state: state, count: entry.count(state))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        case .systemMedium:
            VStack(alignment: .leading, spacing: 6) {
                WidgetHeaderView(
                    title: Text(kind.title),
                    systemImage: kind.systemImage,
                    count: entry.dueNowCount,
                    countDescription: Text("\(entry.dueNowCount) overdue or due today")
                )
                itemList(maxItems: 3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        #if os(iOS)
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 0) {
                        Image(systemName: kind.systemImage)
                            .font(.body)
                            .widgetAccentable()
                        Text(entry.dueNowCount, format: .number)
                            .font(.title3.bold())
                            .minimumScaleFactor(0.6)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(kind.title))
                .accessibilityValue(Text("\(entry.dueNowCount) overdue or due today"))
            case .accessoryInline:
                Label {
                    Text("\(Text(kind.title)): \(entry.dueNowCount) due")
                } icon: {
                    Image(systemName: kind.systemImage)
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text(kind.title)
                        .font(.headline)
                        .widgetAccentable()
                    if entry.items.isEmpty {
                        Text(kind.emptyTitle)
                    } else {
                        ForEach(entry.items.prefix(2)) { item in
                            DueItemRow(item: item, state: entry.state(of: item), referenceDate: entry.date, isCompact: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
        #endif
        default:
            VStack(alignment: .leading, spacing: 8) {
                WidgetHeaderView(
                    title: Text(kind.title),
                    systemImage: kind.systemImage,
                    count: entry.dueNowCount,
                    countDescription: Text("\(entry.dueNowCount) overdue or due today")
                )
                HStack(spacing: 6) {
                    ForEach([DueState.overdue, .dueToday, .dueSoon], id: \.self) { state in
                        Link(destination: kind.url(filter: state)) {
                            DueCountChip(state: state, count: entry.count(state))
                        }
                        .accessibilityHint(Text("Opens the list with this filter"))
                    }
                }
                itemList(maxItems: 9)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func itemList(maxItems: Int) -> some View {
        let items = entry.items
        let shown = items.prefix(maxItems)
        return VStack(alignment: .leading, spacing: 4) {
            if items.isEmpty {
                WidgetMessageView(systemImage: MySymbols.widgetAllDone, title: kind.emptyTitle)
            } else {
                ForEach(shown) { item in
                    DueItemRow(item: item, state: entry.state(of: item), referenceDate: entry.date)
                }
                if items.count > shown.count {
                    Text("+ \(items.count - shown.count) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

/// A chore or task with its due date, for example "Clean the kitchen – In 2 days".
private struct DueItemRow: View {
    let item: WidgetDueSummary.Item
    let state: DueState
    let referenceDate: Date
    var isCompact: Bool = false

    @Environment(\.locale) private var locale
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var dueText: String? {
        guard let dueDate = item.dueDate, let days = DueState.days(from: referenceDate, to: dueDate) else { return nil }
        // "In 3 days" reads well for the coming week. Further away, a date is easier to read than "1,198 days ago".
        guard abs(days) <= 7 else {
            let isSameYear = Calendar.current.isDate(dueDate, equalTo: referenceDate, toGranularity: .year)
            let format: Date.FormatStyle = isSameYear ? .dateTime.day().month(.abbreviated) : .dateTime.day().month(.abbreviated).year()
            return dueDate.formatted(format.locale(locale))
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        formatter.formattingContext = .beginningOfSentence
        return formatter.localizedString(from: DateComponents(day: days))
    }

    var body: some View {
        HStack(spacing: 6) {
            if !isCompact {
                Image(systemName: state.systemImage)
                    .font(.caption)
                    .foregroundStyle(renderingMode == .fullColor ? state.color : .secondary)
                    .widgetAccentable()
            }
            Text(verbatim: item.name)
                .font(isCompact ? .body : .subheadline)
                .lineLimit(1)
            Spacer(minLength: 4)
            if let dueText {
                Text(verbatim: dueText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: item.name))
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: Text {
        switch (state, dueText) {
        case (.overdue, let dueText?), (.dueToday, let dueText?), (.dueSoon, let dueText?):
            Text("\(Text(state.title)), \(dueText)")
        case (_, let dueText?):
            Text(verbatim: dueText)
        case (_, nil):
            Text(DueState.noDueDate.title)
        }
    }
}

/// A count with its state, for the small widget.
private struct DueCountRow: View {
    let state: DueState
    let count: Int

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: state.systemImage)
                .foregroundStyle(renderingMode == .fullColor ? state.color : .primary)
                .widgetAccentable()
                .frame(width: 20)
            Text(state.title)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 4)
            Text(count, format: .number)
                .font(.headline)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.title))
        .accessibilityValue(Text(count, format: .number))
    }
}

/// A tappable count with its state, for the large widget.
private struct DueCountChip: View {
    let state: DueState
    let count: Int

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: state.systemImage)
                    .foregroundStyle(renderingMode == .fullColor ? state.color : .primary)
                    .widgetAccentable()
                Text(count, format: .number)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .font(.title3)
            Text(state.title)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.secondary, in: ContainerRelativeShape())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.title))
        .accessibilityValue(Text(count, format: .number))
    }
}

// MARK: - Widgets

private var dueItemsFamilies: [WidgetFamily] {
    #if os(iOS)
        [.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline]
    #else
        [.systemSmall, .systemMedium, .systemLarge]
    #endif
}

struct ChoresWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: DueItemsKind.chores.widgetKind, intent: DueWidgetConfigurationIntent.self, provider: DueItemsProvider(kind: .chores)) {
            entry in
            DueItemsWidgetView(kind: .chores, entry: entry)
                .grocyWidgetBackground()
        }
        .configurationDisplayName("Chores")
        .description("Shows which chores are overdue, due today and due soon.")
        .supportedFamilies(dueItemsFamilies)
    }
}

struct TasksWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: DueItemsKind.tasks.widgetKind, intent: DueWidgetConfigurationIntent.self, provider: DueItemsProvider(kind: .tasks)) {
            entry in
            DueItemsWidgetView(kind: .tasks, entry: entry)
                .grocyWidgetBackground()
        }
        .configurationDisplayName("Tasks")
        .description("Shows your open tasks and when they are due.")
        .supportedFamilies(dueItemsFamilies)
    }
}

#Preview("Chores small", as: .systemSmall) {
    ChoresWidget()
} timeline: {
    DueItemsEntry(date: .now, summary: DueItemsKind.placeholder, onlyAssignedToMe: false)
}

#Preview("Chores medium", as: .systemMedium) {
    ChoresWidget()
} timeline: {
    DueItemsEntry(date: .now, summary: DueItemsKind.placeholder, onlyAssignedToMe: false)
    DueItemsEntry(date: .now, summary: WidgetDueSummary(items: [], dueSoonDays: 5, updated: .now), onlyAssignedToMe: false)
}

#Preview("Tasks large", as: .systemLarge) {
    TasksWidget()
} timeline: {
    DueItemsEntry(date: .now, summary: DueItemsKind.placeholder, onlyAssignedToMe: false)
    DueItemsEntry(date: .now, summary: nil, onlyAssignedToMe: false)
}

#if os(iOS)
    #Preview("Tasks Lock Screen", as: .accessoryRectangular) {
        TasksWidget()
    } timeline: {
        DueItemsEntry(date: .now, summary: DueItemsKind.placeholder, onlyAssignedToMe: false)
    }
#endif
