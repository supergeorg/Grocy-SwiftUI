//
//  StockView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import SwiftUI

enum StockColumn {
    case product, productGroup, amount, value, nextBestBeforeDate, caloriesPerStockQU, calories
}

#if os(iOS)
enum StockInteractionSheet: Identifiable {
    case purchaseProduct, consumeProduct, transferProduct, inventoryProduct, stockJournal, addToShL, productPurchase, productConsume, productTransfer, productInventory, productOverview, productJournal, editProduct
    
    var id: Int {
        self.hashValue
    }
}
#elseif os(macOS)
enum StockInteractionPopover: Identifiable {
    case addToShL, productPurchase, productConsume, productTransfer, productInventory, productOverview, productJournal, editProduct
    
    var id: Int {
        self.hashValue
    }
}
#endif

struct StockView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @State private var firstAppear: Bool = true
    
    @State private var searchString: String = ""
    @State private var showFilter: Bool = false
    
    private enum StockGrouping: Identifiable {
        case none, productGroup, nextDueDate, lastPurchased, minStockAmount, parentProduct, defaultLocation
        var id: Int {
            hashValue
        }
    }
    @State private var stockGrouping: StockGrouping = .none
    @State private var sortSetting = [KeyPathComparator(\StockElement.product.name)]
    @State private var sortOrder: SortOrder = .forward
    
    @State private var filteredLocationID: Int?
    @State private var filteredProductGroupID: Int?
    @State private var filteredStatus: ProductStatus = .all
    
    @State private var selectedStockElement: StockElement? = nil
    
#if os(iOS)
    @State private var activeSheet: StockInteractionSheet?
#elseif os(macOS)
    @State private var activeSheet: StockInteractionPopover?
    @State private var showStockJournal: Bool = false
