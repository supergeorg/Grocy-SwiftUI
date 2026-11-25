//
//  WatchTasksView.swift
//  Grocy Watch Watch App
//
//  Created by Georg Meißner on 25.11.26.
//

import SwiftUI

/// The tasks that aren't done yet, the ones due first at the top. Tapping a task marks it as done.
struct WatchTasksView: View {
    @Environment(WatchStore.self) private var store

    private var tasks: [WidgetDueSummary.Item] {
        (store.snapshot?.tasks?.items ?? []).sorted { first, second in
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
            if tasks.isEmpty {
                ContentUnavailableView("No open tasks", systemImage: "checklist")
            } else {
                ForEach(tasks) { task in
                    row(task)
                }
            }
            if let snapshot = store.snapshot {
                Section {
                } footer: {
                    WatchSyncStatusView(snapshot: snapshot)
                }
            }
        }
        .navigationTitle("Tasks")
    }

    private func row(_ task: WidgetDueSummary.Item) -> some View {
        let isDone = store.isPending(taskID: task.id)
        let isOverdue = task.dueDate.map { $0 < Calendar.current.startOfDay(for: Date()) } ?? false
        return Button {
            store.complete(taskID: task.id)
        } label: {
            HStack {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isDone ? Color.green : Color.secondary)
                VStack(alignment: .leading) {
                    Text(task.name)
                        .strikethrough(isDone)
                    if let dueDate = task.dueDate {
                        Text(dueDate, format: .dateTime.day().month())
                            .font(.footnote)
                            .foregroundStyle(isOverdue ? Color.red : Color.secondary)
                    }
                }
            }
        }
        .disabled(isDone)
        .accessibilityValue(isDone ? Text("Done") : (isOverdue ? Text("Overdue") : Text("")))
        .accessibilityHint(isDone ? Text("") : Text("Marks this task as done"))
    }
}
