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
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var firstAppear: Bool = true
    
    @State private var searchString: String = ""
    @State private var showFilter: Bool = false
    
    @State private var filteredLocationID: Int?
    @State private var filteredProductGroupID: Int?
    @State private var filteredStatus: ProductStatus = .all
    
    @State private var selectedStockElement: StockElement? = nil
    @State private var toastType: RowActionToastType?
    @State private var mdToastType: MDToastType?
    
#if os(iOS)
    @State private var activeSheet: StockInteractionSheet?
#elseif os(macOS)
    @State private var activeSheet: StockInteractionPopover?
    @State private var showStockJournal: Bool = false
#endif
    
    private let dataToUpdate: [ObjectEntities] = [.products, .shopping_locations, .locations, .product_groups, .quantity_units, .shopping_lists, .shopping_list]
    private let additionalDataToUpdate: [AdditionalEntities] = [.stock, .volatileStock, .system_config, .user_settings]
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
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
                filteredLocationID != nil ? $0.product.locationID == filteredLocationID : true
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
                $0.product.hideOnStockOverview == 0
            }
            .sorted(by: { $0.product.name < $1.product.name })
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
        content
        //        StockTable(filteredStock: filteredProducts, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, toastType: $toastType)
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic, content: {
                    RefreshButton(updateData: { updateData() })
                    Text("")
                        .popover(item: $activeSheet, content: { item in
                            switch item {
                            case .addToShL:
                                ShoppingListEntryFormView(isNewShoppingListEntry: true, product: selectedStockElement?.product, isPopup: true)
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
                                MDProductFormView(isNewProduct: false, product: selectedStockElement?.product, showAddProduct: Binding.constant(false), toastType: $mdToastType, isPopup: true)
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
                    ShoppingListEntryFormView(isNewShoppingListEntry: true, product: selectedStockElement?.product)
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
                        MDProductFormView(isNewProduct: false, product: selectedStockElement?.product, showAddProduct: Binding.constant(false), toastType: $mdToastType, isPopup: true)
                    }
                }
            })
    }
#endif
    
    var content: some View {
        List {
            Section {
                StockFilterActionsView(filteredStatus: $filteredStatus, numExpiringSoon: numExpiringSoon, numOverdue: numOverdue, numExpired: numExpired, numBelowStock: numBelowStock)
                StockFilterBar(searchString: $searchString, filteredLocation: $filteredLocationID, filteredProductGroup: $filteredProductGroupID, filteredStatus: $filteredStatus)
            }
            Section {
                if grocyVM.stock.isEmpty {
                    Text("str.stock.empty").padding()
                }
                ForEach(searchedProducts, id:\.productID) { stockElement in
                    StockTableRow(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, toastType: $toastType)
                }
            }
        }
        .navigationTitle(LocalizedStringKey("str.stock.stockOverview"))
        .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
        .refreshable {
            updateData()
        }
        .animation(.default, value: searchedProducts.count)
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate, ignoreCached: false)
                firstAppear = false
            }
        })
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successConsumeOne || toastType == .successConsumeAll || toastType == .successOpenOne || toastType == .successConsumeAllSpoiled), text: { item in
            switch item {
            case .successConsumeOne:
                return LocalizedStringKey("str.stock.tbl.action.successConsumeOne \(selectedStockElement?.product.name ?? "")")
            case .successConsumeAll:
                return LocalizedStringKey("str.stock.tbl.action.successConsumeAll \(selectedStockElement?.product.name ?? "")")
            case .successOpenOne:
                return LocalizedStringKey("str.stock.tbl.action.successOpenOne \(selectedStockElement?.product.name ?? "")")
            case .successConsumeAllSpoiled:
                return LocalizedStringKey("str.stock.tbl.action.successConsumeAllSpoiled \(selectedStockElement?.product.name ?? "")")
            case .fail:
                return LocalizedStringKey("str.stock.tbl.action.fail")
            }
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
