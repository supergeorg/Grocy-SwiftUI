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

    var shownActions: [ShownAction] = []
    
    enum ShownAction: Identifiable {
        case consumeQA, consumeAll, openQA
        
        var id: Int {
            self.hashValue
        }
    }
    
    @Binding var toastType: ToastType?
    
    var quantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: {$0.id == stockElement.product.quIDStock})
    }
    private func getQUString(amount: Double) -> String {
        return amount == 1.0 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? quantityUnit?.name ?? ""
    }
    
    private func consumeQuickConsumeAmount() {
        selectedStockElement = stockElement
        grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .consume, content: ProductConsume(amount: stockElement.product.quickConsumeAmount ?? 1.0, transactionType: .consume, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil)) { result in
            switch result {
            case .success(_):
                toastType = .successConsumeOne
                grocyVM.requestData(additionalObjects: [.stock])
            case let .failure(error):
                grocyVM.postLog("Consume \(stockElement.product.quickConsumeAmount ?? 1.0) item failed. \(error)", type: .error)
                toastType = .shLActionFail
            }
        }
    }
    
    private func consumeAll() {
        selectedStockElement = stockElement
        grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .consume, content: ProductConsume(amount: stockElement.amount, transactionType: .consume, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil)) { result in
            switch result {
            case .success(_):
                toastType = .successConsumeAll
                grocyVM.requestData(additionalObjects: [.stock])
            case let .failure(error):
                grocyVM.postLog("Consume all items failed. \(error)", type: .error)
                toastType = .shLActionFail
            }
        }
    }
    
    private func openQuickConsumeAmount() {
        selectedStockElement = stockElement
        grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .open, content: ProductConsume(amount: stockElement.product.quickConsumeAmount ?? 1.0, transactionType: .productOpened, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil)) { result in
            switch result {
            case .success(_):
                toastType = .successOpenOne
                grocyVM.requestData(additionalObjects: [.stock])
            case let .failure(error):
                grocyVM.postLog("Open \(stockElement.product.quickConsumeAmount ?? 1.0) item failed. \(error)", type: .error)
                toastType = .shLActionFail
            }
        }
    }
    
    var body: some View {
        if shownActions.contains(.consumeQA) {
            Button(action: consumeQuickConsumeAmount, label: {
                Label(stockElement.product.quickConsumeAmount?.formattedAmount ?? "1", systemImage: MySymbols.consume)
            })
                .tint(Color.grocyGreen)
                .help(LocalizedStringKey("str.stock.tbl.action.consume \("\(stockElement.product.quickConsumeAmount?.formattedAmount ?? "1") \(getQUString(amount: stockElement.product.quickConsumeAmount ?? 1.0)) \(stockElement.product.name)")"))
        }
        if shownActions.contains(.consumeAll) {
            Button(action: consumeAll, label: {
                Label(LocalizedStringKey("str.stock.tbl.action.all"), systemImage: MySymbols.consume)
            })
                .tint(Color.grocyDelete)
                .help(LocalizedStringKey("str.stock.tbl.action.consume.all \(stockElement.product.name)"))
        }
        if shownActions.contains(.openQA) {
            Button(action: openQuickConsumeAmount, label: {
                Label(stockElement.product.quickConsumeAmount?.formattedAmount ?? "1", systemImage: MySymbols.open)
            })
                .tint(Color.grocyBlue)
                .help(LocalizedStringKey("str.stock.tbl.action.consume.open \("\(stockElement.product.quickConsumeAmount?.formattedAmount ?? "1") \(getQUString(amount: stockElement.product.quickConsumeAmount ?? 1.0)) \(stockElement.product.name)")"))
        }
    }
}
