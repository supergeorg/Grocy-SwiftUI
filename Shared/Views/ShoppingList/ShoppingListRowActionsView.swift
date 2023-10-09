//
//  ShoppingListRowActionsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 07.12.20.
//

import SwiftUI

struct ShoppingListRowActionsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    var shoppingListItem: ShoppingListItem
    
    @State private var showEdit: Bool = false
    @State private var showPurchase: Bool = false
    @State private var showAutoPurchase: Bool = false
    @State private var showEntryDeleteAlert: Bool = false
    
    var quantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: { $0.id == shoppingListItem.quID })
    }
    
    private func getQUString(amount: Double) -> String {
        amount == 1.0 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? ""
    }
    
    var productName: String {
        grocyVM.mdProducts.first(where: { $0.id == shoppingListItem.productID })?.name ?? "Productname error"
    }
    
    private func changeDoneStatus() async {
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
            try await grocyVM.putMDObjectWithID(
                object: .shopping_list,
                id: shoppingListItem.id,
                content: doneChangedShoppingListItem
            )
            grocyVM.postLog("Done status changed successfully.", type: .info)
            await grocyVM.requestData(objects: [.shopping_list])
        } catch {
            grocyVM.postLog("Done status change failed. \(error)", type: .error)
        }
    }
    
    private func deleteItem() {
        showEntryDeleteAlert.toggle()
    }
    
    private func deleteSHLItem() async {
        do {
            try await grocyVM.deleteMDObject(object: .shopping_list, id: shoppingListItem.id)
            grocyVM.postLog("Deleting shopping list item was successful.", type: .info)
            await grocyVM.requestData(objects: [.shopping_list])
        } catch {
            grocyVM.postLog("Deleting shopping list item failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            RowInteractionButton(image: "checkmark", backgroundColor: Color(.GrocyColors.grocyGreen), helpString: LocalizedStringKey("str.shL.entry.done"))
                .onTapGesture {
                    Task {
                        await changeDoneStatus()
                    }
                    if shoppingListItem.done != 1, grocyVM.userSettings?.shoppingListToStockWorkflowAutoSubmitWhenPrefilled == true {
                        showAutoPurchase.toggle()
                    }
                }
            RowInteractionButton(image: "square.and.pencil", backgroundColor: Color(.GrocyColors.grocyTurquoise), helpString: LocalizedStringKey("str.shL.entry.edit"))
                .onTapGesture {
                    showEdit.toggle()
                }
#if os(macOS)
                .popover(isPresented: $showEdit, content: {
                    ScrollView {
                        ShoppingListEntryFormView(isNewShoppingListEntry: false, shoppingListEntry: shoppingListItem)
                            .frame(width: 500, height: 400)
                            .padding()
                    }
                })
#else
                .sheet(isPresented: $showEdit, content: {
                    ShoppingListEntryFormView(isNewShoppingListEntry: false, shoppingListEntry: shoppingListItem)
                })
#endif
            RowInteractionButton(image: "trash.fill", backgroundColor: Color(.GrocyColors.grocyDelete), helpString: LocalizedStringKey("str.shL.entry.delete"))
                .onTapGesture {
                    deleteItem()
                }
                .alert(LocalizedStringKey("str.shL.entry.delete.confirm"), isPresented: $showEntryDeleteAlert, actions: {
                    Button("Cancel", role: .cancel) {}
                    Button(LocalizedStringKey("str.delete"), role: .destructive) {
                        Task {
                            await deleteSHLItem()
                        }
                    }
                }, message: { Text(grocyVM.mdProducts.first(where: { $0.id == shoppingListItem.productID })?.name ?? "Name not found") })
            
            RowInteractionButton(image: "shippingbox", backgroundColor: Color.blue, helpString: LocalizedStringKey("str.shL.entry.add \("\(shoppingListItem.amount.formattedAmount) \(getQUString(amount: shoppingListItem.amount)) \(productName)")"))
                .onTapGesture {
                    showPurchase.toggle()
                }
#if os(macOS)
                .popover(isPresented: $showPurchase, content: {
                    PurchaseProductView(directProductToPurchaseID: shoppingListItem.productID, productToPurchaseAmount: shoppingListItem.amount)
                        .padding()
                })
                .popover(isPresented: $showAutoPurchase, content: {
                    PurchaseProductView(directProductToPurchaseID: shoppingListItem.productID, productToPurchaseAmount: shoppingListItem.amount, autoPurchase: true)
                        .padding()
                })
#elseif os(iOS)
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
#endif
        }
    }
}

struct ShoppingListRowActionsView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListRowActionsView(shoppingListItem: ShoppingListItem(id: 1, productID: 1, note: "note", amount: 1, shoppingListID: 1, done: 0, quID: 1, rowCreatedTimestamp: ""))
    }
}
