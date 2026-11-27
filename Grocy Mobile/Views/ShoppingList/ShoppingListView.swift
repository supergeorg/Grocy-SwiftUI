//
//  ShoppingListView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftData
import SwiftUI

struct ShoppingListItemWrapped {
    let shoppingListItem: ShoppingListItem
    let product: MDProduct?
}

enum ShoppingListSortOption: String, Codable, Sendable {
    case byName
    case byAmount
}

enum ShoppingListGrouping: String, Codable, Sendable {
    case none, productGroup, defaultStore
}

enum ShoppingListSortOrderStorage: String, Codable, Sendable {
    case forward, reverse

    var sortOrder: SortOrder {
        self == .forward ? .forward : .reverse
    }

    init(from sortOrder: SortOrder) {
        self = sortOrder == .forward ? .forward : .reverse
    }
}

enum ShoppingListInteraction: Hashable, Identifiable {
    case newShoppingList
    case newShoppingListEntry
    case purchase(item: ShoppingListItem)
    case autoPurchase(item: ShoppingListItem)
    case purchaseAll(items: [ShoppingListItem])

    var id: Self { self }
}

enum AlertType: Hashable, Identifiable {
    case deleteItem(shoppingListItem: ShoppingListItem)
    case deleteShoppingList(alertSHL: ShoppingListDescription)
    case clearShoppingList(alertSHL: ShoppingListDescription)
    case clearAllDone(alertSHL: ShoppingListDescription)
    case syncWithReminders(alertSHL: ShoppingListDescription)

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .deleteItem:
            return "Do you really want to delete this item?"
        case .deleteShoppingList(let alertSHL):
            return "Are you sure you want to delete shopping list \"\(alertSHL.name)\"?"
        case .clearShoppingList(let alertSHL):
            return "Are you sure you want to empty shopping list \"\(alertSHL.name)\"?"
        case .clearAllDone:
            return "Do you really want to clear all done items?"
        case .syncWithReminders(let alertSHL):
            return "Sync \"\(alertSHL.name)\" with Reminders?"
        }
    }
}

@Observable
class ShoppingListInteractionNavigationRouter {
    var presentedInteraction: ShoppingListInteraction?

    func present(_ interaction: ShoppingListInteraction) {
        presentedInteraction = interaction
    }

    func dismiss() {
        presentedInteraction = nil
    }
}

