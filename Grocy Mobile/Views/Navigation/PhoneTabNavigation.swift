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
    /// - Actions aren't: Quick Scan sits in the bottom accessory above the tab bar, while the search tab is selected
    ///   (scanning a barcode is a way of searching).
    /// - Setup isn't a tab either: Settings and master data open from the settings button, in its own toolbar group.
    struct PhoneTabNavigation: View {
        enum Tab: String {
            case stock, shoppingList, recipes, household, search
        }

        @Environment(GrocyViewModel.self) private var grocyVM
        @Environment(DeepLinkManager.self) private var deepLinkManager

        /// The last tab is remembered, except search: selecting the search tab activates its field,
        /// so restoring it would open the app in search mode, with the keyboard up and the tab bar collapsed.
        @AppStorage("phoneTabSelection") private var storedSelection: Tab = .stock
        @State private var selection: Tab = .stock
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
                    .searchable(text: $searchText, prompt: "Products, recipes and more")
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            // Selecting the search tab puts the cursor straight into the field.
            .tabViewSearchActivation(.searchTabSelection)
            // Only on the search tab: scanning a barcode is another way of searching
            // (the stock tab's toolbar is already full, and a tab would be a place, not an action).
            .tabViewBottomAccessory(isEnabled: selection == .search) {
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
                selection = storedSelection == .search ? .stock : storedSelection
                openPendingDestination()
            }
            .onChange(of: deepLinkManager.pendingDestination) { _, _ in
                openPendingDestination()
            }
            .onChange(of: selection) { _, newSelection in
                if newSelection != .search {
                    storedSelection = newSelection
                }
            }
        }

        // MARK: - Toolbar actions

        /// In its own glass group, separated from the screen's own buttons (filter, sort, …), so it reads as
        /// app-wide setup rather than as an action of the current list.
        /// Tab-level items come before the screen's own leading items, so the spacer goes after the button.
        @ToolbarContentBuilder
        private var accountButton: some ToolbarContent {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(value: AccountView.Route.account) {
                    Label("Settings", systemImage: MySymbols.settings)
                }
            }
            ToolbarSpacer(.fixed, placement: .topBarLeading)
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