#endif
    
    private let dataToUpdate: [ObjectEntities] = [.products, .shopping_locations, .locations, .product_groups, .quantity_units, .shopping_lists, .shopping_list]
    private let additionalDataToUpdate: [AdditionalEntities] = [.stock, .volatileStock, .system_config, .user_settings]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    var numExpiringSoon: Int? {
        grocyVM.volatileStock?.dueProducts.count
    }
    
    var numOverdue: Int? {
        grocyVM.volatileStock?.overdueProducts.count
    }
    
    var numExpired: Int? {
        grocyVM.volatileStock?.expiredProducts.count
    }
    
    var numBelowStock: Int? {
        grocyVM.volatileStock?.missingProducts.count
    }
    
    var missingStock: Stock {
        var missingStockList: Stock = []
        for missingProduct in grocyVM.volatileStock?.missingProducts ?? [] {
            if !(missingProduct.isPartlyInStock) {
                if let foundProduct = grocyVM.mdProducts.first(where: { $0.id == missingProduct.id }) {
                    let missingStockElement = StockElement(amount: 0, amountAggregated: 0, value: 0.0, bestBeforeDate: nil, amountOpened: 0, amountOpenedAggregated: 0, isAggregatedAmount: false, dueType: foundProduct.dueType, productID: missingProduct.id, product: foundProduct)
                    missingStockList.append(missingStockElement)
                }
            }
        }
        return missingStockList
    }
    
    var stockWithMissing: Stock {
        grocyVM.stock + missingStock
    }
    
    var filteredProducts: Stock {
        stockWithMissing
            .filter {
                filteredStatus == .expiringSoon ? grocyVM.volatileStock?.dueProducts.map({$0.product.id}).contains($0.product.id) ?? false : true
            }
            .filter {
                filteredStatus == .overdue ? (grocyVM.volatileStock?.overdueProducts.map({$0.product.id}).contains($0.product.id) ?? false) && !(grocyVM.volatileStock?.expiredProducts.map({$0.product.id}).contains($0.product.id) ?? false) : true
            }
            .filter {
                filteredStatus == .expired ? grocyVM.volatileStock?.expiredProducts.map({$0.product.id}).contains($0.product.id) ?? false : true
            }
            .filter {
                filteredStatus == .belowMinStock ? grocyVM.volatileStock?.missingProducts.map({$0.id}).contains($0.product.id) ?? false : true
            }
            .filter {
                filteredLocationID != nil ? (($0.product.locationID == filteredLocationID) || (grocyVM.stockProductLocations[$0.product.id]?.first(where: { $0.locationID == filteredLocationID }) != nil)) : true
            }
            .filter {
                filteredProductGroupID != nil ? $0.product.productGroupID == filteredProductGroupID : true
            }
    }
    
    var searchedProducts: Stock {
        filteredProducts
            .filter {
                !searchString.isEmpty ? $0.product.name.localizedCaseInsensitiveContains(searchString) : true
            }
            .filter {
                $0.product.hideOnStockOverview == false
            }
            .sorted(using: sortSetting)
    }
    
    var groupedProducts: [String: [StockElement]] {
        var dict: [String: [StockElement]] = [:]
        var categoryName: String
        for element in searchedProducts {
            switch stockGrouping {
            case .productGroup:
                let productGroup = grocyVM.mdProductGroups.first(where: { $0.id == element.product.productGroupID })
                categoryName = productGroup?.name ?? ""
            case .nextDueDate:
                categoryName = element.bestBeforeDate?.iso8601withFractionalSeconds ?? ""
            case .lastPurchased:
                if grocyVM.stockProductDetails[element.productID] == nil {
                    Task {
                        try await grocyVM.getStockProductDetails(productID: element.productID)
                    }
                }
                categoryName = grocyVM.stockProductDetails[element.productID]?.lastPurchased?.iso8601withFractionalSeconds ?? ""
            case .minStockAmount:
                categoryName = element.product.minStockAmount.formattedAmount
            case .parentProduct:
                let parentProduct = grocyVM.mdProducts.first(where: { $0.id == element.product.parentProductID })
                categoryName = parentProduct?.name ?? ""
            case .defaultLocation:
                let defaultLocation = grocyVM.mdLocations.first(where: { $0.id == element.product.locationID })
                categoryName = defaultLocation?.name ?? ""
            default:
                categoryName = ""
            }
            if dict[categoryName] == nil {
                dict[categoryName] = []
            }
            dict[categoryName]?.append(element)
        }
        return dict
    }
    
    var summedValue: Double {
        let values = grocyVM.stock.map{ $0.value }
        return values.reduce(0, +)
    }
    
    var summedValueStr: String {
        return "\(String(format: "%.2f", summedValue)) \(grocyVM.getCurrencySymbol())"
    }
    
    var body: some View{
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 && grocyVM.failedToLoadAdditionalObjects.filter({ additionalDataToUpdate.contains($0) }).count == 0 {
            bodyContent
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.stock.stockOverview"))
        }
    }
    
#if os(macOS)
    var bodyContent: some View {
        contentmacOS
        //        StockTable(filteredStock: filteredProducts, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet)
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic, content: {
                    RefreshButton(updateData: { Task { await updateData() } })
                    sortMenu
                    Text("")
                        .popover(item: $activeSheet, content: { item in
                            switch item {
                            case .addToShL:
                                ShoppingListEntryFormView(isNewShoppingListEntry: true, productIDToSelect: selectedStockElement?.productID, isPopup: true)
                                    .padding()
                                    .frame(minWidth: 500, minHeight: 300)
                            case .productPurchase:
                                PurchaseProductView(stockElement: $selectedStockElement, isPopup: true)
                                    .frame(minWidth: 500, minHeight: 500)
                            case .productConsume:
                                ConsumeProductView(stockElement: $selectedStockElement, isPopup: true)
                                    .frame(minWidth: 500, minHeight: 300)
                            case .productTransfer:
                                TransferProductView(stockElement: $selectedStockElement, isPopup: true)
                                    .frame(minWidth: 500, minHeight: 300)
                            case .productInventory:
                                InventoryProductView(stockElement: $selectedStockElement, isPopup: true)
                                    .frame(minWidth: 500, minHeight: 500)
                            case .productOverview:
                                StockProductInfoView(stockElement: $selectedStockElement)
                                    .frame(minWidth: 400, minHeight: 300)
                            case .productJournal:
                                StockJournalView(stockElement: $selectedStockElement)
                                    .frame(minWidth: 500, minHeight: 300)
                            case .editProduct:
                                MDProductFormView(isNewProduct: false, product: selectedStockElement?.product, showAddProduct: Binding.constant(false), isPopup: true)
                                    .frame(minWidth: 400, minHeight: 300)
                            }
                        })
                    Button(action: {
                        self.showStockJournal.toggle()
                    }, label: {
                        Label("Journal", systemImage: MySymbols.stockJournal)
                    })
                    .popover(isPresented: $showStockJournal, content: {
                        StockJournalView()
                            .padding()
                            .frame(width: 700, height: 500, alignment: .leading)
                    })
                })
            })
            .navigationSubtitle(LocalizedStringKey("str.stock.stockOverviewInfo \(grocyVM.stock.count) \(summedValueStr)"))
    }
