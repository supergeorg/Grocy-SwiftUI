//
//  WatchShoppingListView.swift
//  Grocy Watch Watch App
//
//  Created by Georg Meißner on 25.11.26.
//

import SwiftUI

/// The items of all shopping lists that aren't done yet. Tapping an item checks it off.
struct WatchShoppingListView: View {
    @Environment(WatchStore.self) private var store

    private var lists: [WidgetShoppingListSummary.List] {
        (store.snapshot?.shoppingList?.lists ?? []).filter { !$0.items.isEmpty }
    }

    var body: some View {
        List {
            if lists.isEmpty {
                ContentUnavailableView("Nothing to buy", systemImage: "cart")
            } else if lists.count == 1, let list = lists.first {
                items(of: list)
            } else {
                ForEach(lists) { list in
                    Section(list.name) {
                        items(of: list)
                    }
                }
            }
            if let snapshot = store.snapshot {
                Section {
                } footer: {
                    WatchSyncStatusView(snapshot: snapshot)
                }
            }
        }
        .navigationTitle("Shopping list")
    }

    private func items(of list: WidgetShoppingListSummary.List) -> some View {
        ForEach(list.items) { item in
            let isDone = store.isPending(shoppingListItemID: item.id)
            Button {
                store.checkOff(shoppingListItemID: item.id)
            } label: {
                HStack {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isDone ? Color.green : Color.secondary)
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .strikethrough(isDone)
                        if !item.amount.isEmpty {
                            Text(item.amount)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .disabled(isDone)
            .accessibilityValue(isDone ? Text("Done") : Text(""))
            .accessibilityHint(isDone ? Text("") : Text("Marks this item as done"))
        }
    }
}
