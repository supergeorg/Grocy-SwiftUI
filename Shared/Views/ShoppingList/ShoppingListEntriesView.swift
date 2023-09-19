//
//  ShoppingListRowView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct ShoppingListRowView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.colorScheme) var colorScheme
    
    var shoppingListItem: ShoppingListItem
    var isBelowStock: Bool
    @State var toastType: ToastType? = nil
    @State var infoString: String? = nil
    
    var product: MDProduct? {
        grocyVM.mdProducts.first(where: { $0.id == shoppingListItem.productID })
    }
    
    var quantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDPurchase })
    }
    
    private var quantityUnitConversions: [MDQuantityUnitConversion] {
        grocyVM.mdQuantityUnitConversions.filter { $0.toQuID == shoppingListItem.quID }
    }
    
    private var factoredAmount: Double {
        shoppingListItem.amount * (quantityUnitConversions.first(where: { $0.fromQuID == shoppingListItem.quID })?.factor ?? 1)
    }
    
    var amountString: String {
        if let quantityUnit = quantityUnit {
            return "\(factoredAmount.formattedAmount) \(factoredAmount == 1 ? quantityUnit.name : quantityUnit.namePlural ?? quantityUnit.name)"
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
                Text(LocalizedStringKey("str.shL.entry.info.amount \(amountString)"))
                    .strikethrough(shoppingListItem.done == 1)
            }
            .foregroundColor(shoppingListItem.done == 1 ? Color.gray : Color.primary)
        }
    }
}

struct ShoppingListEntriesView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.colorScheme) var colorScheme
    
    let shoppingListItem: ShoppingListItem
    @Binding var selectedShoppingListID: Int
    
    @State var toastType: ToastType? = nil
    @State var infoString: String? = nil
    @State private var shlItemToDelete: ShoppingListItem? = nil
    @State private var showEntryDeleteAlert: Bool = false
    @State private var showPurchase: Bool = false
    @State private var showAutoPurchase: Bool = false
    
    var isBelowStock: Bool {
        if let product = grocyVM.mdProducts.first(where: { $0.id == shoppingListItem.productID }) {
            if product.minStockAmount > shoppingListItem.amount {
                return true
            }
        }
        return false
    }
    
    var backgroundColor: Color {
        if isBelowStock {
            return colorScheme == .light ? Color.grocyBlueLight : Color.grocyBlueDark
        } else {
            return colorScheme == .light ? Color.white : Color.grocyGrayDark
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
            grocyVM.postLog("Done status changed successfully.", type: .info)
            await grocyVM.requestData(objects: [.shopping_list])
        } catch {
            grocyVM.postLog("Shopping list done status change failed. \(error)", type: .error)
            toastType = .shLActionFail
        }
    }
    
    private func deleteItem(itemToDelete: ShoppingListItem) {
        shlItemToDelete = itemToDelete
        showEntryDeleteAlert.toggle()
    }
    
    private func deleteSHLItem(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .shopping_list, id: toDelID)
            grocyVM.postLog("Deleting shopping list item was successful.", type: .info)
            await grocyVM.requestData(objects: [.shopping_list])
        } catch {
            grocyVM.postLog("Deleting shopping list item failed. \(error)", type: .error)
            toastType = .shLActionFail
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
                   label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) })
        })
        .swipeActions(edge: .leading, allowsFullSwipe: shoppingListItem.done != 1, content: {
            Group {
                Button(action: {
                    Task {
                        await changeDoneStatus(shoppingListItem: shoppingListItem)
                    }
                    if shoppingListItem.done != 1,
                       grocyVM.userSettings?.shoppingListToStockWorkflowAutoSubmitWhenPrefilled == true
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
        .alert(LocalizedStringKey("str.shL.entry.delete.confirm"), isPresented: $showEntryDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) {}
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let deleteID = shlItemToDelete?.id {
                    Task {
                        await deleteSHLItem(toDelID: deleteID)
                    }
                }
            }
        }, message: { Text(grocyVM.mdProducts.first(where: { $0.id == shlItemToDelete?.productID })?.name ?? "Name not found") })
#else
        ShoppingListRowView(shoppingListItem: shoppingListItem, isBelowStock: isBelowStock)
            .listRowBackground(backgroundColor)
            .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                Button(role: .destructive,
                       action: { deleteItem(itemToDelete: shoppingListItem) },
                       label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) })
            })
            .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
                Button(action: { Task { await changeDoneStatus(shoppingListItem: shoppingListItem) } },
                       label: { Image(systemName: MySymbols.done) })
                .tint(.green)
            })
            .alert(LocalizedStringKey("str.shL.entry.delete.confirm"), isPresented: $showEntryDeleteAlert, actions: {
                Button(LocalizedStringKey("str.cancel"), role: .cancel) {}
                Button(LocalizedStringKey("str.delete"), role: .destructive) {
                    if let deleteID = shlItemToDelete?.id {
                        Task {
                            await deleteSHLItem(toDelID: deleteID)
                        }
                    }
                }
            }, message: { Text(grocyVM.mdProducts.first(where: { $0.id == shlItemToDelete?.productID })?.name ?? "Name not found") })
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
