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
    
    var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == shoppingListItem.productID})
    }
    
    var quantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: {$0.id == product?.quIDStock})
    }
    
    var amountString: String {
        if let quantityUnit = quantityUnit {
            return "\(shoppingListItem.amount.formattedAmount) \(shoppingListItem.amount == 1 ? quantityUnit.name : quantityUnit.namePlural)"
        } else {
            return "\(shoppingListItem.amount.formattedAmount)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading){
            Text(product?.name ?? "Name Error")
                .font(.headline)
                .strikethrough(shoppingListItem.done == 1)
            Text(LocalizedStringKey("str.shL.entry.info.amount \(amountString)"))
                .strikethrough(shoppingListItem.done == 1)
        }
        .foregroundColor(shoppingListItem.done == 1 ? Color.gray : Color.primary)
    }
}

struct ShoppingListEntriesView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.colorScheme) var colorScheme
    
    let shoppingListItem: ShoppingListItem
    @Binding var selectedShoppingListID: Int
    
    @Binding var toastType: ShoppingListToastType?
    @State private var shlItemToDelete: ShoppingListItem? = nil
    @State private var showEntryDeleteAlert: Bool = false
    
    var isBelowStock: Bool {
        if let product = grocyVM.mdProducts.first(where: {$0.id == shoppingListItem.productID}) {
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
    
    private func changeDoneStatus(shoppingListItem: ShoppingListItem) {
        grocyVM.putMDObjectWithID(object: .shopping_list, id: shoppingListItem.id, content: ShoppingListItem(id: shoppingListItem.id, productID: shoppingListItem.productID, note: shoppingListItem.note, amount: shoppingListItem.amount, shoppingListID: shoppingListItem.shoppingListID, done: shoppingListItem.done == 1 ? 0 : 1, quID: shoppingListItem.quID, rowCreatedTimestamp: shoppingListItem.rowCreatedTimestamp), completion: { result in
            switch result {
            case let .success(message):
                grocyVM.postLog(message: "Shopping list done status changed successful. \(message)", type: .info)
                grocyVM.requestData(objects: [.shopping_list])
            case let .failure(error):
                grocyVM.postLog(message: "Shopping list done status changed failed. \(error)", type: .error)
                toastType = .shLActionFail
            }
        })
    }
    
    private func deleteItem(itemToDelete: ShoppingListItem) {
        shlItemToDelete = itemToDelete
        showEntryDeleteAlert.toggle()
    }
    private func deleteSHLItem(toDelID: Int) {
        grocyVM.deleteMDObject(object: .shopping_list, id: toDelID, completion: { result in
            switch result {
            case let .success(message):
                grocyVM.postLog(message: "Shopping list item delete successful. \(message)", type: .info)
                grocyVM.requestData(objects: [.shopping_list])
            case let .failure(error):
                grocyVM.postLog(message: "Shopping list item delete failed. \(error)", type: .error)
                toastType = .shLActionFail
            }
        })
    }
    
    var body: some View {
        NavigationLink(destination: ShoppingListEntryFormView(isNewShoppingListEntry: false, shoppingListEntry: shoppingListItem, selectedShoppingListID: selectedShoppingListID)) {
            ShoppingListRowView(shoppingListItem: shoppingListItem, isBelowStock: isBelowStock)
        }
        .listRowBackground(backgroundColor)
        .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
            Button(role: .destructive,
                   action: { deleteItem(itemToDelete: shoppingListItem) },
                   label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
            )
        })
        .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
            Button(action: { changeDoneStatus(shoppingListItem: shoppingListItem) },
                   label: { Image(systemName: MySymbols.done) }
            )
                .tint(.green)
        })
        .alert(LocalizedStringKey("str.shL.entry.delete.confirm"), isPresented: $showEntryDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let deleteID = shlItemToDelete?.id {
                    deleteSHLItem(toDelID: deleteID)
                }
            }
        }, message: { Text(grocyVM.mdProducts.first(where: {$0.id == shlItemToDelete?.productID})?.name ?? "Name not found") })
    }
}

struct ShoppingListRowView_Previews: PreviewProvider {
    static var previews: some View {
        List{
            ShoppingListRowView(shoppingListItem: ShoppingListItem(id: 1, productID: 1, note: "note", amount: 2, shoppingListID: 1, done: 1, quID: 1, rowCreatedTimestamp: "ts"), isBelowStock: false)
            ShoppingListRowView(shoppingListItem: ShoppingListItem(id: 1, productID: 1, note: "note", amount: 2, shoppingListID: 1, done: 0, quID: 1, rowCreatedTimestamp: "ts"), isBelowStock: false)
        }
    }
}
