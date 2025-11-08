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

enum StockInteraction: Hashable {
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
}

struct StockView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query var stock: [StockElement]
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups
    @Query(sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    @Query var volatileStockList: [VolatileStock]
    var volatileStock: VolatileStock? {
        return volatileStockList.first
    }
    @State private var searchString: String = ""
    @State private var showingFilterSheet = false

    #if os(iOS)
        @AppStorage("iPhoneTabNavigation") var iPhoneTabNavigation: Bool = true
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    private enum StockGrouping: Identifiable {
        case none, productGroup, nextDueDate, lastPurchased, minStockAmount, parentProduct, defaultLocation
        var id: Int {
            hashValue
        }
    }
    @State private var stockGrouping: StockGrouping = .none
    @State private var sortSetting = [KeyPathComparator(\StockElement.productID)]
    @State private var sortOrder: SortOrder = .forward

    @State private var filteredLocationID: Int?
    @State private var filteredProductGroupID: Int?
    @State private var filteredStatus: ProductStatus = .all

    @State var selectedStockElement: StockElement? = nil

    private let dataToUpdate: [ObjectEntities] = [.products, .shopping_locations, .locations, .product_groups, .quantity_units, .shopping_lists, .shopping_list]
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

    var missingStock: Stock {
        var missingStockList: Stock = []
        for missingProduct in volatileStock?.missingProducts ?? [] {
            if !(missingProduct.isPartlyInStock) {
                if let foundProduct = mdProducts.first(where: { $0.id == missingProduct.id }) {
                    let missingStockElement = StockElement(
                        amount: 0,
                        amountAggregated: 0,
                        value: 0.0,
                        bestBeforeDate: nil,
                        amountOpened: 0,
                        amountOpenedAggregated: 0,
                        isAggregatedAmount: false,
                        dueType: foundProduct.dueType,
                        productID: missingProduct.productID,
                        product: foundProduct
                    )
                    missingStockList.append(missingStockElement)
                }
            }
        }
        return missingStockList
    }

    var filteredAndSearchedStock: [StockElement] {
        // First use predicate for simple conditions
        let simplePredicate = #Predicate<StockElement> { stockElement in
            !(stockElement.product?.hideOnStockOverview ?? false)
                && (searchString.isEmpty || stockElement.product?.name.localizedStandardContains(searchString) ?? false)
                && (filteredProductGroupID == nil || stockElement.product?.productGroupID == filteredProductGroupID)
        }

        // Then apply complex filters using Swift
        return (stock + missingStock)
            .filter { (try? simplePredicate.evaluate($0)) ?? false }
            .filter { stockElement in
                // Location filter
                filteredLocationID == nil || stockElement.product?.locationID == filteredLocationID
                || ((grocyVM.stockProductLocations[stockElement.productID]?.contains(where: {
                    $0.locationID == filteredLocationID
                })) != nil)
            }
            .filter { stockElement in
                // Status filters
                filteredStatus == .all || (filteredStatus == .belowMinStock && volatileStock?.missingProducts.contains(where: { $0.productID == stockElement.productID }) ?? false)
                    || (filteredStatus == .expiringSoon && volatileStock?.dueProducts.contains(where: { $0.productID == stockElement.productID }) ?? false)
                    || (filteredStatus == .overdue && (volatileStock?.overdueProducts.contains(where: { $0.productID == stockElement.productID }) ?? false)
                        && !(volatileStock?.expiredProducts.contains(where: { $0.productID == stockElement.productID }) ?? false))
                    || (filteredStatus == .expired && volatileStock?.expiredProducts.contains(where: { $0.productID == stockElement.productID }) ?? false)
            }
            .sorted(using: sortSetting)
    }

    var groupedStock: [String: [StockElement]] {
        switch stockGrouping {
        case .none:
            return Dictionary(
                grouping: filteredAndSearchedStock,
                by: { element in
                    ""
                }
            )
        case .productGroup:
            return Dictionary(
                grouping: filteredAndSearchedStock,
                by: { element in
                    mdProductGroups.first(where: { productGroup in
                        productGroup.id == element.product?.productGroupID
                    })?
                    .name ?? ""
                }
            )
        case .nextDueDate:
            return Dictionary(
                grouping: filteredAndSearchedStock,
                by: { element in
                    element.bestBeforeDate?.iso8601withFractionalSeconds ?? ""
                }
            )
        case .lastPurchased:
            return Dictionary(
                grouping: filteredAndSearchedStock,
                by: { element in
                    grocyVM.stockProductDetails[element.productID]?.lastPurchased?.iso8601withFractionalSeconds ?? ""
                }
            )
        case .minStockAmount:
            return Dictionary(
                grouping: filteredAndSearchedStock,
                by: { element in
                    element.product?.minStockAmount.formattedAmount ?? ""
                }
            )
        case .parentProduct:
            return Dictionary(
                grouping: filteredAndSearchedStock,
                by: { element in
                    mdProducts.first(where: { product in
                        product.id == element.productID
                    })?
                    .name ?? ""
                }
            )
        case .defaultLocation:
            return Dictionary(
                grouping: filteredAndSearchedStock,
                by: { element in
                    mdLocations.first(where: { location in
                        location.id == element.product?.locationID
                    })?
                    .name ?? ""
                }
            )
        }
    }

    var summedValue: Double {
        let values = stock.map { $0.value }
        return values.reduce(0, +)
    }

    var summedValueStr: String {
        return "\(String(format: "%.2f", summedValue)) \(getCurrencySymbol())"
    }

    var body: some View {
        List {
            Section {
                StockFilterActionsView(filteredStatus: $filteredStatus, numExpiringSoon: numExpiringSoon, numOverdue: numOverdue, numExpired: numExpired, numBelowStock: numBelowStock)
                    .listRowInsets(EdgeInsets())
            }

            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if stock.isEmpty {
                ContentUnavailableView("Stock is empty.", systemImage: MySymbols.quantityUnit)
            } else if filteredAndSearchedStock.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(groupedStock.sorted(by: { $0.key < $1.key }), id: \.key) { groupName, groupElements in
                Section(
                    content: {
                        ForEach(
                            groupElements.sorted(using: sortSetting),
                            id: \.productID,
                            content: { stockElement in
                                StockTableRow(stockElement: stockElement, selectedStockElement: $selectedStockElement)
                            }
                        )
                    },
                    header: {
                        if stockGrouping == .productGroup, groupName.isEmpty {
                            Text("Ungrouped")
                                .italic()
                        } else if stockGrouping == .none {
                            EmptyView()
                        } else {
                            Text(groupName).bold()
                        }
                    }
                )
            }
        }
        .navigationTitle("Stock overview")
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await updateData()
        }
        .animation(.default, value: groupedStock.count)
        .task {
            await updateData()
        }
        .toolbar(content: {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: { showingFilterSheet = true }) {
                    Image(systemName: MySymbols.filter)
                }
                sortMenu
            }
            ToolbarSpacer(.fixed)
            #if os(iOS)
                if horizontalSizeClass == .compact && iPhoneTabNavigation {
                    ToolbarItem(placement: .automatic) {
                        NavigationLink(value: StockInteraction.stockJournal) {
                            Label("Stock journal", systemImage: MySymbols.stockJournal)
                        }
                    }
                    ToolbarSpacer(.fixed)
                }
            #endif
            #if os(iOS)
            ToolbarItemGroup(placement: horizontalSizeClass == .compact ? .secondaryAction : .primaryAction) {
                    NavigationLink(value: StockInteraction.inventoryProduct) {
                        Label("Inventory", systemImage: MySymbols.inventory)
                    }
                    NavigationLink(value: StockInteraction.transferProduct) {
                        Label("Transfer", systemImage: MySymbols.transfer)
                    }
                    NavigationLink(value: StockInteraction.consumeProduct) {
                        Label("Consume", systemImage: MySymbols.consume)
                    }
                    NavigationLink(value: StockInteraction.purchaseProduct) {
                        Label("Purchase", systemImage: MySymbols.purchase)
                    }
                }
            #elseif os(macOS)
                //            RefreshButton(updateData: { Task { await updateData() } })
            #endif
        })
        .navigationDestination(
            for: StockInteraction.self,
            destination: { interaction in
                switch interaction {
                case .stockJournal:
                    StockJournalView()
                case .inventoryProduct:
                    InventoryProductView()
                case .transferProduct:
                    TransferProductView()
                case .consumeProduct:
                    ConsumeProductView()
                case .purchaseProduct:
                    PurchaseProductView()
                case .productPurchase(let stockElement):
                    PurchaseProductView(stockElement: stockElement)
                case .productConsume(let stockElement):
                    ConsumeProductView(stockElement: stockElement)
                case .productTransfer(let stockElement):
                    TransferProductView(stockElement: stockElement)
                case .productInventory(let stockElement):
                    InventoryProductView(stockElement: stockElement)
                case .productOverview(let stockElement):
                    StockProductInfoView(stockElement: stockElement)
                case .productJournal(let stockElement):
                    StockJournalView(stockElement: stockElement)
                case .addToShL(let stockElement):
                    ShoppingListEntryFormView(isNewShoppingListEntry: true, productIDToSelect: stockElement.productID)
                }
            }
        )
        .navigationDestination(
            for: StockElement.self,
            destination: { stockElement in
                StockEntriesView(stockElement: stockElement)
            }
        )
        .sheet(isPresented: $showingFilterSheet) {
            NavigationStack {
                StockFilterView(filteredLocationID: $filteredLocationID, filteredProductGroupID: $filteredProductGroupID, filteredStatus: $filteredStatus)
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
                                        filteredStatus = .all
                                        showingFilterSheet = false
                                    }
                                )
                            }
                        )
                    }
            }
            .presentationDetents([.medium])
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
                        Label("Product group", systemImage: MySymbols.amount)
                            .labelStyle(.titleAndIcon)
                            .tag(StockGrouping.productGroup)
                        Label("Next due date", systemImage: MySymbols.date)
                            .labelStyle(.titleAndIcon)
                            .tag(StockGrouping.nextDueDate)
                        Label("Last purchased", systemImage: MySymbols.date)
                            .labelStyle(.titleAndIcon)
                            .tag(StockGrouping.lastPurchased)
                        Label("Min. stock amount", systemImage: MySymbols.amount)
                            .labelStyle(.titleAndIcon)
                            .tag(StockGrouping.minStockAmount)
                        Label("Parent product", systemImage: MySymbols.product)
                            .labelStyle(.titleAndIcon)
                            .tag(StockGrouping.parentProduct)
                        Label("Default location", systemImage: MySymbols.location)
                            .labelStyle(.titleAndIcon)
                            .tag(StockGrouping.defaultLocation)
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
                    selection: $sortSetting,
                    content: {
                        if sortOrder == .forward {
                            Label("Product name", systemImage: MySymbols.product)
                                .labelStyle(.titleAndIcon)
                                .tag([KeyPathComparator(\StockElement.product?.name, order: .forward)])
                            Label("Due date", systemImage: MySymbols.date)
                                .labelStyle(.titleAndIcon)
                                .tag([KeyPathComparator(\StockElement.bestBeforeDate, order: .forward)])
                            Label("Amount", systemImage: MySymbols.amount)
                                .labelStyle(.titleAndIcon)
                                .tag([KeyPathComparator(\StockElement.amount, order: .forward)])
                        } else {
                            Label("Product name", systemImage: MySymbols.product)
                                .labelStyle(.titleAndIcon)
                                .tag([KeyPathComparator(\StockElement.product?.name, order: .reverse)])
                            Label("Due date", systemImage: MySymbols.date)
                                .labelStyle(.titleAndIcon)
                                .tag([KeyPathComparator(\StockElement.bestBeforeDate, order: .reverse)])
                            Label("Amount", systemImage: MySymbols.amount)
                                .labelStyle(.titleAndIcon)
                                .tag([KeyPathComparator(\StockElement.amount, order: .reverse)])
                        }
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
                    selection: $sortOrder,
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
                .onChange(of: sortOrder) {
                    if var sortElement = sortSetting.first {
                        sortElement.order = sortOrder
                        sortSetting = [sortElement]
                    }
                }
            },
            label: {
                Label("Sort", systemImage: MySymbols.sort)
            }
        )
    }
}

#Preview {
    ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
        StockView()
            .preferredColorScheme(scheme)
    }
}
