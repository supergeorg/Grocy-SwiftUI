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

enum StockInteractionSheet: Identifiable {
    case none, purchaseProduct, consumeProduct, transferProduct, inventoryProduct, stockJournal, addToShL, productPurchase, productConsume, productTransfer, productInventory
    var id: Int {
        self.hashValue
    }
}

struct StockView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("expiringDays") var expiringDays: Int = 5
    
    @State private var reloadRotationDeg: Double = 0.0
    
    @State private var isShowingSheet: Bool = false
    
    @State private var showSearch: Bool = false
    @State private var showFilter: Bool = false
    
    @State private var searchString: String = ""
    
    @State private var filteredLocation: String = ""
    @State private var filteredProductGroup: String = ""
    @State private var filteredStatus: ProductStatus = .all
    
    @State private var selectedStockElement: StockElement? = nil
    
    #if os(macOS)
    @State private var showStockJournal: Bool = false
    #endif
    
    @State private var activeSheet: StockInteractionSheet = .none
    
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
                ($0.dueType == "1") && ((getTimeDistanceFromString($0.bestBeforeDate) ?? 100) < 0)
            }
            .count
    }
    
    var numExpired: Int {
        grocyVM.stock
            .filter {
                ($0.dueType == "2") && ((getTimeDistanceFromString($0.bestBeforeDate) ?? 100) < 0)
            }
            .count
    }
    
    var numBelowStock: Int {
        grocyVM.stock
            .filter {
                Int($0.amount) ?? 1 < Int($0.product.minStockAmount) ?? 0
            }
            .count
    }
    
    var filteredProducts: Stock {
        grocyVM.stock
            .filter {
                filteredStatus == .expiringSoon ? ((0..<(expiringDays + 1)) ~= getTimeDistanceFromString($0.bestBeforeDate) ?? 100) : true
            }
            .filter {
                filteredStatus == .overdue ? ($0.dueType == "1" ? (getTimeDistanceFromString($0.bestBeforeDate) ?? 100 < 0) : false) : true
            }
            .filter {
                filteredStatus == .expired ? ($0.dueType == "2" ? (getTimeDistanceFromString($0.bestBeforeDate) ?? 100 < 0) : false) : true
            }
            .filter {
                filteredStatus == .belowMinStock ? Int($0.amount) ?? 1 < Int($0.product.minStockAmount) ?? 0 : true
            }
            .filter {
                !filteredLocation.isEmpty ? $0.product.locationID == filteredLocation : true
            }
            .filter {
                !filteredProductGroup.isEmpty ? $0.product.productGroupID == filteredProductGroup : true
            }
            .filter {
                !searchString.isEmpty ? $0.product.name.localizedCaseInsensitiveContains(searchString) : true
            }
    }
    
    var summedValue: Double {
        let values = grocyVM.stock.map{ Double($0.value) ?? 0 }
        return values.reduce(0, +)
    }
    
    private func updateData() {
        if grocyVM.stock.isEmpty {
            grocyVM.getStock()
            grocyVM.getMDProducts()
            grocyVM.getMDShoppingLocations()
            grocyVM.getMDLocations()
            grocyVM.getMDProductGroups()
            grocyVM.getMDQuantityUnits()
            grocyVM.getSystemConfig()
        }
    }
    
    var body: some View {
        #if os(macOS)
        content
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic, content: {
                    Button(action: {
                        self.showStockJournal.toggle()
                        //                        self.activeSheet = .stockJournal
                        //                        self.isShowingSheet.toggle()
                    }, label: {
                        Label("Journal", systemImage: "list.bullet.rectangle")
                    })
                    .popover(isPresented: $showStockJournal, content: {
                        StockJournalView()
                            .padding()
                            .frame(width: 300, height: 300, alignment: .leading)
                    })
                    Button(action: {
                        withAnimation {
                            self.reloadRotationDeg += 360
                        }
                        updateData()
                    }, label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(Angle.degrees(reloadRotationDeg))
                    })
                })
            })
            .navigationSubtitle(LocalizedStringKey("str.stock.stockOverviewInfo \(grocyVM.stock.count) \(summedValueStr)"))
        //            .navigationSubtitle(LocalizedStringKey("str.stock.stockOverviewInfo %d %@", grocyVM.stock.count, summedValueStr))
        #elseif os(iOS)
        content
            .toolbar(content: {
                ToolbarItem(placement: .automatic, content: {
                    HStack{
                        Button(action: {
                            updateData()
                        }, label: {
                            Image(systemName: "arrow.clockwise")
                        })
                        Button(action: {
                            self.activeSheet = .stockJournal
                            self.isShowingSheet.toggle()
                        }, label: {
                            Label(LocalizedStringKey("str.details.stockJournal"), systemImage: "list.bullet.rectangle")
                        })
                        Button(action: {
                            self.activeSheet = .inventoryProduct
                            self.isShowingSheet.toggle()
                        }, label: {
                            Label(LocalizedStringKey("str.stock.inventory"), systemImage: "list.bullet")
                        })
                        Button(action: {
                            self.activeSheet = .transferProduct
                            self.isShowingSheet.toggle()
                        }, label: {
                            Label(LocalizedStringKey("str.stock.transfer"), systemImage: "arrow.left.arrow.right")
                        })
                        Button(action: {
                            self.activeSheet = .consumeProduct
                            self.isShowingSheet.toggle()
                        }, label: {
                            Label(LocalizedStringKey("str.stock.consume"), systemImage: "tuningfork")
                        })
                        Button(action: {
                            self.activeSheet = .purchaseProduct
                            self.isShowingSheet.toggle()
                        }, label: {
                            Label(LocalizedStringKey("str.stock.buy"), systemImage: "cart.badge.plus")
                        })
                    }
                })
            })
            .sheet(isPresented: $isShowingSheet, content: {
                switch activeSheet {
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
                        PurchaseProductView(productToPurchaseID: selectedStockElement?.product.id)
                    }
                case .productConsume:
                    NavigationView{
                        ConsumeProductView(productToConsumeID: selectedStockElement?.product.id)
                    }
                case .productTransfer:
                    NavigationView{
                        TransferProductView(productToTransferID: selectedStockElement?.product.id)
                    }
                case .productInventory:
                    NavigationView{
                        InventoryProductView(productToInventoryID: selectedStockElement?.product.id)
                    }
                case .none:
                    EmptyView()
                }
            })
        #endif
    }
    
    var summedValueStr: String {
        return "\(String(format: "%.2f", summedValue)) \(grocyVM.getCurrencySymbol())"
    }
    
    var content: some View {
        List() {
            StockFilterActionsView(filteredStatus: $filteredStatus, numExpiringSoon: numExpiringSoon, numOverdue: numOverdue, numExpired: numExpired, numBelowStock: numBelowStock)
            StockFilterBar(searchString: $searchString, filteredLocation: $filteredLocation, filteredProductGroup: $filteredProductGroup, filteredStatus: $filteredStatus)
            if grocyVM.stock.isEmpty {
                Text("str.stock.empty").padding()
            }
            StockTable(filteredStock: filteredProducts, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, isShowingSheet: $isShowingSheet)
        }
        .listStyle(InsetListStyle())
        .animation(.default)
        .navigationTitle("str.stock.stockOverview".localized)
        .onAppear(perform: {
            updateData()
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
