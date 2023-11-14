//
//  StockTableRowActionsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 07.12.20.
//

import SwiftUI
import SwiftData

struct StockTableRowActionsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    
    var stockElement: StockElement
    
    @Binding var selectedStockElement: StockElement?
    
    var shownActions: [ShownAction] = []
    
    enum ShownAction: Identifiable {
        case consumeQA, consumeAll, openQA
        
        var id: Int {
            self.hashValue
        }
    }
    
    var quantityUnit: MDQuantityUnit? {
        mdQuantityUnits.first(where: {$0.id == stockElement.product.quIDStock})
    }
    
    private func consumeQuickConsumeAmount() async {
        selectedStockElement = stockElement
        do {
            try await grocyVM.postStockObject(id: stockElement.productID, stockModePost: .consume, content: ProductConsume(amount: stockElement.product.quickConsumeAmount ?? 1.0, transactionType: .consume, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock])
        } catch {
            await grocyVM.postLog("Consume \(stockElement.product.quickConsumeAmount ?? 1.0) item failed. \(error)", type: .error)
        }
    }
    
    private func consumeAll() async {
        selectedStockElement = stockElement
        do {
            try await grocyVM.postStockObject(id: stockElement.productID, stockModePost: .consume, content: ProductConsume(amount: stockElement.amount, transactionType: .consume, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock])
        } catch {
            await grocyVM.postLog("Consume all items failed. \(error)", type: .error)
        }
    }
    
    private func openQuickConsumeAmount() async {
        selectedStockElement = stockElement
        do {
            try await grocyVM.postStockObject(id: stockElement.productID, stockModePost: .open, content: ProductConsume(amount: stockElement.product.quickConsumeAmount ?? 1.0, transactionType: .productOpened, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock])
        } catch {
            await grocyVM.postLog("Open \(stockElement.product.quickConsumeAmount ?? 1.0) item failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        if shownActions.contains(.consumeQA) {
            Button(action: { Task { await consumeQuickConsumeAmount() } }, label: {
                Label(stockElement.product.quickConsumeAmount?.formattedAmount ?? "1", systemImage: MySymbols.consume)
            })
            .tint(Color(.GrocyColors.grocyGreen))
            .help("Consume \(stockElement.product.quickConsumeAmount?.formattedAmount ?? "1") \(quantityUnit?.getName(amount: stockElement.product.quickConsumeAmount ?? 1.0) ?? "") \(stockElement.product.name)")
        }
        if shownActions.contains(.consumeAll) {
            Button(action: { Task { await consumeAll() } }, label: {
                Label("All", systemImage: MySymbols.consume)
            })
            .tint(Color(.GrocyColors.grocyDelete))
            .help("Consume all \(stockElement.product.name) which are currently in stock")
        }
        if shownActions.contains(.openQA) {
            Button(action: { Task { await openQuickConsumeAmount() } }, label: {
                Label(stockElement.product.quickConsumeAmount?.formattedAmount ?? "1", systemImage: MySymbols.open)
            })
            .tint(Color(.GrocyColors.grocyBlue))
            .help("Mark \(stockElement.product.quickConsumeAmount?.formattedAmount ?? "1") \(quantityUnit?.getName(amount: stockElement.product.quickConsumeAmount ?? 1.0) ?? "") \(stockElement.product.name) as open")
        }
    }
}
