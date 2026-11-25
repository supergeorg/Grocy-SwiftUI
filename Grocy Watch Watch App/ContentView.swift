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
                            systemImage: "iphone",
                            description: Text("Sign in to your Grocy server in the app on your iPhone.")
                        )
                    }
                } else {
                    ContentUnavailableView(
                        "No data yet",
                        systemImage: "iphone",
                        description: Text("Open Grocy on your iPhone to load the shopping list and tasks.")
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

    private var taskCount: Int {
        (snapshot.tasks?.items ?? []).filter { !store.isPending(taskID: $0.id) }.count
    }

    var body: some View {
        List {
            NavigationLink {
                WatchShoppingListView()
            } label: {
                Label("Shopping list", systemImage: "cart")
            }
            .badge(shoppingListCount)
            NavigationLink {
                WatchTasksView()
            } label: {
                Label("Tasks", systemImage: "checklist")
            }
            .badge(taskCount)
            Section {
            } footer: {
                WatchSyncStatusView(snapshot: snapshot)
            }
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
                Label("Waiting for iPhone", systemImage: "iphone.radiowaves.left.and.right")
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
