//
//  PhoneNavigationStyle.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// How the app is navigated on iPhone (in every width, see `applies(in:)`) and in compact width on iPad, chosen in the app settings.
enum PhoneNavigationStyle: String, CaseIterable, Identifiable {
    /// Stock, shopping list, recipes and an agenda of everything due (chores, tasks, batteries).
    case smart
    /// Tabs the user picks (at most `PhonePlace.maxTabs`).
    case tabs
    /// The sidebar of the iPad, as a list that pushes the screens.
    case sidebar

    var id: Self { self }

    static let storageKey = "phoneNavigationStyle"

    var title: LocalizedStringKey {
        switch self {
        case .smart: "Smart"
        case .tabs: "Own tabs"
        case .sidebar: "Sidebar"
        }
    }

    var footer: LocalizedStringKey {
        switch self {
        case .smart:
            "Stock, shopping list, recipes and everything that is due: products, chores, tasks and batteries. The complete lists are linked in the due tab."
        case .tabs: "Choose up to four tabs. Everything else opens from the settings button."
        case .sidebar: "All places in one list, as in the iPad sidebar."
        }
    }

    var icon: String {
        switch self {
        case .smart: MySymbols.smartNavigation
        case .tabs: MySymbols.iPhoneTabNavigation
        case .sidebar: MySymbols.sidebarNavigation
        }
    }

    #if os(iOS)
        /// Whether this setting decides the navigation, rather than the iPad one (`iPadTabNavigation`).
        ///
        /// On iPhone always, in every width: the inner display of iPhone Duo is regular width, its outer display
        /// and each half of Split View are compact. Switching to the iPad navigation there would replace the whole
        /// hierarchy, losing the selected place and the pushed screens, each time the device opens or closes.
        /// The device only picks which setting applies; the size class still decides the layout within it.
        /// On iPad, in compact width (Split View, Slide Over).
        static func applies(in horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
            UIDevice.current.userInterfaceIdiom == .phone || horizontalSizeClass == .compact
        }
    #endif
}

/// A place of the iPhone tab navigation: a tab, or a page pushed onto a tab (from the settings button
/// or from the due tab). Also the navigation value for pushing it.
enum PhonePlace: String, CaseIterable, Identifiable, Hashable {
    case stock, shoppingList, recipes, due, chores, tasks, batteries, equipment

    var id: Self { self }

    /// Four tabs plus the search tab, so the system "More" list is never needed.
    static let maxTabs = 4
    static let tabsStorageKey = "phoneTabs"

    static let smartTabs: [PhonePlace] = [.stock, .shoppingList, .recipes, .due]
    static let defaultOwnTabs: [PhonePlace] = [.stock, .shoppingList, .recipes, .chores]
    static let defaultOwnTabsValue = encode(defaultOwnTabs)

    /// The places the due tab collects, and links to as complete lists.
    static let householdPlaces: [PhonePlace] = [.chores, .tasks, .batteries, .equipment]

    static func decode(_ value: String) -> [PhonePlace] {
        var places: [PhonePlace] = []
        for place in value.split(separator: ",").compactMap({ PhonePlace(rawValue: String($0)) }) where !places.contains(place) {
            places.append(place)
        }
        // Never no tab at all, e.g. for a broken stored value.
        return places.isEmpty ? defaultOwnTabs : Array(places.prefix(maxTabs))
    }

    static func encode(_ places: [PhonePlace]) -> String {
        places.map(\.rawValue).joined(separator: ",")
    }

    var title: LocalizedStringKey {
        switch self {
        case .stock: "Stock overview"
        case .shoppingList: "Shopping list"
        case .recipes: "Recipes"
        case .due: "Due"
        case .chores: "Chores overview"
        case .tasks: "Tasks"
        case .batteries: "Batteries overview"
        case .equipment: "Equipment"
        }
    }

    /// Shorter than the screen title where that would crowd the tab bar.
    var tabTitle: LocalizedStringKey {
        switch self {
        case .chores: "Chores"
        case .batteries: "Batteries"
        default: title
        }
    }

    var icon: String {
        switch self {
        case .stock: MySymbols.stockOverview
        case .shoppingList: MySymbols.shoppingList
        case .recipes: MySymbols.recipe
        case .due: MySymbols.due
        case .chores: MySymbols.chores
        case .tasks: MySymbols.tasks
        case .batteries: MySymbols.batteries
        case .equipment: MySymbols.equipment
        }
    }

    /// Whether the server's feature flags allow this place. Without a config yet, everything is shown.
    func isEnabled(in config: SystemConfig?) -> Bool {
        guard let config else { return true }
        switch self {
        case .stock: return config.featureFlagStock
        case .shoppingList: return config.featureFlagShoppinglist
        case .recipes: return config.featureFlagRecipes
        case .due: return config.featureFlagStock || config.featureFlagChores || config.featureFlagTasks || config.featureFlagBatteries
        case .chores: return config.featureFlagChores
        case .tasks: return config.featureFlagTasks
        case .batteries: return config.featureFlagBatteries
        case .equipment: return config.featureFlagEquipment
        }
    }

    /// Whether the due tab already leads to this place.
    var isInDueTab: Bool {
        PhonePlace.householdPlaces.contains(self)
    }

    @ViewBuilder
    var view: some View {
        switch self {
        case .stock: StockView()
        case .shoppingList: ShoppingListView()
        case .recipes: RecipesView()
        case .due: DueView()
        case .chores: ChoresView()
        case .tasks: TasksView()
        case .batteries: BatteriesView()
        case .equipment: EquipmentView()
        }
    }
}

extension View {
    /// Lets a navigation stack push the places that aren't tabs.
    func phonePlaceDestinations() -> some View {
        navigationDestination(for: PhonePlace.self) { place in
            place.view
        }
    }
}
