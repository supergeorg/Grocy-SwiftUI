//
//  StockTableRowActionsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 07.12.20.
//

import SwiftUI

struct StockTableRowActionsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
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
    
    
    
    var quantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: {$0.id == stockElement.product.quIDStock})
    }
    private func getQUString(amount: Double) -> String {
        return amount == 1.0 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? quantityUnit?.name ?? ""
    }
    
    private func consumeQuickConsumeAmount() async {
        selectedStockElement = stockElement
        do {
            try await grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .consume, content: ProductConsume(amount: stockElement.product.quickConsumeAmount ?? 1.0, transactionType: .consume, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock])
        } catch {
            grocyVM.postLog("Consume \(stockElement.product.quickConsumeAmount ?? 1.0) item failed. \(error)", type: .error)
        }
    }
    
    private func consumeAll() async {
        selectedStockElement = stockElement
        do {
            try await grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .consume, content: ProductConsume(amount: stockElement.amount, transactionType: .consume, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock])
        } catch {
            grocyVM.postLog("Consume all items failed. \(error)", type: .error)
        }
    }
    
    private func openQuickConsumeAmount() async {
        selectedStockElement = stockElement
        do {
            try await grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .open, content: ProductConsume(amount: stockElement.product.quickConsumeAmount ?? 1.0, transactionType: .productOpened, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock])
        } catch {
            grocyVM.postLog("Open \(stockElement.product.quickConsumeAmount ?? 1.0) item failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        if shownActions.contains(.consumeQA) {
            Button(action: { Task { await consumeQuickConsumeAmount() } }, label: {
                Label(stockElement.product.quickConsumeAmount?.formattedAmount ?? "1", systemImage: MySymbols.consume)
            })
            .tint(Color.grocyGreen)
            .help(LocalizedStringKey("str.stock.tbl.action.consume \("\(stockElement.product.quickConsumeAmount?.formattedAmount ?? "1") \(getQUString(amount: stockElement.product.quickConsumeAmount ?? 1.0)) \(stockElement.product.name)")"))
        }
        if shownActions.contains(.consumeAll) {
            Button(action: { Task { await consumeAll() } }, label: {
                Label(LocalizedStringKey("str.stock.tbl.action.all"), systemImage: MySymbols.consume)
            })
            .tint(Color.grocyDelete)
            .help(LocalizedStringKey("str.stock.tbl.action.consume.all \(stockElement.product.name)"))
        }
        if shownActions.contains(.openQA) {
            Button(action: { Task { await openQuickConsumeAmount() } }, label: {
                Label(stockElement.product.quickConsumeAmount?.formattedAmount ?? "1", systemImage: MySymbols.open)
            })
            .tint(Color.grocyBlue)
            .help(LocalizedStringKey("str.stock.tbl.action.consume.open \("\(stockElement.product.quickConsumeAmount?.formattedAmount ?? "1") \(getQUString(amount: stockElement.product.quickConsumeAmount ?? 1.0)) \(stockElement.product.name)")"))
        }
    }
}
