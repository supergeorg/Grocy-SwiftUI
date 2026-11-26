//
//  WatchDueItemsView.swift
//  Grocy Watch Watch App
//
//  Created by Georg Meißner on 25.11.26.
//

import SwiftUI

/// The two lists of due items on the watch. Both come as a `WidgetDueSummary` from the iPhone.
enum WatchDueKind {
    case tasks
    case chores

    var title: LocalizedStringKey {
        switch self {
        case .tasks: "Tasks"
        case .chores: "Chores"
        }
    }

    var systemImage: String {
        switch self {
        case .tasks: "checklist"
        // The same symbols as in the iPhone app (`MySymbols`, which this target doesn't compile).
        case .chores: "list.bullet.clipboard"
        }
    }

    var emptyTitle: LocalizedStringKey {
        switch self {
        case .tasks: "No open tasks"
        case .chores: "No chores"
        }
    }

    var doneHint: Text {
        switch self {
        case .tasks: Text("Marks this task as done")
        case .chores: Text("Tracks this chore as done now")
        }
    }

    func summary(in snapshot: WatchSnapshot?) -> WidgetDueSummary? {
        switch self {
        case .tasks: snapshot?.tasks
        case .chores: snapshot?.chores
        }
    }
}

extension WatchStore {
    func isPending(_ kind: WatchDueKind, id: Int) -> Bool {
        switch kind {
        case .tasks: isPending(taskID: id)
        case .chores: isPending(choreID: id)
        }
    }

    func complete(_ kind: WatchDueKind, id: Int) {
        switch kind {
        case .tasks: complete(taskID: id)
        case .chores: trackChore(choreID: id)
        }
    }

    /// The count shown on the home screen: all open tasks, but only the chores that are due today or overdue, because
    /// chores come back after each tracking.
    func openCount(_ kind: WatchDueKind, now: Date = Date()) -> Int {
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now)) ?? now
        return (kind.summary(in: snapshot)?.items ?? []).filter { item in
            guard !isPending(kind, id: item.id) else { return false }
            switch kind {
            case .tasks: return true
            case .chores: return item.dueDate.map { $0 < endOfToday } ?? false
            }
        }.count
    }
}

/// The open tasks or the chores, the ones due first at the top. Tapping an item marks it as done.
///
/// A tracked chore comes back with its next due date once the iPhone has tracked it.
struct WatchDueItemsView: View {
    @Environment(WatchStore.self) private var store
    let kind: WatchDueKind

    private var items: [WidgetDueSummary.Item] {
        (kind.summary(in: store.snapshot)?.items ?? []).sorted { first, second in
            switch (first.dueDate, second.dueDate) {
            case (let firstDate?, let secondDate?): firstDate < secondDate
            case (.some, .none): true
            case (.none, .some): false
            case (.none, .none): first.name.localizedStandardCompare(second.name) == .orderedAscending
            }
        }
    }

    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView(kind.emptyTitle, systemImage: kind.systemImage)
            } else {
                ForEach(items) { item in
                    row(item)
                }
            }
            if let snapshot = store.snapshot {
                Section {
                } footer: {
                    WatchSyncStatusView(snapshot: snapshot)
                }
            }
        }
        .navigationTitle(kind.title)
    }

    private func row(_ item: WidgetDueSummary.Item) -> some View {
        let isDone = store.isPending(kind, id: item.id)
        let isOverdue = item.dueDate.map { $0 < Calendar.current.startOfDay(for: Date()) } ?? false
        return Button {
            store.complete(kind, id: item.id)
        } label: {
            HStack {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isDone ? Color.green : Color.secondary)
                VStack(alignment: .leading) {
                    Text(item.name)
                        .strikethrough(isDone)
                    if let dueDate = item.dueDate {
                        Text(dueDate, format: .dateTime.day().month())
                            .font(.footnote)
                            .foregroundStyle(isOverdue ? Color.red : Color.secondary)
                    }
                }
            }
        }
        .disabled(isDone)
        .accessibilityValue(isDone ? Text("Done") : (isOverdue ? Text("Overdue") : Text("")))
        .accessibilityHint(isDone ? Text("") : kind.doneHint)
    }
}
