//
//  AppSidebarNavigation.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 12.11.20.
//

import SwiftUI

struct AppSidebarNavigation: View {
    @Environment(DeepLinkManager.self) var deepLinkManager
    @Environment(GrocyViewModel.self) private var grocyVM
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    @State private var selection: NavigationItem? = .none

    var body: some View {
        NavigationSplitView(
            sidebar: {
                Sidebar(selection: $selection)
                    // Only while the server can't be used, at the bottom of the sidebar, like Mail's offline status.
                    .serverStatusBar(isShown: grocyVM.connectionProblem != nil)
            },
            detail: {
                NavigationStack {
                    Navigation(selection: $selection)
                }
                #if os(iOS)
                    // Collapsed (iPhone), the sidebar isn't visible on the screens opened from it, so they show it too.
                    .serverStatusBar(isShown: grocyVM.connectionProblem != nil && horizontalSizeClass == .compact)
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
