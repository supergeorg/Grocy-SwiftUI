//
//  AppSidebarNavigation.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 12.11.20.
//

import SwiftUI

struct AppSidebarNavigation: View {
    @Environment(DeepLinkManager.self) var deepLinkManager
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    @State private var selection: NavigationItem? = .none

    var body: some View {
        NavigationSplitView(
            sidebar: {
                Sidebar(selection: $selection)
                    // The server status, like Mail's offline status, at the bottom of the sidebar.
                    .safeAreaInset(edge: .bottom) {
                        ServerConnectionStatusView(style: .sidebar)
                    }
            },
            detail: {
                NavigationStack {
                    Navigation(selection: $selection)
                }
                #if os(iOS)
                    // Collapsed (iPhone), the sidebar isn't visible on the pushed screens, so they show the status too.
                    .safeAreaInset(edge: .bottom) {
                        if horizontalSizeClass == .compact {
                            ServerConnectionStatusView(style: .floating)
                        }
                    }
                #endif
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
