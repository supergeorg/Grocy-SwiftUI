//
//  ShoppingListRowView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI
import SwiftData

struct ShoppingListRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups
    @Query(sort: \MDStore.id, order: .forward) var mdStores: MDStores
    
    @Environment(\.colorScheme) var colorScheme
    
    var shoppingListItem: ShoppingListItem
    var isBelowStock: Bool
    
    var product: MDProduct? {
        mdProducts.first(where: { $0.id == shoppingListItem.productID })
    }
    
    var quantityUnit: MDQuantityUnit? {
        mdQuantityUnits.first(where: { $0.id == product?.quIDPurchase })
    }
    
    private var quantityUnitConversions: [MDQuantityUnitConversion] {
        mdQuantityUnitConversions.filter { $0.toQuID == shoppingListItem.quID }
    }
    
    private var factoredAmount: Double {
        shoppingListItem.amount * (quantityUnitConversions.first(where: { $0.fromQuID == shoppingListItem.quID })?.factor ?? 1)
    }
    
    var amountString: String {
        if let quantityUnit = quantityUnit {
            return "\(factoredAmount.formattedAmount) \(quantityUnit.getName(amount: factoredAmount))"
        } else {
            return "\(factoredAmount.formattedAmount)"
        }
    }
    
    var body: some View {
        HStack {
#if os(macOS)
            ShoppingListRowActionsView(shoppingListItem: shoppingListItem)
#endif
            VStack(alignment: .leading) {
                Text(product?.name ?? shoppingListItem.note ?? "?")
                    .font(.headline)
                    .strikethrough(shoppingListItem.done == 1)
                Text("Amount: \(amountString)")
                    .strikethrough(shoppingListItem.done == 1)
            }
            .foregroundStyle(shoppingListItem.done == 1 ? Color.gray : Color.primary)
        }
    }
}

struct ShoppingListEntriesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    let shoppingListItem: ShoppingListItem
    @Binding var selectedShoppingListID: Int
    
    @State private var shlItemToDelete: ShoppingListItem? = nil
    @State private var showEntryDeleteAlert: Bool = false
    @State private var showPurchase: Bool = false
    @State private var showAutoPurchase: Bool = false
    
    var isBelowStock: Bool {
        if let product = mdProducts.first(where: { $0.id == shoppingListItem.productID }) {
            if product.minStockAmount > shoppingListItem.amount {
                return true
            }
        }
        return false
    }
    
    var backgroundColor: Color {
        if isBelowStock {
            return Color(.GrocyColors.grocyBlueBackground)
        } else {
            return Color(.GrocyColors.grocyGrayBackground)
        }
    }
    
    private func changeDoneStatus(shoppingListItem: ShoppingListItem) async {
        let doneChangedShoppingListItem = ShoppingListItem(
            id: shoppingListItem.id,
            productID: shoppingListItem.productID,
            note: shoppingListItem.note,
            amount: shoppingListItem.amount,
            shoppingListID: shoppingListItem.shoppingListID,
            done: shoppingListItem.done == 1 ? 0 : 1,
            quID: shoppingListItem.quID,
            rowCreatedTimestamp: shoppingListItem.rowCreatedTimestamp
        )
        do {
            try await grocyVM.putMDObjectWithID(object: .shopping_list, id: shoppingListItem.id, content: doneChangedShoppingListItem)
            await grocyVM.postLog("Done status changed successfully.", type: .info)
            await grocyVM.requestData(objects: [.shopping_list])
        } catch {
            await grocyVM.postLog("Shopping list done status change failed. \(error)", type: .error)
        }
    }
    
    private func deleteItem(itemToDelete: ShoppingListItem) {
        shlItemToDelete = itemToDelete
        showEntryDeleteAlert.toggle()
    }
    
    private func deleteSHLItem(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .shopping_list, id: toDelID)
            await grocyVM.postLog("Deleting shopping list item was successful.", type: .info)
            await grocyVM.requestData(objects: [.shopping_list])
        } catch {
            await grocyVM.postLog("Deleting shopping list item failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
#if os(iOS)
        NavigationLink(destination: ShoppingListEntryFormView(isNewShoppingListEntry: false, shoppingListEntry: shoppingListItem, selectedShoppingListID: selectedShoppingListID)) {
            ShoppingListRowView(shoppingListItem: shoppingListItem, isBelowStock: isBelowStock)
        }
        .listRowBackground(backgroundColor)
        .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
            Button(role: .destructive,
                   action: { deleteItem(itemToDelete: shoppingListItem) },
                   label: { Label("Delete", systemImage: MySymbols.delete) })
        })
        .swipeActions(edge: .leading, allowsFullSwipe: shoppingListItem.done != 1, content: {
            Group {
                Button(action: {
                    Task {
                        await changeDoneStatus(shoppingListItem: shoppingListItem)
                    }
                    if shoppingListItem.done != 1,
                       userSettings?.shoppingListToStockWorkflowAutoSubmitWhenPrefilled == true
                    {
                        showAutoPurchase.toggle()
                    }
                },
                       label: { Image(systemName: MySymbols.done) })
                .tint(.green)
                Button(action: {
                    showPurchase.toggle()
                }, label: { Image(systemName: "shippingbox") })
                .tint(.blue)
            }
        })
        .sheet(isPresented: $showPurchase, content: {
            NavigationView {
                PurchaseProductView(directProductToPurchaseID: shoppingListItem.productID, productToPurchaseAmount: shoppingListItem.amount)
            }
        })
        .sheet(isPresented: $showAutoPurchase, content: {
            NavigationView {
                PurchaseProductView(directProductToPurchaseID: shoppingListItem.productID, productToPurchaseAmount: shoppingListItem.amount, autoPurchase: true)
            }
        })
        .confirmationDialog("Do you really want to delete this item?", isPresented: $showEntryDeleteAlert, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let deleteID = shlItemToDelete?.id {
                    Task {
                        await deleteSHLItem(toDelID: deleteID)
                    }
                }
            }
        }, message: { Text(mdProducts.first(where: { $0.id == shlItemToDelete?.productID })?.name ?? "Name not found") })
#else
        ShoppingListRowView(shoppingListItem: shoppingListItem, isBelowStock: isBelowStock)
            .listRowBackground(backgroundColor)
            .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                Button(role: .destructive,
                       action: { deleteItem(itemToDelete: shoppingListItem) },
                       label: { Label("Delete", systemImage: MySymbols.delete) })
            })
            .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
                Button(action: { Task { await changeDoneStatus(shoppingListItem: shoppingListItem) } },
                       label: { Image(systemName: MySymbols.done) })
                .tint(.green)
            })
            .confirmationDialog("Do you really want to delete this item?", isPresented: $showEntryDeleteAlert, actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let deleteID = shlItemToDelete?.id {
                        Task {
                            await deleteSHLItem(toDelID: deleteID)
                        }
                    }
                }
            }, message: { Text(mdProducts.first(where: { $0.id == shlItemToDelete?.productID })?.name ?? "Name not found") })
#endif
    }
}

//struct ShoppingListRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        List {
//            ShoppingListRowView(shoppingListItem: ShoppingListItem(id: 1, productID: 1, note: "note", amount: 2, shoppingListID: 1, done: 1, quID: 1, rowCreatedTimestamp: "ts"), isBelowStock: false, infoString: Binding.constant(nil))
//            ShoppingListRowView(shoppingListItem: ShoppingListItem(id: 1, productID: 1, note: "note", amount: 2, shoppingListID: 1, done: 0, quID: 1, rowCreatedTimestamp: "ts"), isBelowStock: false, infoString: Binding.constant(nil))
//        }
//    }
//}
