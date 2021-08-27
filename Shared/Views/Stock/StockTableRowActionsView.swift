//
//  StockTableRowActionsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 07.12.20.
//

import SwiftUI

struct StockTableRowActionsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var stockElement: StockElement
    @Binding var selectedStockElement: StockElement?
    #if os(iOS)
    @Binding var activeSheet: StockInteractionSheet?
    #elseif os(macOS)
    @Binding var activeSheet: StockInteractionPopover?
    #endif
    @Binding var toastType: RowActionToastType?
    @State private var mdToastType: MDToastType?
    @State private var showConsumeAll: Bool = false
    
    var quantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: {$0.id == stockElement.product.quIDStock})
    }
    private func getQUString(amount: Double) -> String {
        return amount == 1.0 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? ""
    }
    
    var body: some View {
        HStack(spacing: 2){
            RowInteractionButton(title: formatAmount(stockElement.product.quickConsumeAmount ?? 1.0), image: MySymbols.consume, backgroundColor: Color.grocyGreen, helpString: LocalizedStringKey("str.stock.tbl.action.consume \("\(stockElement.product.quickConsumeAmount ?? 1.0) \(getQUString(amount: stockElement.product.quickConsumeAmount ?? 1.0)) \(stockElement.product.name)")"))
                .onTapGesture {
                    selectedStockElement = stockElement
                    grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .consume, content: ProductConsume(amount: stockElement.product.quickConsumeAmount ?? 1.0, transactionType: .consume, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil)) { result in
                        switch result {
                        case .success(_):
                            toastType = .successConsumeOne
                            grocyVM.requestData(additionalObjects: [.stock], ignoreCached: true)
                        case let .failure(error):
                            grocyVM.postLog(message: "Consume 1 item failed. \(error)", type: .error)
                            toastType = .fail
                        }
                    }
                }
            RowInteractionButton(title: "str.stock.tbl.action.all", image: MySymbols.consume, backgroundColor: Color.grocyDelete, helpString: LocalizedStringKey("str.stock.tbl.action.consume.all \(stockElement.product.name)"))
                .onTapGesture {
                    showConsumeAll = true
                }
                .alert(isPresented:$showConsumeAll) {
                    Alert(
                        title: Text(LocalizedStringKey("str.stock.tbl.action.consume.all.confirm \("\(stockElement.amount) \(getQUString(amount: stockElement.amount))") \(stockElement.product.name)")),
                        primaryButton: .default(Text(LocalizedStringKey("str.confirm"))) {
                            selectedStockElement = stockElement
                            grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .consume, content: ProductConsume(amount: stockElement.amount, transactionType: .consume, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil)) { result in
                                switch result {
                                case .success(_):
                                    toastType = .successConsumeAll
                                    grocyVM.requestData(additionalObjects: [.stock], ignoreCached: true)
                                case let .failure(error):
                                    grocyVM.postLog(message: "Consume all items failed. \(error)", type: .error)
                                    toastType = .fail
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            RowInteractionButton(title: formatAmount(stockElement.product.quickConsumeAmount ?? 1.0), image: "shippingbox", backgroundColor: Color.grocyGreen, helpString: LocalizedStringKey("str.stock.tbl.action.consume.open \("\(stockElement.product.quickConsumeAmount ?? 1.0) \(getQUString(amount: stockElement.product.quickConsumeAmount ?? 1.0)) \(stockElement.product.name)")"))
                .onTapGesture {
                    selectedStockElement = stockElement
                    grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .open, content: ProductConsume(amount: stockElement.product.quickConsumeAmount ?? 1.0, transactionType: .productOpened, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil)) { result in
                        switch result {
                        case .success(_):
                            toastType = .successOpenOne
                            grocyVM.requestData(additionalObjects: [.stock], ignoreCached: true)
                        case let .failure(error):
                            grocyVM.postLog(message: "Open 1 item failed. \(error)", type: .error)
                            toastType = .fail
                        }
                    }
                }
            Menu(content: {
                StockTableMenuView(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, toastType: $toastType)
            }, label: {
                RowInteractionButton(image: "ellipsis", backgroundColor: .white, foregroundColor: Color.gray)
            })
            .frame(width: 35)
        }
    }
}
