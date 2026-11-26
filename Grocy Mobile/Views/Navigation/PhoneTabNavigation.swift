//
//  PhoneTabNavigation.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 15.11.26.
//

import SwiftData
import SwiftUI

#if os(iOS)
    /// iPhone tab navigation: at most four places plus the search tab, so the system "More" list
    /// (with its second navigation bar) is never needed. Used by the smart style (`PhonePlace.smartTabs`)
    /// and by the own tabs style (the user's choice).
    ///
    /// - Places that aren't tabs open from the settings button (`AccountView`).
    /// - Actions aren't tabs: Quick Scan sits in the bottom accessory above the tab bar, while the search tab is selected
    ///   (scanning a barcode is a way of searching).
    /// - Setup isn't a tab either: Settings and master data open from the settings button, in its own toolbar group.
    struct PhoneTabNavigation: View {
        enum Selection: Hashable {
            case place(PhonePlace)
            case search
        }

        /// The tabs, in order. Places the server disabled are hidden.
        var places: [PhonePlace]

        @Environment(GrocyViewModel.self) private var grocyVM
        @Environment(DeepLinkManager.self) private var deepLinkManager

        /// The last tab is remembered, except search: selecting the search tab activates its field,
        /// so restoring it would open the app in search mode, with the keyboard up and the tab bar collapsed.
        @AppStorage("phoneTabSelection") private var storedSelection: String = PhonePlace.stock.rawValue
        @State private var selection: Selection = .place(.stock)
        /// One navigation path per tab, so deep links can push a place that isn't a tab.
        @State private var paths: [PhonePlace: NavigationPath] = [:]
        @State private var showQuickScan: Bool = false
        /// The search field has the keyboard: it then floats above the keyboard, and Quick Scan moves above it.
        @FocusState private var isSearchFieldFocused: Bool
        @Namespace private var quickScanTransition
        @State private var searchText: String = ""
        /// The search tab's own path, so Quick Scan shows only on the search itself, not on a result opened from it.
        @State private var searchPath = NavigationPath()

        @Query private var systemConfigList: [SystemConfig]
        private var systemConfig: SystemConfig? { systemConfigList.first }

        // For the due tab's badge.
        @AppStorage(DueKind.hiddenKindsStorageKey) private var hiddenDueKinds: String = ""
        @Query(filter: #Predicate<StockElement> { $0.amountAggregated > 0 }) private var stock: Stock
        @Query private var volatileStockList: [VolatileStock]
        @Query private var chores: Chores
        @Query(filter: #Predicate<GrocyTask> { !$0.done }) private var openTasks: GrocyTasks
        @Query private var batteries: Batteries
        @Query private var userSettingsList: GrocyUserSettingsList

        private var visiblePlaces: [PhonePlace] {
            places.filter { $0.isEnabled(in: systemConfig) }
        }

        /// Expired, overdue and due today; "due soon" and "below min. stock" don't need attention yet.
        ///
        /// Counted on every update of the tab bar, so without the products below min. stock (never counted, and they
        /// need all products) and without sorting.
        private var urgentDueCount: Int {
            guard places.contains(.due) else { return 0 }
            return DueItem.items(
                stock: stock,
                volatileStock: volatileStockList.first,
                mdProducts: [],
                chores: chores,
                tasks: openTasks,
                batteries: batteries,
                userSettings: userSettingsList.first,
                systemConfig: systemConfig,
                hiddenKinds: DueKind.hiddenKinds(from: hiddenDueKinds).union([.belowMinStock]),
                sorted: false
            )
            .count(where: { $0.urgency.needsAttention })
        }

        var body: some View {
            TabView(selection: $selection) {
                ForEach(places) { place in
                    Tab(place.tabTitle, systemImage: place.icon, value: Selection.place(place)) {
                        NavigationStack(path: path(for: place)) {
                            place.view
                                .toolbar { accountButton }
                                .accountNavigationDestinations()
                                .phonePlaceDestinations()
                        }
                    }
                    .badge(place == .due ? urgentDueCount : 0)
                    .hidden(!place.isEnabled(in: systemConfig))
                }

                // Gets its own place in the tab bar and turns into the search field when selected (iOS 26).
                Tab(value: Selection.search, role: .search) {
                    NavigationStack(path: $searchPath) {
                        GlobalSearchView(searchText: $searchText)
                            // Only on the search tab: scanning a barcode is another way of searching
                            // (the stock tab's toolbar is already full, and a tab would be a place, not an action).
                            // Only on the search screen itself, not on a result opened from it (e.g. a product's
                            // form), where scanning isn't searching anymore.
                            .safeAreaInset(edge: .bottom) {
                                QuickScanSearchButton(
                                    // Opening the scanner hides the keyboard: the button stays up meanwhile, so it
                                    // doesn't slide under the field while the sheet zooms out of it.
                                    isSearchFieldFocused: isSearchFieldFocused || showQuickScan,
                                    transitionNamespace: quickScanTransition
                                ) { showQuickScan = true }
                            }
                    }
                    // On the search tab's navigation stack, so the tab turns into the search field.
                    .searchable(text: $searchText, prompt: "Products, recipes and more")
                    .searchFocused($isSearchFieldFocused)
                }
            }
            // Rebuilt when the chosen tabs change: otherwise the tab bar keeps an item's old symbol by position
            // (e.g. the Chores tab showed the Tasks symbol). Selection and paths are kept outside the TabView.
            .id(PhonePlace.encode(places))
            // A tab bar in compact width; in regular width (the inner display of iPhone Duo) it can also
            // become a sidebar, with the same places, so the hierarchy doesn't change when the device opens.
            .tabViewStyle(.sidebarAdaptable)
            .tabBarMinimizeBehavior(.onScrollDown)
            // Selecting the search tab puts the cursor straight into the field.
            .tabViewSearchActivation(.searchTabSelection)
            // Only while the server can't be used: says so on every tab, without covering anything.
            .serverStatusAccessory(isShown: grocyVM.connectionProblem != nil)
            .quickScanSheet(isPresented: $showQuickScan, zoomSource: (QuickScanSearchButton.transitionID, quickScanTransition))
            .task {
                await grocyVM.requestData(additionalObjects: [.system_config])
            }
            .onAppear {
                if let place = PhonePlace(rawValue: storedSelection), visiblePlaces.contains(place) {
                    selection = .place(place)
                } else if let first = visiblePlaces.first {
                    selection = .place(first)
                }
                openPendingDestination()
            }
            .onChange(of: deepLinkManager.pendingDestination) { _, _ in
                openPendingDestination()
            }
            .onChange(of: selection) { _, newSelection in
                if case .place(let place) = newSelection {
                    storedSelection = place.rawValue
                }
            }
        }

        private func path(for place: PhonePlace) -> Binding<NavigationPath> {
            Binding(
                get: { paths[place] ?? NavigationPath() },
                set: { paths[place] = $0 }
            )
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

        /// Widgets open stock, shopping list, chores and tasks. A place without a tab is pushed:
        /// onto the due tab for chores and tasks, if there is one, otherwise onto the first tab.
        private func openPendingDestination() {
            guard let destination = deepLinkManager.pendingDestination else { return }
            switch destination {
            case .stock: open(.stock)
            case .shoppingList: open(.shoppingList)
            case .chores: open(.chores)
            case .tasks: open(.tasks)
            }
            deepLinkManager.pendingDestination = nil
        }

        private func open(_ place: PhonePlace) {
            if visiblePlaces.contains(place) {
                paths[place] = NavigationPath()
                selection = .place(place)
                return
            }
            let host = place.isInDueTab && visiblePlaces.contains(.due) ? PhonePlace.due : visiblePlaces.first
            guard let host else { return }
            var path = NavigationPath()
            path.append(place)
            paths[host] = path
            selection = .place(host)
        }
    }

    /// Quick Scan on the search screen, across the whole width, right above the search field.
    ///
    /// A tab view bottom accessory stays behind the keyboard, and the navigation bar is hidden while searching.
    /// The bottom safe area moves up with the keyboard, but while the field has the keyboard, it floats above the
    /// keyboard and covers the safe area's lower edge, so the button keeps that field's height free below it.
    /// Without the keyboard, the field is back in the tab bar, below the safe area.
    /// The scanner zooms out of the button (iOS 26 zoom transition).
    private struct QuickScanSearchButton: View {
        static let transitionID = "quickScan"

        let isSearchFieldFocused: Bool
        let transitionNamespace: Namespace.ID
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Label("Quick Scan", systemImage: MySymbols.barcodeScan)
                    .frame(maxWidth: .infinity, minHeight: Sizes.minimumHitTarget)
            }
            .buttonStyle(.glassProminent)
            .matchedTransitionSource(id: Self.transitionID, in: transitionNamespace)
            .padding(.horizontal, Spacing.large)
            .padding(.bottom, isSearchFieldFocused ? Sizes.floatingSearchFieldHeight + Spacing.medium : Spacing.small)
            .animation(.smooth, value: isSearchFieldFocused)
        }
    }

    #Preview("Smart", traits: .previewData) {
        PhoneTabNavigation(places: PhonePlace.smartTabs)
            .environment(DeepLinkManager())
    }

    #Preview("Own tabs", traits: .previewData) {
        PhoneTabNavigation(places: [.stock, .shoppingList, .chores, .tasks])
            .environment(DeepLinkManager())
    }
#endif
