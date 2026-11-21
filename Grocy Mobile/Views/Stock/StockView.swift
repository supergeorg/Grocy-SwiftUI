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

    // Cached filtered/grouped results to prevent blocking during filter changes
    @State private var cachedFilteredStock: [StockElement] = []
    @State private var cachedGroupedStock: [AnyHashable: [StockElement]] = [:]
    @State private var filterComputationTask: Task<Void, Never>?

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

    var filteredAndSearchedStock: [StockElement] {
        cachedFilteredStock
    }

    var groupedStock: [AnyHashable: [StockElement]] {
        cachedGroupedStock
    }

    private func computeFilteredAndGroupedStock() {
        filterComputationTask?.cancel()

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

        filterComputationTask = Task {
            // Run computation on main thread to avoid Sendable/ModelContext issues
            var grouped: [AnyHashable: [StockElement]] = [:]
            var filtered: [StockElement] = []

            let allStock = stock + missingStock

            for element in allStock {
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

            if !Task.isCancelled {
                self.cachedGroupedStock = grouped
                self.cachedFilteredStock = filtered
            }
        }
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

    var stockListContent: some View {
        let sortedGroups = Array(groupedStock).sorted { a, b in
            if let dateA = a.key as? Date, let dateB = b.key as? Date { return dateA < dateB }
            if let numA = a.key as? Double, let numB = b.key as? Double { return numA < numB }
            return String(describing: a.key) < String(describing: b.key)
        }

        return ForEach(sortedGroups, id: \.key) { groupKey, groupElements in
            Section(
                content: {
                    ForEach(
                        groupElements,
                        id: \.productID
                    ) { stockElement in
                        StockTableRow(
                            stockElement: stockElement,
                            mdQuantityUnits: mdQuantityUnits,
                            shoppingList: shoppingList,
                            mdProductGroups: mdProductGroups,
                            volatileStock: volatileStock,
                            parentProduct: mdProducts.first(where: { $0.id == stockElement.product?.parentProductID }),
                            userSettings: userSettings
                        )
                    }
                },
                header: {
                    let dateFormatter: DateFormatter = {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .none
                        return formatter
                    }()

                    if stockGrouping == .productGroup, (groupKey as? String)?.isEmpty ?? false {
                        Text("Ungrouped")
                            .italic()
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

    var body: some View {
        List {

            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if (stock + missingStock).isEmpty {
                ContentUnavailableView {
                    Label("Stock is empty.", systemImage: MySymbols.stockOverview)
                } actions: {
                    Button("Purchase") {
                        stockInteractionRouter.present(.purchaseProduct)
                    }
                }
            } else if filteredAndSearchedStock.isEmpty {
                ContentUnavailableView.search
            }
            stockListContent
        }
        .refreshable {
            await updateData()
        }
        .safeAreaBar(edge: .top) {
            filterCapsules
                .padding(.vertical, Spacing.small)
        }
        .navigationTitle("Stock overview")
        .searchable(text: $searchString, prompt: "Search")
        .animation(.default, value: filteredStatus)
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
                    }
                )
            }
            ToolbarSpacer(.fixed)
            ToolbarItemGroup {
                Button(
                    action: {
                        stockInteractionRouter.present(.inventoryProduct)
                    },
                    label: {
                        Label("Inventory", systemImage: MySymbols.inventory)
                    }
                )
                if features.locationTracking {
                    Button(
                        action: {
                            stockInteractionRouter.present(.transferProduct)
                        },
                        label: {
                            Label("Transfer", systemImage: MySymbols.transfer)
                        }
                    )
                }
                Button(
                    action: {
                        stockInteractionRouter.present(.consumeProduct)
                    },
                    label: {
                        Label("Consume", systemImage: MySymbols.consume)
                    }
                )
                Button(
                    action: {
                        stockInteractionRouter.present(.purchaseProduct)
                    },
                    label: {
                        Label("Purchase", systemImage: MySymbols.purchase)
                    }
                )
            }
        })
        .stockInteractionSheet(router: stockInteractionRouter)
        .navigationDestination(
            for: StockElement.self,
            destination: { stockElement in
                StockEntriesView(stockElement: stockElement)
            }
        )
        #if os(iOS)
            .sheet(isPresented: $showingFilterSheet) {
                NavigationStack {
                    StockFilterView(
                        filteredLocationID: $filteredLocationID,
                        filteredProductGroupID: $filteredProductGroupID,
                        filteredStatus: filteredStatusBinding
                    )
                    .navigationTitle("Filter")
                    .navigationBarTitleDisplayMode(.inline)
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

            }
        #endif
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
                        Label("Product group", systemImage: MySymbols.amount)
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
                        Label("Parent product", systemImage: MySymbols.product)
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
                        Label("Name", systemImage: MySymbols.product)
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
