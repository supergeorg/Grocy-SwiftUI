//
//  StockInteractionView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import SwiftUI

/// The screen of a stock interaction, shown in a sheet by the stock overview and the due agenda.
struct StockInteractionView: View {
    var interaction: StockInteraction

    var body: some View {
        switch interaction {
        case .stockJournal: StockJournalView(isPopup: true)
        case .inventoryProduct: InventoryProductView(isPopup: true)
        case .transferProduct: TransferProductView(isPopup: true)
        case .consumeProduct: ConsumeProductView(isPopup: true)
        case .purchaseProduct: PurchaseProductView(isPopup: true)
        case .productPurchase(let stockElement): PurchaseProductView(stockElement: stockElement, isPopup: true)
        case .productConsume(let stockElement): ConsumeProductView(stockElement: stockElement, isPopup: true)
        case .productTransfer(let stockElement): TransferProductView(stockElement: stockElement, isPopup: true)
        case .productInventory(let stockElement): InventoryProductView(stockElement: stockElement, isPopup: true)
        case .productOverview(let stockElement): StockProductInfoView(stockElement: stockElement, isPopup: true)
        case .productJournal(let stockElement): StockJournalView(stockElement: stockElement, isPopup: true)
        // These screens are usually pushed and have no button of their own to close the sheet.
        case .productEntries(let stockElement): StockEntriesView(stockElement: stockElement).modifier(SheetCloseButton())
        case .productRecipes(let stockElement): StockProductRecipesView(stockElement: stockElement).modifier(SheetCloseButton())
        case .editProduct(let stockElement): MDProductFormView(existingProduct: stockElement.product).modifier(SheetCloseButton())
        case .addToShL(let stockElement): ShoppingListEntryFormView(productIDToSelect: stockElement.productID, isPopup: true)
        }
    }
}

extension View {
    /// Lets the stock rows below (`StockTableRow`, `StockTableMenuEntriesView`) present their stock interactions:
    /// provides the router to them and shows the interaction it presents in a sheet.
    func stockInteractionSheet(router: StockInteractionNavigationRouter) -> some View {
        modifier(StockInteractionSheet(router: router))
    }
}

private struct StockInteractionSheet: ViewModifier {
    @Bindable var router: StockInteractionNavigationRouter

    func body(content: Content) -> some View {
        content
            .environment(router)
            .sheet(item: $router.presentedInteraction) { interaction in
                NavigationStack {
                    StockInteractionView(interaction: interaction)
                }
                .environment(router)
            }
    }
}

private struct SheetCloseButton: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .close) {
                    dismiss()
                }
            }
        }
    }
}
