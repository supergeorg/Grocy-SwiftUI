//
//  ShoppingListPurchaseAllView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import SwiftData
import SwiftUI

/// "Add all list items to stock": the purchase form for each item in turn, like Grocy's shopping list.
///
/// A purchased item is marked as done; the person can skip an item or close the sheet to stop.
struct ShoppingListPurchaseAllView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \MDProduct.id, order: .forward) private var mdProducts: MDProducts
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) private var mdQuantityUnitConversions: MDQuantityUnitConversions

    var items: [ShoppingListItem]

    @State private var index: Int = 0

    private var currentItem: ShoppingListItem? {
        items.indices.contains(index) ? items[index] : nil
    }

    private func markDone(_ item: ShoppingListItem) async {
        item.done = true
        do {
            try item.modelContext?.save()
            try await grocyVM.putMDObjectWithID(object: .shopping_list, id: item.id, content: item)
            GrocyLogger.info("Marking shopping list item \(item.id) as done was successful.")
        } catch {
            GrocyLogger.error("Marking shopping list item \(item.id) as done failed. \(error)")
        }
    }

    private func next() {
        if index + 1 < items.count {
            index += 1
        } else {
            Task {
                await grocyVM.requestData(objects: [.shopping_list])
            }
            dismiss()
        }
    }

    var body: some View {
        if let item = currentItem {
            PurchaseProductView(
                directProductToPurchaseID: item.productID,
                // The purchase form starts in the purchase unit, and Grocy stores the item's amount in the stock unit (#114).
                productToPurchaseAmount: item.purchaseAmount(
                    product: mdProducts.first(where: { $0.id == item.productID }),
                    conversions: mdQuantityUnitConversions
                ),
                isPopup: true,
                onPurchased: {
                    Task {
                        await markDone(item)
                        next()
                    }
                }
            )
            // A fresh form for every item.
            .id(item.id)
            .navigationSubtitle(Text("Item \(index + 1) of \(items.count)"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Skip", systemImage: MySymbols.forward) {
                        next()
                    }
                    .help("Skip this item")
                }
            }
        } else {
            ContentUnavailableView("No items to add to stock", systemImage: MySymbols.purchase)
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        ShoppingListPurchaseAllView(items: [ShoppingListItem(id: 1, productID: 1, amount: 2)])
    }
}