#elseif os(iOS)
    var bodyContent: some View {
        content
            .toolbar(content: {
                ToolbarItem(placement: .automatic, content: {
                    HStack{
                        sortMenu
                        Button(action: {
                            activeSheet = .stockJournal
                        }, label: {
                            Label(LocalizedStringKey("str.details.stockJournal"), systemImage: MySymbols.stockJournal)
                        })
                        Button(action: {
                            activeSheet = .inventoryProduct
                        }, label: {
                            Label(LocalizedStringKey("str.stock.inventory"), systemImage: MySymbols.inventory)
                        })
                        Button(action: {
                            activeSheet = .transferProduct
                        }, label: {
                            Label(LocalizedStringKey("str.stock.transfer"), systemImage: MySymbols.transfer)
                        })
                        Button(action: {
                            activeSheet = .consumeProduct
                        }, label: {
                            Label(LocalizedStringKey("str.stock.consume"), systemImage: MySymbols.consume)
                        })
                        Button(action: {
                            activeSheet = .purchaseProduct
                        }, label: {
                            Label(LocalizedStringKey("str.stock.buy"), systemImage: MySymbols.purchase)
                        })
                    }
                })
            })
            .sheet(item: $activeSheet, content: { item in
                switch item {
                case .stockJournal:
                    StockJournalView()
                case .purchaseProduct:
                    NavigationView{
                        PurchaseProductView()
                    }
                case .consumeProduct:
                    NavigationView{
                        ConsumeProductView()
                    }
                case .transferProduct:
                    NavigationView{
                        TransferProductView()
                    }
                case .inventoryProduct:
                    NavigationView{
                        InventoryProductView()
                    }
                case .addToShL:
                    ShoppingListEntryFormView(isNewShoppingListEntry: true, productIDToSelect: selectedStockElement?.productID)
                case .productPurchase:
                    NavigationView{
                        PurchaseProductView(stockElement: $selectedStockElement)
                    }
                case .productConsume:
                    NavigationView{
                        ConsumeProductView(stockElement: $selectedStockElement)
                    }
                case .productTransfer:
                    NavigationView{
                        TransferProductView(stockElement: $selectedStockElement)
                    }
                case .productInventory:
                    NavigationView{
                        InventoryProductView(stockElement: $selectedStockElement)
                    }
                case .productOverview:
                    NavigationView {
                        StockProductInfoView(stockElement: $selectedStockElement)
                    }
                case .productJournal:
                    StockJournalView(stockElement: $selectedStockElement)
                case .editProduct:
                    NavigationView{
                        MDProductFormView(isNewProduct: false, product: selectedStockElement?.product, showAddProduct: Binding.constant(false), isPopup: true)
                    }
                }
            })
    }
