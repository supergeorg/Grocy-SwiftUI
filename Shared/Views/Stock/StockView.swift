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

struct StockView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    @Environment(\.presentationMode) private var presentationMode
    
    @AppStorage("expiringDays") var expiringDays: Int = 5
    
    @State private var isShowingSheet: Bool = false
    
    @State private var showSearch: Bool = false
    @State private var showFilter: Bool = false
    
    @State private var searchString: String = ""
    
    @State private var filteredLocation: String = ""
    @State private var filteredProductGroup: String = ""
    @State private var filteredStatus: ProductStatus = .all
    
    @State private var showTableSettings: Bool = false
    @AppStorage("stockShowProduct") var stockShowProduct: Bool = true
    @AppStorage("stockShowProductGroup") var stockShowProductGroup: Bool = false
    @AppStorage("stockShowAmount") var stockShowAmount: Bool = true
    @AppStorage("stockShowValue") var stockShowValue: Bool = false
    @AppStorage("stockShowNextBestBeforeDate") var stockShowNextBestBeforeDate: Bool = true
    @AppStorage("stockShowCaloriesPerStockQU") var stockShowCaloriesPerStockQU: Bool = false
    @AppStorage("stockShowCalories") var stockShowCalories: Bool = false
    @State private var sortedStockColumn: StockColumn = .product
    @State private var sortAscending: Bool = true
    
    //    @State private var showStockJournal: Bool = false
    
    private enum InteractionSheet: Identifiable {
        case none, purchaseProduct, consumeProduct, transferProduct, stockJournal
        var id: Int {
            self.hashValue
        }
    }
    
    @State private var activeSheet: InteractionSheet = .none
    
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
            .sorted {
                switch sortedStockColumn {
                case .product:
                    return sortAscending ? ($0.product.name < $1.product.name) : ($0.product.name > $1.product.name)
                case .productGroup:
                    return sortAscending ? ($0.product.productGroupID < $1.product.productGroupID) : ($0.product.productGroupID > $1.product.productGroupID)
                case .amount:
                    return sortAscending ? ($0.amount < $1.amount) : ($0.amount > $1.amount)
                case .nextBestBeforeDate:
                    return sortAscending ? ($0.bestBeforeDate < $1.bestBeforeDate) : ($0.bestBeforeDate > $1.bestBeforeDate)
                default:
                    return ($0.productID < $1.productID)
                }
            }
    }
    
    private func updateData() {
        grocyVM.getStock()
        grocyVM.getMDProducts()
        grocyVM.getMDShoppingLocations()
        grocyVM.getMDLocations()
        grocyVM.getMDProductGroups()
        grocyVM.getMDQuantityUnits()
    }
    
    var body: some View {
        List() {
            StockFilterActionsView(filteredStatus: $filteredStatus, numExpiringSoon: numExpiringSoon, numOverdue: numOverdue, numExpired: numExpired, numBelowStock: numBelowStock)
            StockFilterBar(searchString: $searchString, filteredLocation: $filteredLocation, filteredProductGroup: $filteredProductGroup, filteredStatus: $filteredStatus)
            if grocyVM.stock.isEmpty {
                Text("str.stock.empty").padding()
            }
            Button(action: {
                showTableSettings.toggle()
            }, label: {
                Image(systemName: "eye.fill")
            })
            .popover(isPresented: $showTableSettings, content: {
                StockTableConfigView(showProduct: $stockShowProduct, showProductGroup: $stockShowProductGroup, showAmount: $stockShowAmount, showValue: $stockShowValue, showNextBestBeforeDate: $stockShowNextBestBeforeDate, showCaloriesPerStockQU: $stockShowCaloriesPerStockQU, showCalories: $stockShowCalories)
                    .padding()
            })
            StockTable(showProduct: $stockShowProduct, showProductGroup: $stockShowProductGroup, showAmount: $stockShowAmount, showValue: $stockShowValue, showNextBestBeforeDate: $stockShowNextBestBeforeDate, showCaloriesPerStockQU: $stockShowCaloriesPerStockQU, showCalories: $stockShowCalories, filteredStock: filteredProducts, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
            //            ForEach(filteredProducts, id:\.productID) { stock in
            //                StockRowView(stockElement: stock)
            //            }
        }.listStyle(InsetListStyle())
        .animation(.default)
        .navigationTitle("str.stock.stockOverview".localized)
        .onAppear(perform: {
            updateData()
        })
        .toolbar(content: {
            #if os(macOS)
            ToolbarItem(placement: .automatic, content: {
                Button(action: {
                    updateData()
                }, label: {
                    Image(systemName: "arrow.clockwise")
                })
                Button(action: {
                    showStockJournal.toggle()
                }, label: {
                    Label("Journal", systemImage: "list.bullet.rectangle")
                })
                .popover(isPresented: $showStockJournal, content: {
                    StockJournalView().padding().frame(width: 300, height: 300, alignment: .leading)
                })
            })
            #else
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
                        Label("Journal", systemImage: "list.bullet.rectangle")
                    })
                    Button(action: {
                        self.activeSheet = .purchaseProduct
                        self.isShowingSheet.toggle()
                    }, label: {
                        Label("Purchase", systemImage: "cart.badge.plus")
                    })
                }
            })
            #endif
        })
        .sheet(isPresented: $isShowingSheet, content: {
            switch activeSheet {
            case .stockJournal:
                StockJournalView()
            case .purchaseProduct:
                PurchaseProductView()
            case .consumeProduct:
                ConsumeProductView()
            case .transferProduct:
                TransferProductView()
            case .none:
                EmptyView()
            }
        })
    }
}

struct StockView_Previews: PreviewProvider {
    static var previews: some View {
        StockView()
    }
}
