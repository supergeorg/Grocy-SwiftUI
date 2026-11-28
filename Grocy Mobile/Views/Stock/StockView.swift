//
//  StockView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import SwiftData
import SwiftUI

enum StockColumn {
    case product, productGroup, amount, value, nextDueDate, caloriesPerStockQU, calories
}

enum StockInteraction: Hashable, Identifiable {
    case purchaseProduct
    case consumeProduct
    case transferProduct
    case inventoryProduct
    case stockJournal
    case addToShL(stockElement: StockElement)
    case productPurchase(stockElement: StockElement)
    case productConsume(stockElement: StockElement)
    case productTransfer(stockElement: StockElement)
    case productInventory(stockElement: StockElement)
    case productOverview(stockElement: StockElement)
    case productJournal(stockElement: StockElement)
    case productEntries(stockElement: StockElement)
    case productRecipes(stockElement: StockElement)
    case editProduct(stockElement: StockElement)

    var id: Self { self }

    /// The product's stock element, for the interactions of one product.
    private var stockElement: StockElement? {
        switch self {
        case .purchaseProduct, .consumeProduct, .transferProduct, .inventoryProduct, .stockJournal: nil
        case .addToShL(let element), .productPurchase(let element), .productConsume(let element), .productTransfer(let element),
            .productInventory(let element), .productOverview(let element), .productJournal(let element), .productEntries(let element),
            .productRecipes(let element), .editProduct(let element):
            element
        }
    }

    /// The case without its element, to compare the kind of interaction.
    private var kind: Int {
        switch self {
        case .purchaseProduct: 0
        case .consumeProduct: 1
        case .transferProduct: 2
        case .inventoryProduct: 3
        case .stockJournal: 4
        case .addToShL: 5
        case .productPurchase: 6
        case .productConsume: 7
        case .productTransfer: 8
        case .productInventory: 9
        case .productOverview: 10
        case .productJournal: 11
        case .productEntries: 12
        case .productRecipes: 13
        case .editProduct: 14
        }
    }

    // Compared by the element's identity, not its values: while a sheet is open, a stock sync can delete the element
    // (the product left the stock), and reading a deleted model's attributes crashes SwiftData.
    static func == (lhs: StockInteraction, rhs: StockInteraction) -> Bool {
        lhs.kind == rhs.kind && lhs.stockElement.map(ObjectIdentifier.init) == rhs.stockElement.map(ObjectIdentifier.init)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
        hasher.combine(stockElement.map(ObjectIdentifier.init))
    }
}

enum StockGrouping: String, Codable, Sendable {
    case none, productGroup, nextDueDate, lastPurchased, minStockAmount, parentProduct, defaultLocation
}

enum StockSortCategory: String, Codable, Sendable {
    case name, dueDate, amount
}

enum StockSortOrderStorage: String, Codable, Sendable {
    case forward, reverse

    var sortOrder: SortOrder {
        self == .forward ? .forward : .reverse
    }

    init(from sortOrder: SortOrder) {
        self = sortOrder == .forward ? .forward : .reverse
    }
}

enum StockProductStatusStorage: String, Codable, Sendable {
    case all, belowMinStock, expiringSoon, overdue, expired

    var productStatus: ProductStatus {
        switch self {
        case .all:
            return .all
        case .belowMinStock:
            return .belowMinStock
        case .expiringSoon:
            return .expiringSoon
        case .overdue:
            return .overdue
        case .expired:
            return .expired
        }
    }

    init(from productStatus: ProductStatus) {
        switch productStatus {
        case .all:
            self = .all
        case .belowMinStock:
            self = .belowMinStock
        case .expiringSoon:
            self = .expiringSoon
        case .overdue:
            self = .overdue
        case .expired:
            self = .expired
        }
    }
}

@Observable
class StockInteractionNavigationRouter {
    var presentedInteraction: StockInteraction?

    func present(_ interaction: StockInteraction) {
        presentedInteraction = interaction
    }

    func dismiss() {
        presentedInteraction = nil
    }
}

