//
//  ContentView.swift
//  Grocy Watch Watch App
//
//  Created by Georg Meißner on 25.11.26.
//

import SwiftUI

struct ContentView: View {
    @Environment(WatchStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = store.snapshot {
                    if snapshot.isLoggedIn {
                        HomeView(snapshot: snapshot)
                    } else {
                        ContentUnavailableView(
                            "Not signed in",
                            systemImage: MySymbols.iPhone,
                            description: Text("Sign in to your Grocy server in the app on your iPhone.")
                        )
                    }
                } else {
                    ContentUnavailableView(
                        "No data yet",
                        systemImage: MySymbols.iPhone,
                        description: Text("Open Grocy on your iPhone to load the shopping list, tasks and chores.")
                    )
                }
            }
            .navigationTitle("Grocy")
        }
        .environment(\.locale, store.snapshot.map { Locale(identifier: $0.localizationKey) } ?? .current)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                store.requestRefresh()
            }
        }
    }
}

private struct HomeView: View {
    @Environment(WatchStore.self) private var store
    let snapshot: WatchSnapshot

    private var shoppingListCount: Int {
        (snapshot.shoppingList?.lists ?? []).flatMap(\.items).filter { !store.isPending(shoppingListItemID: $0.id) }.count
    }

    var body: some View {
        List {
            NavigationLink {
                WatchShoppingListView()
            } label: {
                CountRow(title: "Shopping list", systemImage: MySymbols.shoppingList, count: shoppingListCount)
            }
            ForEach([WatchDueKind.tasks, .chores], id: \.self) { kind in
                NavigationLink {
                    WatchDueItemsView(kind: kind)
                } label: {
                    CountRow(title: kind.title, systemImage: kind.systemImage, count: store.openCount(kind))
                }
            }
            Section {
            } footer: {
                WatchSyncStatusView(snapshot: snapshot)
            }
        }
    }
}

/// A row with a title and the number of open items. (`badge` isn't available on watchOS.)
private struct CountRow: View {
    let title: LocalizedStringKey
    let systemImage: String
    let count: Int

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text(count, format: .number)
                .foregroundStyle(.secondary)
        }
    }
}

/// Shows when the data was last updated, and whether check-offs wait for the iPhone.
struct WatchSyncStatusView: View {
    @Environment(WatchStore.self) private var store
    let snapshot: WatchSnapshot

    var body: some View {
        VStack(alignment: .leading) {
            if !store.pendingActions.isEmpty {
                Label("Waiting for iPhone", systemImage: MySymbols.waitingForPhone)
            }
            Text("Updated \(snapshot.updated, format: .relative(presentation: .named))")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    ContentView()
        .environment(WatchStore.shared)
}
