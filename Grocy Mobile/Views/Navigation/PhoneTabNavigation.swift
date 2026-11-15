//
//  PhoneTabNavigation.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 15.11.26.
//

import SwiftData
import SwiftUI

#if os(iOS)
    /// iPhone navigation prototype: at most five tabs, so the system "More" list (with its second
    /// navigation bar) is never needed.
    ///
    /// - Places are tabs: Stock, Shopping list, Recipes, Household (chores and tasks) and a search tab.
    /// - Actions aren't: Quick Scan sits in the bottom accessory above the tab bar, on every tab.
    /// - Setup isn't a tab either: Settings and master data open from the profile button, on the current tab.
    struct PhoneTabNavigation: View {
        enum Tab: String {
            case stock, shoppingList, recipes, household, search
        }

        @Environment(GrocyViewModel.self) private var grocyVM
        @Environment(DeepLinkManager.self) private var deepLinkManager

        @AppStorage("phoneTabSelection") private var selection: Tab = .stock
        @State private var householdSection: HouseholdView.Section = .chores
        @State private var showQuickScan: Bool = false
        @State private var searchText: String = ""

        @Query private var systemConfigList: [SystemConfig]
        private var systemConfig: SystemConfig? { systemConfigList.first }

        // Same feature flags as the server; a disabled feature hides its tab.
        private var showsStock: Bool { systemConfig?.featureFlagStock != false }
        private var showsShoppingList: Bool { systemConfig?.featureFlagShoppinglist != false }
        private var showsRecipes: Bool { systemConfig?.featureFlagRecipes != false }
        private var showsHousehold: Bool { systemConfig?.featureFlagChores != false || systemConfig?.featureFlagTasks != false }

        var body: some View {
            TabView(selection: $selection) {
                SwiftUI.Tab("Stock overview", systemImage: MySymbols.stockOverview, value: Tab.stock) {
                    NavigationStack {
                        StockView()
                            .toolbar { accountButton }
                            .accountNavigationDestinations()
                    }
                }
                .hidden(!showsStock)

                SwiftUI.Tab("Shopping list", systemImage: MySymbols.shoppingList, value: Tab.shoppingList) {
                    NavigationStack {
                        ShoppingListView()
                            .toolbar { accountButton }
                            .accountNavigationDestinations()
                    }
                }
                .hidden(!showsShoppingList)

                SwiftUI.Tab("Recipes", systemImage: MySymbols.recipe, value: Tab.recipes) {
                    NavigationStack {
                        RecipesView()
                            .toolbar { accountButton }
                            .accountNavigationDestinations()
                    }
                }
                .hidden(!showsRecipes)

                SwiftUI.Tab("Household", systemImage: MySymbols.household, value: Tab.household) {
                    NavigationStack {
                        HouseholdView(section: $householdSection)
                            .toolbar { accountButton }
                            .accountNavigationDestinations()
                    }
                }
                .hidden(!showsHousehold)

                // Gets its own place in the tab bar and turns into the search field when selected (iOS 26).
                SwiftUI.Tab(value: Tab.search, role: .search) {
                    NavigationStack {
                        GlobalSearchView(searchText: $searchText)
                    }
                    // On the search tab's navigation stack, so the tab turns into the search field.
                    .searchable(text: $searchText, prompt: "Products, stock and recipes")
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            // Selecting the search tab puts the cursor straight into the field.
            .tabViewSearchActivation(.searchTabSelection)
            // Scanning is the most frequent action, so it stays one tap away on every tab
            // (the stock tab's toolbar is already full, and a tab would be a place, not an action).
            .tabViewBottomAccessory {
                Button {
                    showQuickScan = true
                } label: {
                    Label("Quick Scan", systemImage: MySymbols.barcodeScan)
                }
            }
            .fullScreenCover(isPresented: $showQuickScan) {
                NavigationStack {
                    QuickScanModeView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(role: .close) {
                                    showQuickScan = false
                                }
                            }
                        }
                }
            }
            .task {
                await grocyVM.requestData(additionalObjects: [.system_config])
            }
            .onAppear {
                openPendingDestination()
            }
            .onChange(of: deepLinkManager.pendingDestination) { _, _ in
                openPendingDestination()
            }
        }

        // MARK: - Toolbar actions

        private var accountButton: some ToolbarContent {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(value: AccountView.Route.account) {
                    Label("Settings", systemImage: MySymbols.user)
                }
            }
        }

        // MARK: - Deep links

        /// Widgets open stock, shopping list, chores and tasks. Chores and tasks share the household tab.
        private func openPendingDestination() {
            guard let destination = deepLinkManager.pendingDestination else { return }
            switch destination {
            case .stock:
                selection = .stock
            case .shoppingList:
                selection = .shoppingList
            case .chores:
                householdSection = .chores
                selection = .household
            case .tasks:
                householdSection = .tasks
                selection = .household
            }
            deepLinkManager.pendingDestination = nil
        }
    }

    #Preview(traits: .previewData) {
        PhoneTabNavigation()
            .environment(DeepLinkManager())
    }
#endif