struct StockView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<StockElement> { $0.amountAggregated > 0 }) var stock: [StockElement]
    @Query(filter: #Predicate<StockLocation> { $0.amount > 0 }) var stockLocations: StockLocations
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups
    @Query(sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \ShoppingListItem.id, order: .forward) var shoppingList: [ShoppingListItem]
    @Query(sort: \StockEntry.id, order: .forward) var stockEntries: StockEntries
    @Query var volatileStockList: [VolatileStock]
    var volatileStock: VolatileStock? {
        return volatileStockList.first
    }
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        return userSettingsList.first
    }
    @State private var searchString: String = ""
    @State private var showingFilterSheet = false

    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        /// The stock interaction sheets zoom out of the toolbar buttons that open them.
        @Namespace private var stockInteractionTransition
    #endif

    @Environment(DeepLinkManager.self) var deepLinkManager
    @Environment(\.grocyFeatures) private var features

    @AppStorage("StockView.stockGrouping") private var stockGrouping: StockGrouping = .none
    @AppStorage("StockView.sortCategory") private var sortCategory: StockSortCategory = .name
    @AppStorage("StockView.sortOrder") private var storageSortOrder: StockSortOrderStorage = .forward
    @AppStorage("StockView.filteredLocationID") private var filteredLocationID: Int?
    @AppStorage("StockView.filteredProductGroupID") private var filteredProductGroupID: Int?
    @AppStorage("StockView.filteredStatus") private var storageFilteredStatus: StockProductStatusStorage = .all

    private var sortOrder: SortOrder {
        storageSortOrder.sortOrder
    }

    private var sortOrderBinding: Binding<SortOrder> {
        Binding(
            get: { self.sortOrder },
            set: { self.storageSortOrder = StockSortOrderStorage(from: $0) }
        )
    }

    private var filteredStatus: ProductStatus {
        storageFilteredStatus.productStatus
    }

    private var filteredStatusBinding: Binding<ProductStatus> {
        Binding(
            get: { self.filteredStatus },
            set: { self.storageFilteredStatus = StockProductStatusStorage(from: $0) }
        )
    }

    private func clearFilters() {
        storageFilteredStatus = .all
        filteredLocationID = nil
        filteredProductGroupID = nil
    }

    private var numFilters: Int {
        var filterCount = 0
        if filteredStatus != .all { filterCount += 1 }
        if features.locationTracking, filteredLocationID != nil { filterCount += 1 }
        if filteredProductGroupID != nil { filterCount += 1 }
        return filterCount
    }

    var sortSetting: [KeyPathComparator<StockElement>] {
        let order = sortOrder
        switch sortCategory {
        case .name:
            return [KeyPathComparator(\StockElement.product?.name, order: order)]
        case .dueDate:
            return [KeyPathComparator(\StockElement.bestBeforeDate, order: order)]
        case .amount:
            return [KeyPathComparator(\StockElement.amount, order: order)]
        }
    }

    @State private var stockInteractionRouter = StockInteractionNavigationRouter()

    /// The fields of a stock entry that `StockElement.==` compares, as a value, so `onChange` can keep it safely.
    private struct StockSnapshot: Equatable {
        var id: PersistentIdentifier
        var amount: Double
        var amountAggregated: Double
        var value: Double
        var bestBeforeDate: Date?
        var amountOpened: Double
        var amountOpenedAggregated: Double
        var isAggregatedAmount: Bool
        var dueType: DueType
        var productID: Int

        init(_ element: StockElement) {
            id = element.persistentModelID
            amount = element.amount
            amountAggregated = element.amountAggregated
            value = element.value
            bestBeforeDate = element.bestBeforeDate
            amountOpened = element.amountOpened
            amountOpenedAggregated = element.amountOpenedAggregated
            isAggregatedAmount = element.isAggregatedAmount
            dueType = element.dueType
            productID = element.productID
        }
    }

    /// The filtered and grouped stock. Not `Equatable` on purpose: `@State` compares a new `Equatable` value with the
    /// old one, and the old one can hold elements a sync has deleted. `StockElement.==` reads their attributes, which
    /// crashes SwiftData ("backing data was detached from a context").
    private struct StockListCache {
        var filtered: [StockElement] = []
        var grouped: [AnyHashable: [StockElement]] = [:]
    }

    // Cached filtered/grouped results to prevent blocking during filter changes
    @State private var cachedStockList = StockListCache()

    private let dataToUpdate: [ObjectEntities] = [
        .products, .shopping_locations, .locations, .product_groups, .quantity_units, .shopping_lists, .shopping_list, .stock, .stock_current_locations,
    ]
    private let additionalDataToUpdate: [AdditionalEntities] = [.stock, .volatileStock, .system_config, .user_settings]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    var numExpiringSoon: Int? {
        volatileStock?.dueProducts.count
    }

    var numOverdue: Int? {
        volatileStock?.overdueProducts.count
    }

    var numExpired: Int? {
        volatileStock?.expiredProducts.count
    }

    var numBelowStock: Int? {
        volatileStock?.missingProducts.count
    }

    @State private var cachedMissingStock: Stock = []

    var missingStock: Stock {
        cachedMissingStock
    }

    /// Grocy's "stock_overview_show_all_out_of_stock_products": list every active product, not only those in stock
    /// or below their minimum stock amount.
    private var showsAllOutOfStockProducts: Bool {
        userSettings?.stockOverviewShowAllOutOfStockProducts ?? false
    }

    /// The products that aren't in stock but belong in the overview, as empty stock elements: those below their minimum
    /// stock amount and, with `showsAllOutOfStockProducts`, every other active product.
    ///
    /// Synchronous, so `computeFilteredAndGroupedStock()` right after it sees the new elements.
    private func updateMissingStock() {
        let productsByID = Dictionary(uniqueKeysWithValues: mdProducts.map { ($0.id, $0) })
        let missingProducts = volatileStock?.missingProducts ?? []
        let stockProductIDs = Set(stock.map { $0.productID })

        var elements: Stock = missingProducts.filter { !$0.isPartlyInStock && !stockProductIDs.contains($0.productID) }.compactMap { missingProduct in
            productsByID[missingProduct.productID].map(StockElement.init(notInStock:))
        }
        if showsAllOutOfStockProducts {
            let listedProductIDs = stockProductIDs.union(elements.map(\.productID))
            elements += mdProducts.filter { $0.active && !listedProductIDs.contains($0.id) }.map(StockElement.init(notInStock:))
        }
        cachedMissingStock = elements
    }

    // The cache can still hold elements a sync removed since it was computed (their product left the stock);
    // their attributes can't be read anymore, so they're left out until the next computation.
    var filteredAndSearchedStock: [StockElement] {
        cachedStockList.filtered.filter { !$0.isRemoved }
    }

    var groupedStock: [AnyHashable: [StockElement]] {
        cachedStockList.grouped.compactMapValues { elements in
            let live = elements.filter { !$0.isRemoved }
            return live.isEmpty ? nil : live
        }
    }

    private func computeFilteredAndGroupedStock() {
        // Capture only Sendable primitives from SwiftData objects (on main thread)
        let searchString = self.searchString
        // A location filter stored before location tracking was turned off on the server no longer applies.
        let filteredLocationID = features.locationTracking ? self.filteredLocationID : nil
        let filteredProductGroupID = self.filteredProductGroupID
        let filteredStatus = self.filteredStatus
        let stockGrouping = self.stockGrouping
        let sortSetting = self.sortSetting
        let stock = self.stock
        let missingStock = self.missingStock
        let productNamesByID = Dictionary(uniqueKeysWithValues: mdProducts.map { ($0.id, $0.name) })

        // Built once per pass, not per element: with "show all out of stock products" the overview has an element for every
        // product, and per-element scans of these lists made a pass quadratic.
        let dueProductIDs = Set(volatileStock?.dueProducts.map(\.productID) ?? [])
        let expiredProductIDs = Set(volatileStock?.expiredProducts.map(\.productID) ?? [])
        let overdueProductIDs = Set(volatileStock?.overdueProducts.map(\.productID) ?? [])
        let missingProductIDs = Set(volatileStock?.missingProducts.map(\.productID) ?? [])
        let productIDsAtFilteredLocation: Set<Int>? = filteredLocationID.map { locationID in
            Set(stockLocations.filter { $0.locationID == locationID }.map(\.productID))
        }
        var lastPurchasedByProductID: [Int: Date] = [:]
        if stockGrouping == .lastPurchased {
            for entry in stockEntries {
                guard let purchasedDate = entry.purchasedDate else { continue }
                if let known = lastPurchasedByProductID[entry.productID], known >= purchasedDate { continue }
                lastPurchasedByProductID[entry.productID] = purchasedDate
            }
        }

        // Synchronous, on the main actor: a later task could read elements that a sync deleted in between, which crashes SwiftData.
        var grouped: [AnyHashable: [StockElement]] = [:]
        var filtered: [StockElement] = []

        let allStock = stock + missingStock

        for element in allStock {
            // A sync may have removed the element since it was captured; reading it would crash.
            guard !element.isRemoved else { continue }
            // Quick reject checks
            guard !(element.product?.hideOnStockOverview ?? false) else { continue }

            // Search filter
            if !searchString.isEmpty {
                let productNameMatches = element.product?.name.localizedStandardContains(searchString) ?? false
                let parentProductNameMatches =
                    element.product?.parentProductID.flatMap { productNamesByID[$0]?.localizedStandardContains(searchString) } ?? false

                if !productNameMatches && !parentProductNameMatches {
                    continue
                }
            }

            // Product group filter
            if let groupID = filteredProductGroupID,
                element.product?.productGroupID != groupID
            {
                continue
            }

            // Location filter
            if let productIDsAtFilteredLocation, !productIDsAtFilteredLocation.contains(element.productID) {
                continue
            }

            // Status filter
            let productID = element.productID

            let passesStatus =
                filteredStatus == .all
                || (filteredStatus == .belowMinStock && missingProductIDs.contains(productID))
                || (filteredStatus == .expiringSoon && dueProductIDs.contains(productID))
                || (filteredStatus == .overdue && overdueProductIDs.contains(productID) && !expiredProductIDs.contains(productID))
                || (filteredStatus == .expired && expiredProductIDs.contains(productID))

            if !passesStatus { continue }

            // Compute group key
            let groupKey: AnyHashable = {
                switch stockGrouping {
                case .none:
                    return ""
                case .productGroup:
                    return element.product?.productGroupID ?? 0
                case .nextDueDate:
                    return element.bestBeforeDate as AnyHashable
                case .lastPurchased:
                    return lastPurchasedByProductID[productID] as AnyHashable
                case .minStockAmount:
                    return element.product?.minStockAmount ?? 0
                case .parentProduct:
                    return element.product?.parentProductID ?? 0
                case .defaultLocation:
                    return element.product?.locationID ?? 0
                }
            }()

            if grouped[groupKey] != nil {
                grouped[groupKey]?.append(element)
            } else {
                grouped[groupKey] = [element]
            }
        }

        // Sort each group
        for key in grouped.keys {
            grouped[key]?.sort(using: sortSetting)
        }

        filtered = grouped.values.flatMap { $0 }

        self.cachedStockList = StockListCache(filtered: filtered, grouped: grouped)
    }

    @State private var cachedSummedValue: Double = 0
    @State private var lastStockChangeID: Int = 0

    var summedValue: Double {
        let changeID = stock.count &+ (stock.first?.id.hashValue ?? 0)
        if lastStockChangeID != changeID {
            lastStockChangeID = changeID
            cachedSummedValue = stock.reduce(0) { $0 + $1.value }
        }
        return cachedSummedValue
    }

    var summedValueStr: String {
        return "\(summedValue.formatted(.number.precision(.fractionLength(0...2)))) \(grocyVM.getCurrencySymbol())"
    }

    /// Whether the groups are keyed by the ID of an object (product group, parent product, location), whose name the header shows.
    private var isGroupedByObject: Bool {
        stockGrouping == .productGroup || stockGrouping == .parentProduct || stockGrouping == .defaultLocation
    }

    /// The names of the objects the groups are keyed by, or nil when the stock isn't grouped by an object.
    private var groupNamesByID: [Int: String]? {
        switch stockGrouping {
        case .productGroup:
            return Dictionary(mdProductGroups.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        case .parentProduct:
            return Dictionary(mdProducts.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        case .defaultLocation:
            return Dictionary(mdLocations.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        default:
            return nil
        }
    }

    var stockListContent: some View {
        let groupNamesByID = self.groupNamesByID
        // Built once for all rows, which look up their quantity unit, product group, parent product and status in it.
        let rowLookups = StockRowLookups(
            quantityUnits: mdQuantityUnits,
            productGroups: mdProductGroups,
            products: mdProducts,
            shoppingList: shoppingList,
            volatileStock: volatileStock,
            dueDateTracking: features.dueDateTracking
        )
        let groupName: (AnyHashable) -> String? = { key in
            guard let id = key as? Int else { return nil }
            return groupNamesByID?[id]
        }
        let sortedGroups = Array(groupedStock).sorted { a, b in
            if let dateA = a.key as? Date, let dateB = b.key as? Date { return dateA < dateB }
            if let numA = a.key as? Double, let numB = b.key as? Double { return numA < numB }
            if groupNamesByID != nil {
                // Named groups by name, the ungrouped elements last
                switch (groupName(a.key), groupName(b.key)) {
                case (let nameA?, let nameB?):
                    return nameA.localizedStandardCompare(nameB) == .orderedAscending
                case (.some, nil):
                    return true
                default:
                    return false
                }
            }
            return String(describing: a.key) < String(describing: b.key)
        }

        return ForEach(sortedGroups, id: \.key) { groupKey, groupElements in
            Section(
                content: {
                    ForEach(
                        groupElements,
                        id: \.productID
                    ) { stockElement in
                        StockTableRow(stockElement: stockElement, lookups: rowLookups, userSettings: userSettings)
                    }
                },
                header: {
                    let dateFormatter: DateFormatter = {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .none
                        return formatter
                    }()

                    if isGroupedByObject {
                        if let name = groupName(groupKey) {
                            Text(name).bold()
                        } else {
                            Text("Ungrouped")
                                .italic()
                        }
                    } else if stockGrouping == .none {
                        EmptyView()
                    } else if stockGrouping == .minStockAmount, let numValue = groupKey as? Double {
                        Text(numValue.formatted(.number.precision(.fractionLength(0)))).bold()
                    } else if stockGrouping == .nextDueDate || stockGrouping == .lastPurchased {
                        if let date = groupKey as? Date {
                            Text(dateFormatter.string(from: date)).bold()
                        } else if groupKey is NSNull {
                            Text("Unknown").italic()
                        } else {
                            Text(String(describing: groupKey)).bold()
                        }
                    } else {
                        let groupName = groupKey as? String ?? String(describing: groupKey)
                        Text(groupName).bold()
                    }
                }
            )
        }
    }

    // The capsules float in a bar above the list (the navigation layer), so their glass isn't drawn inside a list row
    private var filterCapsules: some View {
        StockFilterActionsView(
            filteredStatus: filteredStatusBinding,
            numExpiringSoon: numExpiringSoon,
            numOverdue: numOverdue,
            numExpired: numExpired,
            numBelowStock: numBelowStock
        )
    }

    /// The stock actions of the toolbar, in the order of the bar (purchase ends up at the trailing edge).
    private var stockActions: [StockInteraction] {
        features.locationTracking
            ? [.inventoryProduct, .transferProduct, .consumeProduct, .purchaseProduct]
            : [.inventoryProduct, .consumeProduct, .purchaseProduct]
    }

    private func stockActionButton(_ interaction: StockInteraction) -> some View {
        Button {
            stockInteractionRouter.present(interaction)
        } label: {
            switch interaction {
            case .inventoryProduct:
                Label("Inventory", systemImage: MySymbols.inventory)
                    .macHelp("Inventory")
            case .transferProduct:
                Label("Transfer", systemImage: MySymbols.transfer)
                    .macHelp("Transfer")
            case .consumeProduct:
                Label("Consume", systemImage: MySymbols.consume)
                    .macHelp("Consume")
            case .purchaseProduct:
                Label("Purchase", systemImage: MySymbols.purchase)
                    .macHelp("Purchase")
            default: EmptyView()
            }
        }
    }

    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            }
            stockListContent
        }
        .overlay {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count == 0 {
                if (stock + missingStock).isEmpty {
                    ContentUnavailableView {
                        Label("Stock is empty.", systemImage: MySymbols.stockOverview)
                    } actions: {
                        Button("Purchase") {
                            stockInteractionRouter.present(.purchaseProduct)
                        }
                    }
                } else if filteredAndSearchedStock.isEmpty {
                    if numFilters > 0 {
                        // Say that filters hide products, so a product that exists isn't taken for missing (#253).
                        ContentUnavailableView {
                            Label("No products", systemImage: MySymbols.filter)
                        } description: {
                            Text("No product matches the filters.")
                        } actions: {
                            Button("Clear filter", action: clearFilters)
                        }
                    } else {
                        ContentUnavailableView.search
                    }
                }
            }
        }
        .refreshable {
            await updateData()
        }
        .floatingTopBar {
            filterCapsules
                .padding(.vertical, Spacing.small)
        }
        .navigationTitle("Stock overview")
        .searchable(text: $searchString, prompt: "Search")
        .animation(.default, value: filteredStatus)
        .onAppear {
            // The saved stock right away, so the rows are there in the first layout: on macOS, rows a list gets later
            // in a split view's detail keep the estimated height and width until the window is resized.
            updateMissingStock()
            computeFilteredAndGroupedStock()
        }
        .task {
            await updateData()
            updateMissingStock()
            computeFilteredAndGroupedStock()

            if let filter = deepLinkManager.pendingStockFilter {
                storageFilteredStatus = StockProductStatusStorage(from: filter)
                deepLinkManager.consume()
            }
        }
        .onChange(of: deepLinkManager.pendingStockFilter) { _, newValue in
            if let filter = newValue {
                storageFilteredStatus = StockProductStatusStorage(from: filter)
                deepLinkManager.consume()
            }
        }
        .onChange(of: filteredLocationID) { _, _ in
            computeFilteredAndGroupedStock()
        }
        .onChange(of: filteredProductGroupID) { _, _ in
            computeFilteredAndGroupedStock()
        }
        .onChange(of: storageFilteredStatus) { _, _ in
            computeFilteredAndGroupedStock()
        }
        .onChange(of: searchString) { _, _ in
            computeFilteredAndGroupedStock()
        }
        .onChange(of: stockGrouping) { _, _ in
            computeFilteredAndGroupedStock()
        }
        .onChange(of: sortCategory) { _, _ in
            computeFilteredAndGroupedStock()
        }
        .onChange(of: storageSortOrder) { _, _ in
            computeFilteredAndGroupedStock()
        }
        // Observes a value snapshot, not the models: `onChange` keeps the previous value, and comparing models
        // that a sync has deleted reads detached attributes, which crashes SwiftData.
        .onChange(of: stock.map(StockSnapshot.init)) { _, _ in
            // A product that leaves or enters the stock moves between the stock and the empty elements.
            updateMissingStock()
            computeFilteredAndGroupedStock()
        }
        .onChange(of: volatileStock) { _, _ in
            updateMissingStock()
            computeFilteredAndGroupedStock()
        }
        .onChange(of: showsAllOutOfStockProducts) { _, _ in
            updateMissingStock()
            computeFilteredAndGroupedStock()
        }
        // Adding, deleting or (de)activating a product changes which products are listed.
        .onChange(of: mdProducts.filter(\.active).map(\.id)) { _, _ in
            if showsAllOutOfStockProducts {
                updateMissingStock()
                computeFilteredAndGroupedStock()
            }
        }
        .toolbar(content: {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: { showingFilterSheet = true }) {
                    Label("Filter", systemImage: MySymbols.filter)
                        .macHelp("Filter")
                }
                .badge(numFilters)
                sortMenu
            }
            ToolbarSpacer(.fixed)
            ToolbarItem(placement: .automatic) {
                Button(
                    action: {
                        stockInteractionRouter.present(.stockJournal)
                    },
                    label: {
                        Label("Stock journal", systemImage: MySymbols.stockJournal)
                            .macHelp("Stock journal")
                    }
                )
            }
            #if os(iOS)
                .matchedTransitionSource(id: StockInteractionZoom.journalSourceID, in: stockInteractionTransition)
            #endif
            ToolbarSpacer(.fixed)
            #if os(iOS)
                // The iPhone bar has room for one button here: the four actions share a menu instead of
                // spilling three of them into an overflow menu.
                if horizontalSizeClass == .compact {
                    ToolbarItem {
                        Menu {
                            ForEach(stockActions.reversed(), id: \.self) { interaction in
                                stockActionButton(interaction)
                            }
                        } label: {
                            Label("Stock actions", systemImage: MySymbols.stockActions)
                                .macHelp("Stock actions")
                        }
                    }
                    .matchedTransitionSource(id: StockInteractionZoom.actionsSourceID, in: stockInteractionTransition)
                } else {
                    ToolbarItemGroup {
                        ForEach(stockActions, id: \.self) { interaction in
                            stockActionButton(interaction)
                        }
                    }
                }
            #else
                ToolbarItemGroup {
                    ForEach(stockActions, id: \.self) { interaction in
                        stockActionButton(interaction)
                    }
                }
            #endif
        })
        #if os(iOS)
            .stockInteractionSheet(
                router: stockInteractionRouter,
                zoom: horizontalSizeClass == .compact ? StockInteractionZoom(namespace: stockInteractionTransition) : nil
            )
        #else
            .stockInteractionSheet(router: stockInteractionRouter)
        #endif
        .stockEntriesDestination()
        .sheet(isPresented: $showingFilterSheet) {
            NavigationStack {
                StockFilterView(
                    filteredLocationID: $filteredLocationID,
                    filteredProductGroupID: $filteredProductGroupID,
                    filteredStatus: filteredStatusBinding
                )
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
                                    showingFilterSheet = false
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
                                    filteredLocationID = nil
                                    filteredProductGroupID = nil
                                    storageFilteredStatus = .all
                                    showingFilterSheet = false
                                }
                            )
                        }
                    )
                }
            }
            .presentationDetents([.medium])
            // The filter is a list of pickers.
            .filterSheetSize()
        }
    }

    var sortMenu: some View {
        Menu(
            content: {
                Picker(
                    "Group by",
                    systemImage: MySymbols.groupBy,
                    selection: $stockGrouping,
                    content: {
                        Label("None", systemImage: MySymbols.product)
                            .labelStyle(.titleAndIcon)
                            .tag(StockGrouping.none)
                        Label("Product group", systemImage: MySymbols.productGroup)
                            .labelStyle(.titleAndIcon)
                            .tag(StockGrouping.productGroup)
                        if features.dueDateTracking {
                            Label("Next due date", systemImage: MySymbols.date)
                                .labelStyle(.titleAndIcon)
                                .tag(StockGrouping.nextDueDate)
                        }
                        Label("Last purchased", systemImage: MySymbols.date)
                            .labelStyle(.titleAndIcon)
                            .tag(StockGrouping.lastPurchased)
                        Label("Min. stock amount", systemImage: MySymbols.amount)
                            .labelStyle(.titleAndIcon)
                            .tag(StockGrouping.minStockAmount)
                        Label("Parent product", systemImage: MySymbols.parentProduct)
                            .labelStyle(.titleAndIcon)
                            .tag(StockGrouping.parentProduct)
                        if features.locationTracking {
                            Label("Default location", systemImage: MySymbols.location)
                                .labelStyle(.titleAndIcon)
                                .tag(StockGrouping.defaultLocation)
                        }
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
                    selection: $sortCategory,
                    content: {
                        Label("Name", systemImage: MySymbols.name)
                            .labelStyle(.titleAndIcon)
                            .tag(StockSortCategory.name)
                        if features.dueDateTracking {
                            Label("Due date", systemImage: MySymbols.date)
                                .labelStyle(.titleAndIcon)
                                .tag(StockSortCategory.dueDate)
                        }
                        Label("Amount", systemImage: MySymbols.amount)
                            .labelStyle(.titleAndIcon)
                            .tag(StockSortCategory.amount)
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
                    .macHelp("Sort")
            }
        )
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        StockView()
    }
    .environment(DeepLinkManager())
}
