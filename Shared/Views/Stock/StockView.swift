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
    
    @AppStorage("expiringDays") var expiringDays: Int = 5
    
    @State private var reloadRotationDeg: Double = 0.0
    
    @State private var showSearch: Bool = false
    @State private var showFilter: Bool = false
    
    @State private var searchString: String = ""
    
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
    private let additionalDataToUpdate: [AdditionalEntities] = [.stock, .system_config]
    
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    var numExpiringSoon: Int {
        grocyVM.stock
            .filter {
                (0..<(expiringDays + 1)) ~= (getTimeDistanceFromString($0.bestBeforeDate) ?? 100)
            }
            .count
    }
    
    var numOverdue: Int {
        grocyVM.stock
            .filter {
                ($0.dueType == 1) && ((getTimeDistanceFromString($0.bestBeforeDate) ?? 100) < 0)
            }
            .count
    }
    
    var numExpired: Int {
        grocyVM.stock
            .filter {
                ($0.dueType == 2) && ((getTimeDistanceFromString($0.bestBeforeDate) ?? 100) < 0)
            }
            .count
    }
    
    var numBelowStock: Int {
        grocyVM.stock
            .filter {
                $0.amount < $0.product.minStockAmount
            }
            .count
    }
    
    var filteredProducts: Stock {
        grocyVM.stock
            .filter {
                filteredStatus == .expiringSoon ? ((0..<(expiringDays + 1)) ~= getTimeDistanceFromString($0.bestBeforeDate) ?? 100) : true
            }
            .filter {
                filteredStatus == .overdue ? ($0.dueType == 1 ? (getTimeDistanceFromString($0.bestBeforeDate) ?? 100 < 0) : false) : true
            }
            .filter {
                filteredStatus == .expired ? ($0.dueType == 2 ? (getTimeDistanceFromString($0.bestBeforeDate) ?? 100 < 0) : false) : true
            }
            .filter {
                filteredStatus == .belowMinStock ? $0.amount < $0.product.minStockAmount : true
            }
            .filter {
                filteredLocationID != nil ? $0.product.locationID == filteredLocationID : true
            }
            .filter {
                filteredProductGroupID != nil ? $0.product.productGroupID == filteredProductGroupID : true
            }
            .filter {
                !searchString.isEmpty ? $0.product.name.localizedCaseInsensitiveContains(searchString) : true
            }
    }
    
    var summedValue: Double {
        let values = grocyVM.stock.map{ $0.value }
        return values.reduce(0, +)
    }
    
    var body: some View{
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 && grocyVM.failedToLoadAdditionalObjects.filter({additionalDataToUpdate.contains($0)}).count == 0 {
            bodyContent
        } else {
            ServerOfflineView()
                .navigationTitle(LocalizedStringKey("str.stock.stockOverview"))
        }
    }
    
    #if os(macOS)
    var bodyContent: some View {
        content
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic, content: {
                    Text("")
                        .popover(item: $activeSheet, content: { item in
                            switch item {
                            case .addToShL:
                                ShoppingListEntryFormView(isNewShoppingListEntry: true, product: selectedStockElement?.product)
                                    .padding()
                                    .frame(minWidth: 400, minHeight: 300)
                            case .productPurchase:
                                PurchaseProductView(productToPurchaseID: selectedStockElement?.productID)
                                    .frame(minWidth: 400, minHeight: 300)
                            case .productConsume:
                                ConsumeProductView(productToConsumeID: selectedStockElement?.productID)
                                    .frame(minWidth: 400, minHeight: 300)
                            case .productTransfer:
                                TransferProductView(productToTransferID: selectedStockElement?.productID)
                                    .frame(minWidth: 400, minHeight: 300)
                            case .productInventory:
                                InventoryProductView(productToInventoryID: selectedStockElement?.productID)
                                    .frame(minWidth: 400, minHeight: 300)
                            case .productOverview:
                                ProductOverviewView(productDetails: ProductDetailsModel(product: selectedStockElement?.product))
                                    .frame(minWidth: 400, minHeight: 300)
                            case .productJournal:
                                StockJournalView(selectedProductID: selectedStockElement?.product.id)
                                    .frame(minWidth: 400, minHeight: 300)
                            case .editProduct:
                                MDProductFormView(isNewProduct: false, product: selectedStockElement?.product, showAddProduct: Binding.constant(false), toastType: $mdToastType)
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
                    Button(action: {
                        withAnimation {
                            self.reloadRotationDeg += 360
                        }
                        updateData()
                    }, label: {
                        Image(systemName: MySymbols.reload)
                            .rotationEffect(Angle.degrees(reloadRotationDeg))
                    })
                })
                ToolbarItem(placement: .automatic, content: {
                    ToolbarSearchField(searchTerm: $searchString)
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
                            updateData()
                        }, label: {
                            Image(systemName: MySymbols.reload)
                        })
                        Button(action: {
                            self.activeSheet = .stockJournal
                        }, label: {
                            Label(LocalizedStringKey("str.details.stockJournal"), systemImage: MySymbols.stockJournal)
                        })
                        Button(action: {
                            self.activeSheet = .inventoryProduct
                        }, label: {
                            Label(LocalizedStringKey("str.stock.inventory"), systemImage: MySymbols.inventory)
                        })
                        Button(action: {
                            self.activeSheet = .transferProduct
                        }, label: {
                            Label(LocalizedStringKey("str.stock.transfer"), systemImage: MySymbols.transfer)
                        })
                        Button(action: {
                            self.activeSheet = .consumeProduct
                        }, label: {
                            Label(LocalizedStringKey("str.stock.consume"), systemImage: MySymbols.consume)
                        })
                        Button(action: {
                            self.activeSheet = .purchaseProduct
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
                        PurchaseProductView(productToPurchaseID: selectedStockElement?.productID)
                    }
                case .productConsume:
                    NavigationView{
                        ConsumeProductView(productToConsumeID: selectedStockElement?.productID)
                    }
                case .productTransfer:
                    NavigationView{
                        TransferProductView(productToTransferID: selectedStockElement?.productID)
                    }
                case .productInventory:
                    NavigationView{
                        InventoryProductView(productToInventoryID: selectedStockElement?.productID)
                    }
                case .productOverview:
                    NavigationView{
                        ProductOverviewView(productDetails: ProductDetailsModel(product: selectedStockElement?.product))
                    }
                case .productJournal:
                    StockJournalView(selectedProductID: selectedStockElement?.product.id)
                case .editProduct:
                    NavigationView{
                        MDProductFormView(isNewProduct: false, product: selectedStockElement?.product, showAddProduct: Binding.constant(false), toastType: $mdToastType)
                    }
                }
            })
    }
    #endif
    
    var summedValueStr: String {
        return "\(String(format: "%.2f", summedValue)) \(grocyVM.getCurrencySymbol())"
    }
    
    var content: some View {
        List() {
            StockFilterActionsView(filteredStatus: $filteredStatus, numExpiringSoon: numExpiringSoon, numOverdue: numOverdue, numExpired: numExpired, numBelowStock: numBelowStock)
            StockFilterBar(searchString: $searchString, filteredLocation: $filteredLocationID, filteredProductGroup: $filteredProductGroupID, filteredStatus: $filteredStatus)
            if grocyVM.stock.isEmpty {
                Text("str.stock.empty").padding()
            }
            StockTable(filteredStock: filteredProducts, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, toastType: $toastType)
            // the sheets don't work without this
            Text(selectedStockElement?.product.name ?? "no stockElement")
                .font(.caption)
                .hidden()
        }
        .listStyle(InsetListStyle())
//        .animation(.default)
        .navigationTitle(LocalizedStringKey("str.stock.stockOverview"))
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate, ignoreCached: false)
                firstAppear = false
            }
        })
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successConsumeOne || toastType == .successConsumeAll || toastType == .successOpenOne || toastType == .successConsumeAllSpoiled), content: { item in
            switch item {
            case .successConsumeOne:
                Label(LocalizedStringKey("str.stock.tbl.action.successConsumeOne \(selectedStockElement?.product.name ?? "")"), systemImage: MySymbols.success)
            case .successConsumeAll:
                Label(LocalizedStringKey("str.stock.tbl.action.successConsumeAll \(selectedStockElement?.product.name ?? "")"), systemImage: MySymbols.success)
            case .successOpenOne:
                Label(LocalizedStringKey("str.stock.tbl.action.successOpenOne \(selectedStockElement?.product.name ?? "")"), systemImage: MySymbols.success)
            case .successConsumeAllSpoiled:
                Label(LocalizedStringKey("str.stock.tbl.action.successConsumeAllSpoiled \(selectedStockElement?.product.name ?? "")"), systemImage: MySymbols.success)
            case .fail:
                Label(LocalizedStringKey("str.stock.tbl.action.fail"), systemImage: MySymbols.failure)
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
