//
//  ShoppingListRowActionsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 07.12.20.
//

import SwiftUI

struct ShoppingListRowActionsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var shoppingListItem: ShoppingListItem
    
    @State private var showEdit: Bool = false
    @State private var showPurchase: Bool = false
    
    var quantityUnit: MDQuantityUnit {
        grocyVM.mdQuantityUnits.first(where: {$0.id==shoppingListItem.quID}) ?? MDQuantityUnit(id: "", name: "Error QU", mdQuantityUnitDescription: nil, rowCreatedTimestamp: "", namePlural: "Error QU", pluralForms: nil, userfields: nil)
    }
    
    var productName: String {
        grocyVM.mdProducts.first(where: {$0.id == shoppingListItem.productID})?.name ?? "Productname error"
    }
    
    private func changeDoneStatus() {
        let doneStatus = shoppingListItem.done == "0" ? "1" : "0"
        grocyVM.putMDObjectWithID(object: .shopping_list, id: shoppingListItem.id, content: ShoppingListItem(id: shoppingListItem.id, productID: shoppingListItem.productID, note: shoppingListItem.note, amount: shoppingListItem.amount, rowCreatedTimestamp: shoppingListItem.rowCreatedTimestamp, shoppingListID: shoppingListItem.shoppingListID, done: doneStatus, quID: shoppingListItem.quID, userfields: shoppingListItem.userfields))
        grocyVM.getShoppingList()
    }
    
    private func deleteSHItem() {
        grocyVM.deleteMDObject(object: .shopping_list, id: shoppingListItem.id)
        grocyVM.getShoppingList()
    }
    
    var body: some View {
        HStack(spacing: 2){
            RowInteractionButton(image: shoppingListItem.done == "0" ? "checkmark" : "checkmark.circle", backgroundColor: Color.grocyGreen, helpString: LocalizedStringKey("str.shL.entry.done"))
                .onTapGesture {
                    changeDoneStatus()
                }
            RowInteractionButton(image: "square.and.pencil", backgroundColor: Color.grocyTurquoise, helpString: LocalizedStringKey("str.shL.entry.edit"))
                .onTapGesture {
                    showEdit.toggle()
                }
                .popover(isPresented: $showEdit, content: {
                    ShoppingListEntryFormView(isNewShoppingListEntry: false, shoppingListEntry: shoppingListItem)
                        .padding()
                })
            RowInteractionButton(image: "trash.fill", backgroundColor: Color.grocyDelete, helpString: LocalizedStringKey("str.shL.entry.delete"))
                .onTapGesture {
                    deleteSHItem()
                }
            #if os(macOS)
            RowInteractionButton(image: "shippingbox", backgroundColor: Color.blue, helpString: LocalizedStringKey("str.shL.entry.add \("\(shoppingListItem.amount) \(shoppingListItem.amount == "1" ? quantityUnit.name : quantityUnit.namePlural) \(productName)")"))
                .onTapGesture {
                    showPurchase.toggle()
                }
                .popover(isPresented: $showPurchase, content: {
                    PurchaseProductView(productToPurchaseID: shoppingListItem.productID, productToPurchaseAmount: Double(shoppingListItem.amount)!)
                        .padding()
                })
            #elseif os(iOS)
            RowInteractionButton(image: "shippingbox", backgroundColor: Color.blue, helpString: LocalizedStringKey("str.shL.entry.add \("\(shoppingListItem.amount) \(shoppingListItem.amount == "1" ? quantityUnit.name : quantityUnit.namePlural) \(productName)")"))
                .onTapGesture {
                    showPurchase.toggle()
                }
                .sheet(isPresented: $showPurchase, content: {
                        NavigationView{
                            PurchaseProductView(productToPurchaseID: shoppingListItem.productID, productToPurchaseAmount: Double(shoppingListItem.amount)!)
                        }
                })
            #endif
        }
    }
}

struct ShoppingListRowActionsView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListRowActionsView(shoppingListItem: ShoppingListItem(id: "1", productID: "1", note: "note", amount: "1", rowCreatedTimestamp: "", shoppingListID: "", done: "0", quID: "", userfields: nil))
    }
}
