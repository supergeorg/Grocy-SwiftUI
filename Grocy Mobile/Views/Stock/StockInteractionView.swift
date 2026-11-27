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

/// The toolbar buttons of the stock overview that its interaction sheets zoom out of (iOS 26 zoom transition):
/// the stock journal button, and the menu of the four stock actions. Each button is marked with
/// `.matchedTransitionSource(id:in:)` for its ID and this namespace.
struct StockInteractionZoom {
    static let journalSourceID = "stockJournal"
    static let actionsSourceID = "stockActions"

    var namespace: Namespace.ID

    /// The button the interaction's sheet zooms out of. The interactions of a single product open from its row,
    /// so they slide up as usual.
    func sourceID(for interaction: StockInteraction) -> String? {
        switch interaction {
        case .stockJournal: Self.journalSourceID
        case .purchaseProduct, .consumeProduct, .transferProduct, .inventoryProduct: Self.actionsSourceID
        default: nil
        }
    }
}

extension View {
    /// Lets the stock rows below (`StockTableRow`, `StockTableMenuEntriesView`) present their stock interactions:
    /// provides the router to them and shows the interaction it presents in a sheet.
    /// With `zoom`, the sheets of the toolbar's interactions zoom out of their buttons.
    func stockInteractionSheet(router: StockInteractionNavigationRouter, zoom: StockInteractionZoom? = nil) -> some View {
        modifier(StockInteractionSheet(router: router, zoom: zoom))
    }
}

private struct StockInteractionSheet: ViewModifier {
    @Bindable var router: StockInteractionNavigationRouter
    var zoom: StockInteractionZoom?

    func body(content: Content) -> some View {
        content
            .environment(router)
            .sheet(item: $router.presentedInteraction) { interaction in
                let sheet = NavigationStack {
                    StockInteractionView(interaction: interaction)
                }
                .environment(router)
                #if os(macOS)
                    // A Mac sheet takes its content's size; the lists (journal, entries, recipes) have none of their own.
                    .frame(minWidth: Sizes.macOSSheetMinWidth, minHeight: Sizes.macOSSheetMinHeight)
                #endif
                #if os(iOS)
                    if let zoom, let sourceID = zoom.sourceID(for: interaction) {
                        sheet.navigationTransition(.zoom(sourceID: sourceID, in: zoom.namespace))
                    } else {
                        sheet
                    }
                #else
                    sheet
                #endif
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