#endif
    
    var contentmacOS: some View {
        VStack {
            Group {
                StockFilterActionsView(filteredStatus: $filteredStatus, numExpiringSoon: numExpiringSoon, numOverdue: numOverdue, numExpired: numExpired, numBelowStock: numBelowStock)
                StockFilterBar(searchString: $searchString, filteredLocation: $filteredLocationID, filteredProductGroup: $filteredProductGroupID, filteredStatus: $filteredStatus)
            }
            .padding()
            NavigationView {
                List {
                    if grocyVM.stock.isEmpty {
                        ContentUnavailableView("str.stock.empty", systemImage: MySymbols.stockOverview)
                    }
                    ForEach(groupedProducts.sorted(by: {
                        switch stockGrouping {
                        case .minStockAmount:
                            return $0.key.compare($1.key, options: .numeric) == .orderedAscending
                        case .lastPurchased, .nextDueDate:
                            return $0.key.iso8601withFractionalSeconds ?? Date() < $1.key.iso8601withFractionalSeconds ?? Date()
                        default:
                            return $0.key < $1.key
                        }
                    }), id: \.key) { groupName, groupElements in
                        if stockGrouping == .none {
                            ForEach(groupElements, id:\.product.id) { stockElement in
                                StockTableRow(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet)
                            }
                        }
                        Section(content: {
                            ForEach(groupElements, id:\.product.id) { stockElement in
                                StockTableRow(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet)
                            }
                        }, header: {
                            if stockGrouping == .productGroup, groupName.isEmpty {
                                Text(LocalizedStringKey("str.shL.ungrouped")).italic()
                            } else {
                                switch stockGrouping {
                                case .lastPurchased, .nextDueDate:
                                    Text(groupName.iso8601withFractionalSeconds?.formatted(date: .numeric, time: .omitted) ?? "").bold()
                                default:
                                    Text(groupName).bold()
                                }
                            }
                        })
                    }
                }
                .frame(minWidth: 350)
            }
        }
        .navigationTitle(LocalizedStringKey("str.stock.stockOverview"))
        .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
        .animation(.default, value: groupedProducts.count)
        .animation(.default, value: sortSetting)
        .task {
            if firstAppear {
                Task {
                    await updateData()
                    firstAppear = false
                }
            }
        }
    }
    
    var content: some View {
        List {
            Section {
                StockFilterActionsView(filteredStatus: $filteredStatus, numExpiringSoon: numExpiringSoon, numOverdue: numOverdue, numExpired: numExpired, numBelowStock: numBelowStock)
                StockFilterBar(searchString: $searchString, filteredLocation: $filteredLocationID, filteredProductGroup: $filteredProductGroupID, filteredStatus: $filteredStatus)
            }
            if grocyVM.stock.isEmpty {
                ContentUnavailableView("str.stock.empty", systemImage: MySymbols.stockOverview)
            }
            ForEach(groupedProducts.sorted(by: { $0.key < $1.key }), id: \.key) { groupName, groupElements in
                Section(content: {
                    ForEach(groupElements.sorted(using: sortSetting), id: \.productID, content: { stockElement in
                        StockTableRow(
                            stockElement: stockElement,
                            selectedStockElement: $selectedStockElement,
                            activeSheet: $activeSheet
                        )
                    })
                }, header: {
                    if stockGrouping == .productGroup, groupName.isEmpty {
                        Text(LocalizedStringKey("str.shL.ungrouped")).italic()
                    } else if stockGrouping == .none {
                        EmptyView()
                    } else {
                        Text(groupName).bold()
                    }
                })
            }
        }
        .navigationTitle(LocalizedStringKey("str.stock.stockOverview"))
        .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
        .refreshable {
            await updateData()
        }
        .animation(.default, value: groupedProducts.count)
        .task {
            if firstAppear {
                Task {
                    await updateData()
                    firstAppear = false
                }
            }
        }
    }
    
    var sortMenu: some View {
        Menu(content: {
            Picker(LocalizedStringKey("str.group.category"), selection: $stockGrouping, content: {
                Label(LocalizedStringKey("str.none"), systemImage: MySymbols.product)
                    .labelStyle(.titleAndIcon)
                    .tag(StockGrouping.none)
                Label(LocalizedStringKey("str.stock.productGroup"), systemImage: MySymbols.amount)
                    .labelStyle(.titleAndIcon)
                    .tag(StockGrouping.productGroup)
                Label(LocalizedStringKey("str.stock.tbl.nextDueDate"), systemImage: MySymbols.date)
                    .labelStyle(.titleAndIcon)
                    .tag(StockGrouping.nextDueDate)
                Label(LocalizedStringKey("str.stock.tbl.lastPurchased"), systemImage: MySymbols.date)
                    .labelStyle(.titleAndIcon)
                    .tag(StockGrouping.lastPurchased)
                Label(LocalizedStringKey("str.stock.tbl.minStockAmount"), systemImage: MySymbols.amount)
                    .labelStyle(.titleAndIcon)
                    .tag(StockGrouping.minStockAmount)
                Label(LocalizedStringKey("str.stock.tbl.parentProduct"), systemImage: MySymbols.product)
                    .labelStyle(.titleAndIcon)
                    .tag(StockGrouping.parentProduct)
                Label(LocalizedStringKey("str.stock.tbl.defaultLocation"), systemImage: MySymbols.location)
                    .labelStyle(.titleAndIcon)
                    .tag(StockGrouping.defaultLocation)
            })
#if os(iOS)
            .pickerStyle(.menu)
#else
            .pickerStyle(.inline)
#endif
            Picker(LocalizedStringKey("str.sort.category"), selection: $sortSetting, content: {
                if sortOrder == .forward {
                    Label(LocalizedStringKey("str.md.product.name"), systemImage: MySymbols.product)
                        .labelStyle(.titleAndIcon)
                        .tag([KeyPathComparator(\StockElement.product.name, order: .forward)])
                    Label(LocalizedStringKey("str.stock.buy.product.dueDate"), systemImage: MySymbols.date)
                        .labelStyle(.titleAndIcon)
                        .tag([KeyPathComparator(\StockElement.bestBeforeDate, order: .forward)])
                    Label(LocalizedStringKey("str.stock.product.amount"), systemImage: MySymbols.amount)
                        .labelStyle(.titleAndIcon)
                        .tag([KeyPathComparator(\StockElement.amount, order: .forward)])
                } else {
                    Label(LocalizedStringKey("str.md.product.name"), systemImage: MySymbols.product)
                        .labelStyle(.titleAndIcon)
                        .tag([KeyPathComparator(\StockElement.product.name, order: .reverse)])
                    Label(LocalizedStringKey("str.stock.buy.product.dueDate"), systemImage: MySymbols.date)
                        .labelStyle(.titleAndIcon)
                        .tag([KeyPathComparator(\StockElement.bestBeforeDate, order: .reverse)])
                    Label(LocalizedStringKey("str.stock.product.amount"), systemImage: MySymbols.amount)
                        .labelStyle(.titleAndIcon)
                        .tag([KeyPathComparator(\StockElement.amount, order: .reverse)])
                }
            })
#if os(iOS)
            .pickerStyle(.menu)
#else
            .pickerStyle(.inline)
#endif
            Picker(LocalizedStringKey("str.sort.order"), selection: $sortOrder, content: {
                Label(LocalizedStringKey("str.sort.order.forward"), systemImage: MySymbols.sortForward)
                    .labelStyle(.titleAndIcon)
                    .tag(SortOrder.forward)
                Label(LocalizedStringKey("str.sort.order.reverse"), systemImage: MySymbols.sortReverse)
                    .labelStyle(.titleAndIcon)
                    .tag(SortOrder.reverse)
            })
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
        }, label: {
            Label(LocalizedStringKey("str.sort"), systemImage: MySymbols.sort)
        })
    }
}

struct StockView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
            StockView()
                .preferredColorScheme(scheme)
        }
    }
}
