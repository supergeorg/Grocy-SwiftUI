//
//  AppSidebarNavigation.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 12.11.20.
//

import SwiftUI

struct AppSidebarNavigation: View {
    @Environment(DeepLinkManager.self) var deepLinkManager

    @State private var selection: NavigationItem? = .none

    var body: some View {
        NavigationSplitView(
            sidebar: {
                Sidebar(selection: $selection)
            },
            detail: {
                NavigationStack {
                    Navigation(selection: $selection)
                }
            }
        )
        .onAppear {
            openPendingDestination()
        }
        .onChange(of: deepLinkManager.pendingDestination) { _, _ in
            openPendingDestination()
        }
    }

    private func openPendingDestination() {
        guard let destination = deepLinkManager.pendingDestination else { return }
        switch destination {
        case .stock:
            selection = .stockOverview
        case .shoppingList:
            selection = .shoppingList
        case .chores:
            selection = .choresOverview
        case .tasks:
            selection = .tasks
        }
        deepLinkManager.pendingDestination = nil
    }
}

#Preview {
    AppSidebarNavigation()
}