struct ShoppingListView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(DeepLinkManager.self) private var deepLinkManager: DeepLinkManager?
    @Environment(\.openURL) private var openURL
    @Environment(\.grocyFeatures) private var features

    @Query(sort: \ShoppingListDescription.id, order: .forward) var shoppingListDescriptions: ShoppingListDescriptions
    @Query(sort: \ShoppingListItem.id, order: .forward) var shoppingList: [ShoppingListItem]
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups
    @Query(sort: \MDStore.id, order: .forward) var mdStores: MDStores
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query var userSettingsList: GrocyUserSettingsList
    /// The purchase form starts in the purchase unit, and Grocy stores the item's amount in the stock unit (#114).
    private func purchaseAmount(of item: ShoppingListItem) -> Double {
        item.purchaseAmount(product: mdProducts.first(where: { $0.id == item.productID }), conversions: mdQuantityUnitConversions)
    }

    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }

    @State private var selectedShoppingListID: Int = -1
    /// The selected list's notes as plain text. Grocy's web page edits them as rich text, so they're only shown here.
    @State private var notesText: String = ""

    @State private var firstAppear: Bool = true

    @State private var searchString: String = ""

    @AppStorage("ShoppingListView.filteredStatus") private var filteredStatus: ShoppingListStatus = .all
    @AppStorage("ShoppingListView.shoppingListGrouping") private var shoppingListGrouping: ShoppingListGrouping = .productGroup
    @AppStorage("ShoppingListView.sortOption") private var sortOption: ShoppingListSortOption = .byName
    @AppStorage("ShoppingListView.sortOrder") private var storageSortOrder: ShoppingListSortOrderStorage = .forward

    private var numFilters: Int {
        var filterCount = 0
        if filteredStatus != .all { filterCount += 1 }
        return filterCount
    }

    private var sortOrder: SortOrder {
        storageSortOrder.sortOrder
    }

    private var sortOrderBinding: Binding<SortOrder> {
        Binding(
            get: { self.sortOrder },
            set: { self.storageSortOrder = ShoppingListSortOrderStorage(from: $0) }
        )
    }

    @State private var showFilterSheet: Bool = false
    /// The form for a new item zooms out of the toolbar's add button.
    @Namespace private var addTransition

    @State private var shoppingListInteractionRouter = ShoppingListInteractionNavigationRouter()

    @State private var shlItemToDelete: ShoppingListItem? = nil
    @State private var activeAlert: AlertType?
    @State private var showRemindersAccessAlert: Bool = false
    @State private var reminderSyncSucceeded: Bool = false
    /// A failed delete or list action, shown to the person instead of only being logged.
    @State private var actionFailure: (title: LocalizedStringKey, message: String)?

    private func reportFailure(_ title: LocalizedStringKey, _ error: Error) {
        actionFailure = (title, (error as? APIError)?.displayMessage ?? error.localizedDescription)
    }

    private let dataToUpdate: [ObjectEntities] = [
        .products,
        .product_groups,
        .quantity_units,
        .quantity_unit_conversions,
        .shopping_lists,
        .shopping_list,
    ]
    /// Selects the shopping list a widget link asked for.
    private func applyPendingShoppingList() {
        guard let deepLinkManager, let listID = deepLinkManager.pendingShoppingListID else { return }
        if shoppingListDescriptions.contains(where: { $0.id == listID }) {
            selectedShoppingListID = listID
        }
        deepLinkManager.pendingShoppingListID = nil
    }

    func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    func checkBelowStock(item: ShoppingListItem) -> Bool {
        if let product = mdProducts.first(where: { $0.id == item.productID }) {
            if product.minStockAmount > item.amount {
                return true
            }
        }
        return false
    }

    private func changeDoneStatus(shoppingListItem: ShoppingListItem) async {
        shoppingListItem.done = !shoppingListItem.done
        do {
            try shoppingListItem.modelContext?.save()
            try await grocyVM.putMDObjectWithID(object: .shopping_list, id: shoppingListItem.id, content: shoppingListItem)
            GrocyLogger.info("Done status changed successfully.")
            await grocyVM.requestData(objects: [.shopping_list])
        } catch {
            GrocyLogger.error("Shopping list done status change failed. \(error)")
        }
    }

    private func deleteItem(itemToDelete: ShoppingListItem) {
        activeAlert = .deleteItem(shoppingListItem: itemToDelete)
    }

    private func deleteSHLItem(item: ShoppingListItem) async {
        do {
            try await grocyVM.deleteMDObject(object: .shopping_list, id: item.id)
            item.modelContext?.delete(item)
            GrocyLogger.info("Deleting shopping list item was successful.")
            await grocyVM.requestData(objects: [.shopping_list])
        } catch {
            GrocyLogger.error("Deleting shopping list item failed. \(error)")
            let itemName = mdProducts.first(where: { $0.id == item.productID })?.name ?? item.note
            reportFailure("Couldn't delete \"\(itemName)\"", error)
        }
    }

    var selectedShoppingList: ShoppingListDescription? {
        shoppingListDescriptions
            .filter {
                $0.id == selectedShoppingListID
            }
            .first
    }

    var sortComparator: (ShoppingListItemWrapped, ShoppingListItemWrapped) -> Bool {
        switch sortOption {
        case .byName:
            return { a, b in
                let aName = a.product?.name ?? a.shoppingListItem.note
                let bName = b.product?.name ?? b.shoppingListItem.note
                let comparison = aName.localizedCaseInsensitiveCompare(bName)
                return self.sortOrder == .forward
                    ? comparison == .orderedAscending
                    : comparison == .orderedDescending
            }
        case .byAmount:
            return { a, b in
                let aAmount = a.shoppingListItem.amount
                let bAmount = b.shoppingListItem.amount
                return self.sortOrder == .forward
                    ? aAmount < bAmount
                    : aAmount > bAmount
            }
        }
    }

    var selectedShoppingListItems: [ShoppingListItem] {
        shoppingList
            .filter {
                $0.shoppingListID == selectedShoppingListID
            }
    }

    /// The items "Add all list items to stock" purchases: those with a product that aren't done yet, in the shown order.
    private var itemsToPurchase: [ShoppingListItem] {
        selectedShoppingListItems
            .filter { $0.productID != nil && !$0.done }
            .sorted { $0.id < $1.id }
    }

    var filteredShoppingListItems: [ShoppingListItem] {
        selectedShoppingListItems
            .filter { shLItem in
                switch filteredStatus {
                case .all:
                    return true
                case .belowMinStock:
                    return checkBelowStock(item: shLItem)
                case .done:
                    return shLItem.done
                case .undone:
                    return !shLItem.done
                }
            }
            .filter { shLItem in
                if !searchString.isEmpty {
                    if let product = mdProducts.first(where: { $0.id == shLItem.productID }) {
                        return product.name.localizedCaseInsensitiveContains(searchString)
                    } else {
                        return false
                    }
                } else {
                    return true
                }
            }
    }

    var groupedShoppingList: [String: [ShoppingListItemWrapped]] {
        var dict: [String: [ShoppingListItemWrapped]] = [:]
        for listItem in filteredShoppingListItems {
            let product = mdProducts.first(where: { $0.id == listItem.productID })
            switch shoppingListGrouping {
            case .productGroup:
                let productGroup = mdProductGroups.first(where: { $0.id == product?.productGroupID })
                if dict[productGroup?.name ?? ""] == nil {
                    dict[productGroup?.name ?? ""] = []
                }
                dict[productGroup?.name ?? ""]?.append(
                    ShoppingListItemWrapped(shoppingListItem: listItem, product: product)
                )
            case .defaultStore:
                let store = mdStores.first(where: { $0.id == product?.storeID })
                if dict[store?.name ?? ""] == nil {
                    dict[store?.name ?? ""] = []
                }
                dict[store?.name ?? ""]?.append(
                    ShoppingListItemWrapped(shoppingListItem: listItem, product: product)
                )
            default:
                if dict[""] == nil {
                    dict[""] = []
                }
                dict[""]?.append(
                    ShoppingListItemWrapped(shoppingListItem: listItem, product: product)
                )
            }
        }
        return dict
    }

    var numBelowStock: Int {
        selectedShoppingListItems
            .filter { shLItem in
                checkBelowStock(item: shLItem)
            }
            .count
    }

    var numUndone: Int {
        selectedShoppingListItems
            .filter { shLItem in
                !shLItem.done
            }
            .count
    }

    var numDone: Int {
        selectedShoppingListItems
            .filter { shLItem in
                shLItem.done
            }
            .count
    }

    func deleteShoppingList(alertSHL: ShoppingListDescription) async {
        do {
            try await grocyVM.deleteMDObject(object: .shopping_lists, id: alertSHL.id)
            GrocyLogger.info("Deleting shopping list was successful.")
            await grocyVM.requestData(objects: [.shopping_lists])
        } catch {
            GrocyLogger.error("Deleting shopping list failed. \(error)")
            reportFailure("Couldn't delete \"\(alertSHL.name)\"", error)
        }
    }

    private func slAction(_ actionType: ShoppingListActionType, actionSHL: ShoppingListDescription) async {
        do {
            if actionType == .clearDone {
                // this is not clean, but was the fastest way to work around the different data types
                let jsonContent = try! JSONEncoder().encode(ShoppingListClearAction(listID: actionSHL.id, doneOnly: true))
                try await grocyVM.grocyApi.shoppingListAction(content: jsonContent, actionType: actionType)
            } else {
                try await grocyVM.shoppingListAction(content: ShoppingListAction(listID: actionSHL.id), actionType: actionType)
            }
            GrocyLogger.info("SHLAction \(actionType) successful.")
            await grocyVM.requestData(objects: [.shopping_list])
        } catch {
            GrocyLogger.error("SHLAction failed. \(error)")
            reportFailure("Couldn't update shopping list \"\(actionSHL.name)\"", error)
        }
    }

    /// Syncs the list with Reminders. The first sync of a list asks first, because it creates a list in Reminders.
    private func startReminderSync(shoppingList: ShoppingListDescription) {
        if ReminderStore.shared.isLinked(shoppingListID: shoppingList.id) {
            Task { await syncWithReminders(shoppingList: shoppingList) }
        } else {
            activeAlert = .syncWithReminders(alertSHL: shoppingList)
        }
    }

    private func syncWithReminders(shoppingList: ShoppingListDescription) async {
        do {
            if try await ReminderStore.shared.sync(shoppingList: shoppingList, grocyVM: grocyVM, requestAccess: true) != nil {
                reminderSyncSucceeded.toggle()
            }
        } catch ReminderSyncError.accessDenied {
            GrocyLogger.error("Syncing the shopping list with Reminders failed, because the access was denied.")
            showRemindersAccessAlert = true
        } catch {
            GrocyLogger.error("Syncing the shopping list with Reminders failed. \(error)")
            reportFailure("Couldn't sync \"\(shoppingList.name)\" with Reminders", error)
        }
    }

    // The capsules float in a bar above the list (the navigation layer), so their glass isn't drawn inside a list row
    @ViewBuilder
    private var filterCapsules: some View {
        if numBelowStock > 0 || numDone > 0 || numUndone > 0 {
            ShoppingListFilterActionView(
                filteredStatus: $filteredStatus,
                numBelowStock: numBelowStock,
                numDone: numDone,
                numUndone: numUndone
            )
        }
    }

    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            }
            ForEach(groupedShoppingList.sorted(by: { $0.key < $1.key }), id: \.key) { groupName, groupElements in
                #if os(macOS)
                    DisclosureGroup(
                        isExpanded: Binding.constant(true),
                        content: {
                            ForEach(
                                groupElements.sorted(by: sortComparator),
                                id: \.shoppingListItem.id,
                                content: { element in
                                    shoppingListRowWithNavigation(element: element)
                                }
                            )
                        },
                        label: {
                            if shoppingListGrouping == .productGroup, groupName.isEmpty {
                                Text("Ungrouped").italic()
                            } else if shoppingListGrouping == .none {
                                EmptyView()
                            } else {
                                Text(groupName).bold()
                            }
                        }
                    )
                #else
                    Section(
                        content: {
                            ForEach(
                                groupElements.sorted(by: sortComparator),
                                id: \.shoppingListItem.id,
                                content: { element in
                                    shoppingListRowWithNavigation(element: element)
                                }
                            )
                        },
                        header: {
                            if shoppingListGrouping == .productGroup, groupName.isEmpty {
                                Text("Ungrouped")
                                    .italic()
                            } else if shoppingListGrouping == .none {
                                EmptyView()
                            } else {
                                Text(groupName).bold()
                            }
                        }
                    )
                #endif
            }
            if !notesText.isEmpty {
                Section("Notes") {
                    Text(notesText)
                        .textSelection(.enabled)
                }
            }
        }
        .overlay {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count == 0 {
                if filteredShoppingListItems.isEmpty {
                    ContentUnavailableView {
                        Label("Shopping list is empty.", systemImage: MySymbols.shoppingList)
                    } actions: {
                        Button("Add item") {
                            shoppingListInteractionRouter.present(.newShoppingListEntry)
                        }
                    }
                }
            }
        }
        .task(id: selectedShoppingList?.notes) {
            let notes = selectedShoppingList?.notes ?? ""
            let text = notes.contains("<") ? String(await notes.htmlToAttributedStringAsync().characters) : notes
            notesText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .refreshable {
            await updateData()
        }
        .floatingTopBar {
            filterCapsules
                .padding(.vertical, Spacing.small)
        }
        .navigationTitle(selectedShoppingList?.name ?? "Shopping list")
        .toolbar {
            ToolbarItemGroup(
                placement: .navigation,
                content: {
                    Button(action: { showFilterSheet = true }) {
                        Label("Filter", systemImage: MySymbols.filter)
                    }
                    .badge(numFilters)
                    sortGroupMenu
                }
            )
            ToolbarTitleMenu {
                shoppingListActionContent
                Divider()
                shoppingListItemActionContent
                Divider()
                shoppingListReminderSyncContent
            }
            ToolbarItem(
                placement: .primaryAction,
                content: {
                    Button(
                        "Add item",
                        systemImage: MySymbols.new,
                        action: {
                            shoppingListInteractionRouter.present(.newShoppingListEntry)
                        }
                    )
                    .help("Add item")
                }
            )
            #if os(iOS)
                .matchedTransitionSource(id: ZoomTransitionID.add, in: addTransition)
            #endif
        }
        .navigationDestination(
            for: ShoppingListDescription.self,
            destination: { desc in
                ShoppingListFormView(existingShoppingListDescription: desc)
            }
        )
        .navigationDestination(
            for: ShoppingListItem.self,
            destination: { item in
                ShoppingListEntryFormView(existingShoppingListEntry: item)
            }
        )
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            if firstAppear {
                await updateData()
                // Without multiple shopping lists, Grocy only uses its first list.
                if selectedShoppingListID == -1 || !features.multipleShoppingLists {
                    selectedShoppingListID = shoppingListDescriptions.first?.id ?? -1
                }
                firstAppear = false
            }
            applyPendingShoppingList()
        }
        .onChange(of: deepLinkManager?.pendingShoppingListID) { _, _ in
            applyPendingShoppingList()
        }
        .searchable(
            text: $searchString,
            prompt: "Search"
        )
        .animation(.default, value: groupedShoppingList.count)
        .animation(.default, value: filteredStatus)
        .sheet(isPresented: $showFilterSheet) {
            NavigationStack {
                ShoppingListFilterView(filteredStatus: $filteredStatus)
                    .navigationTitle("Filter")
                    #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(
                            placement: .confirmationAction,
                            content: {
                                Button(
                                    role: .confirm,
                                    action: {
                                        showFilterSheet = false
                                    }
                                )
                            }
                        )
                        ToolbarItem(
                            placement: .cancellationAction,
                            content: {
                                Button(
                                    role: .destructive,
                                    action: {
                                        filteredStatus = .all
                                        showFilterSheet = false
                                    }
                                )
                            }
                        )
                    }
            }
            .presentationDetents([.medium])
        }
        .environment(shoppingListInteractionRouter)
        .sheet(item: $shoppingListInteractionRouter.presentedInteraction) { interaction in
            NavigationStack {
                switch interaction {
                case .newShoppingList:
                    ShoppingListFormView()
                case .newShoppingListEntry:
                    ShoppingListEntryFormView(selectedShoppingListID: selectedShoppingListID, isPopup: true)
                case .purchase(let item):
                    PurchaseProductView(directProductToPurchaseID: item.productID, productToPurchaseAmount: purchaseAmount(of: item), isPopup: true)
                case .autoPurchase(let item):
                    PurchaseProductView(
                        directProductToPurchaseID: item.productID,
                        productToPurchaseAmount: purchaseAmount(of: item),
                        autoPurchase: true,
                        isPopup: true
                    )
                case .purchaseAll(let items):
                    ShoppingListPurchaseAllView(items: items)
                }
            }
            #if os(iOS)
                .zoomTransition(sourceID: ZoomTransitionID.add, in: addTransition, if: interaction == .newShoppingListEntry)
            #endif
        }
        .alert(
            activeAlert?.title ?? "",
            isPresented: Binding(
                get: { activeAlert != nil },
                set: { if !$0 { activeAlert = nil } }
            ),
            actions: {
                Button("Cancel", role: .cancel) {}
                switch activeAlert {
                // No destructive roles: the person chose these actions, the buttons carry out their intent (HIG).
                case .deleteItem(let shoppingListItem):
                    Button("Delete") {
                        Task {
                            await deleteSHLItem(item: shoppingListItem)
                        }
                    }
                case .deleteShoppingList(let alertSHL):
                    Button("Delete") {
                        Task {
                            await deleteShoppingList(alertSHL: alertSHL)
                        }
                    }
                case .clearShoppingList(let alertSHL):
                    // Named after the result, as Grocy does, instead of a generic "Confirm".
                    Button("Clear") {
                        Task {
                            await slAction(.clear, actionSHL: alertSHL)
                        }
                    }
                case .clearAllDone(let alertSHL):
                    Button("Clear") {
                        Task {
                            await slAction(.clearDone, actionSHL: alertSHL)
                        }
                    }
                case .syncWithReminders(let alertSHL):
                    Button("Sync") {
                        Task {
                            await syncWithReminders(shoppingList: alertSHL)
                        }
                    }
                default:
                    Button("") {}
                }
            },
            message: {
                switch activeAlert {
                case .deleteItem(let shoppingListItem):
                    Text(mdProducts.first(where: { $0.id == shoppingListItem.productID })?.name ?? "Name not found")
                case .syncWithReminders(let alertSHL):
                    Text(
                        "This creates the list \"\(alertSHL.name) (Grocy Mobile)\" in Reminders. Items you check off or add there are brought into Grocy when you sync again."
                    )
                case .deleteShoppingList, .clearShoppingList, .clearAllDone:
                    Text("This can't be undone.")
                case _: Text("")
                }
            }
        )
        .alert(
            actionFailure?.title ?? "",
            isPresented: Binding(
                get: { actionFailure != nil },
                set: { if !$0 { actionFailure = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(actionFailure?.message ?? "")
            }
        )
        .alert("Reminders access is off", isPresented: $showRemindersAccessAlert) {
            Button("Open Settings") {
                if let url = ReminderStore.privacySettingsURL {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To sync shopping lists with Reminders, allow Grocy Mobile full access to Reminders in Settings.")
        }
        .sensoryFeedback(.success, trigger: reminderSyncSucceeded)
    }

    var shoppingListActionContent: some View {
        Group {
            if features.multipleShoppingLists {
                Picker(
                    selection: $selectedShoppingListID,
                    label: Text(""),
                    content: {
                        ForEach(shoppingListDescriptions, id: \.id) { shoppingListDescription in
                            Text(shoppingListDescription.name).tag(shoppingListDescription.id)
                        }
                    }
                )
                .help("Shopping list")
                Divider()
                Button(
                    action: {
                        shoppingListInteractionRouter.present(.newShoppingList)
                    },
                    label: {
                        Label("New shopping list", systemImage: MySymbols.new)
                    }
                )
                .help("New shopping list")
            }
            NavigationLink(
                value: selectedShoppingList,
                label: {
                    Label("Edit shopping list", systemImage: MySymbols.edit)
                }
            )
            .help("Edit shopping list")
            if features.multipleShoppingLists {
                Button(
                    role: .destructive,
                    action: {
                        if let selectedShoppingList {
                            activeAlert = .deleteShoppingList(alertSHL: selectedShoppingList)
                        }
                    },
                    label: {
                        Label("Delete shopping list", systemImage: MySymbols.delete)
                    }
                )
                .help("Delete shopping list")
            }
        }
    }

    var shoppingListItemActionContent: some View {
        Group {
            Button(
                role: .destructive,
                action: {
                    if let selectedShoppingList {
                        activeAlert = .clearShoppingList(alertSHL: selectedShoppingList)
                    }
                },
                label: {
                    Label("Clear list", systemImage: MySymbols.clear)
                }
            )
            .help("Clear list")
            if grocyVM.systemConfig?.featureFlagStock != false {
                Button(
                    action: {
                        shoppingListInteractionRouter.present(.purchaseAll(items: itemsToPurchase))
                    },
                    label: {
                        Label("Add all list items to stock", systemImage: MySymbols.purchase)
                    }
                )
                .help("Add all list items to stock")
                .disabled(itemsToPurchase.isEmpty)
            }
            Button(
                role: .destructive,
                action: {
                    if let selectedShoppingList {
                        activeAlert = .clearAllDone(alertSHL: selectedShoppingList)
                    }
                },
                label: {
                    Label("Clear done items", systemImage: MySymbols.done)
                }
            )
            .help("Clear done items")
            Button(
                action: {
                    Task {
                        if let selectedShoppingList {
                            await slAction(.addMissing, actionSHL: selectedShoppingList)
                        }
                    }
                },
                label: {
                    Label("Add products that are below defined min. stock amount", systemImage: MySymbols.addToShoppingList)
                }
            )
            .help("Add products that are below defined min. stock amount")
            Button(
                action: {
                    Task {
                        if let selectedShoppingList {
                            await slAction(.addExpired, actionSHL: selectedShoppingList)
                            await slAction(.addOverdue, actionSHL: selectedShoppingList)
                        }
                    }
                },
                label: {
                    Label("Add overdue/expired products", systemImage: MySymbols.addToShoppingList)
                }
            )
            .help("Add overdue/expired products")
        }
    }

    var shoppingListReminderSyncContent: some View {
        Button(
            action: {
                if let selectedShoppingList {
                    startReminderSync(shoppingList: selectedShoppingList)
                }
            },
            label: {
                Label("Sync with Reminders", systemImage: MySymbols.syncWithReminders)
                // A second text is the menu item's subtitle.
                if let lastSync = selectedShoppingList.flatMap({ ReminderStore.shared.lastSync(shoppingListID: $0.id) }) {
                    Text("Last synced \(lastSync, format: .relative(presentation: .named))")
                }
            }
        )
        .disabled(selectedShoppingList.map { ReminderStore.shared.isSyncing(.shoppingList(id: $0.id)) } ?? true)
    }

    var sortGroupMenu: some View {
        Menu(
            content: {
                Picker(
                    "Group by",
                    systemImage: MySymbols.groupBy,
                    selection: $shoppingListGrouping,
                    content: {
                        Label("None", systemImage: MySymbols.product)
                            .labelStyle(.titleAndIcon)
                            .tag(ShoppingListGrouping.none)
                        Label("Product group", systemImage: MySymbols.productGroup)
                            .labelStyle(.titleAndIcon)
                            .tag(ShoppingListGrouping.productGroup)
                        Label("Store", systemImage: MySymbols.store)
                            .labelStyle(.titleAndIcon)
                            .tag(ShoppingListGrouping.defaultStore)
                    }
                )
                #if os(iOS)
                    .pickerStyle(.menu)
                #else
                    .pickerStyle(.inline)
                #endif
                Picker(
                    "Sort category",
                    systemImage: MySymbols.sortCategory,
                    selection: $sortOption,
                    content: {
                        Label("Name", systemImage: MySymbols.name)
                            .labelStyle(.titleAndIcon)
                            .tag(ShoppingListSortOption.byName)
                        Label("Amount", systemImage: MySymbols.amount)
                            .labelStyle(.titleAndIcon)
                            .tag(ShoppingListSortOption.byAmount)
                    }
                )
                #if os(iOS)
                    .pickerStyle(.menu)
                #else
                    .pickerStyle(.inline)
                #endif
                Picker(
                    "Sort order",
                    systemImage: MySymbols.sortOrder,
                    selection: sortOrderBinding,
                    content: {
                        Label("Ascending", systemImage: MySymbols.sortForward)
                            .labelStyle(.titleAndIcon)
                            .tag(SortOrder.forward)
                        Label("Descending", systemImage: MySymbols.sortReverse)
                            .labelStyle(.titleAndIcon)
                            .tag(SortOrder.reverse)
                    }
                )
                #if os(iOS)
                    .pickerStyle(.menu)
                #else
                    .pickerStyle(.inline)
                #endif
            },
            label: {
                Label("Sort", systemImage: MySymbols.sort)
            }
        )
    }

    @ViewBuilder
    private func shoppingListRowWithNavigation(element: ShoppingListItemWrapped) -> some View {
        let isBelowStock = checkBelowStock(item: element.shoppingListItem)

        NavigationLink(
            value: element.shoppingListItem,
            label: {
                ShoppingListRowView(
                    shoppingListItem: element.shoppingListItem,
                    isBelowStock: isBelowStock,
                    product: element.product,
                    quantityUnit: mdQuantityUnits.first(where: { $0.id == element.shoppingListItem.quID }),
                    userSettings: userSettings,
                    conversions: mdQuantityUnitConversions,
                    onToggleDone: changeDoneStatus,
                    onDelete: deleteItem
                )
            }
        )
        .listRowBackground(
            isBelowStock ? Color(.GrocyColors.grocyBlueBackground) : nil
        )
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        ShoppingListView()
    }
}
