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
    
    @Binding var toastType: ShoppingListToastType?
    
    var quantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: {$0.id == shoppingListItem.quID})
    }
    
    private func getQUString(amount: Double) -> String {
        return amount == 1.0 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? ""
    }
    
    var productName: String {
        grocyVM.mdProducts.first(where: {$0.id == shoppingListItem.productID})?.name ?? "Productname error"
    }
    
    private func changeDoneStatus() {
        grocyVM.putMDObjectWithID(object: .shopping_list, id: shoppingListItem.id, content: ShoppingListItem(id: shoppingListItem.id, productID: shoppingListItem.productID, note: shoppingListItem.note, amount: shoppingListItem.amount, shoppingListID: shoppingListItem.shoppingListID, done: shoppingListItem.done == 1 ? 0 : 1, quID: shoppingListItem.quID, rowCreatedTimestamp: shoppingListItem.rowCreatedTimestamp), completion: { result in
            switch result {
            case let .success(message):
                print(message)
                grocyVM.requestData(objects: [.shopping_list])
            case let .failure(error):
                print("\(error)")
                toastType = .shLActionFail
            }
        })
        
    }
    
    private func deleteSHItem() {
        grocyVM.deleteMDObject(object: .shopping_list, id: shoppingListItem.id, completion: { result in
            switch result {
            case let .success(message):
                print(message)
                grocyVM.requestData(objects: [.shopping_list])
            case let .failure(error):
                print("\(error)")
                toastType = .shLActionFail
            }
        })
    }
    
    var body: some View {
        HStack(spacing: 2){
            RowInteractionButton(image: "checkmark", backgroundColor: Color.grocyGreen, helpString: LocalizedStringKey("str.shL.entry.done"))
                .onTapGesture {
                    changeDoneStatus()
                }
            RowInteractionButton(image: "square.and.pencil", backgroundColor: Color.grocyTurquoise, helpString: LocalizedStringKey("str.shL.entry.edit"))
                .onTapGesture {
                    showEdit.toggle()
                }
#if os(macOS)
                .popover(isPresented: $showEdit, content: {
                    ScrollView{
                        ShoppingListEntryFormView(isNewShoppingListEntry: false, shoppingListEntry: shoppingListItem)
                            .frame(width: 500, height: 400)
                    }
                })
#else
                .sheet(isPresented: $showEdit, content: {
                    ShoppingListEntryFormView(isNewShoppingListEntry: false, shoppingListEntry: shoppingListItem)
                })
#endif
            RowInteractionButton(image: "trash.fill", backgroundColor: Color.grocyDelete, helpString: LocalizedStringKey("str.shL.entry.delete"))
                .onTapGesture {
                    deleteSHItem()
                }
            
            RowInteractionButton(image: "shippingbox", backgroundColor: Color.blue, helpString: LocalizedStringKey("str.shL.entry.add \("\(shoppingListItem.amount) \(getQUString(amount: shoppingListItem.amount)) \(productName)")"))
                .onTapGesture {
                    showPurchase.toggle()
                }
#if os(macOS)
                .popover(isPresented: $showPurchase, content: {
                    PurchaseProductView(directProductToPurchaseID: shoppingListItem.productID, productToPurchaseAmount: shoppingListItem.amount)
                        .padding()
                })
#elseif os(iOS)
                .sheet(isPresented: $showPurchase, content: {
                    NavigationView{
                        PurchaseProductView(directProductToPurchaseID: shoppingListItem.productID, productToPurchaseAmount: shoppingListItem.amount)
                    }
                })
#endif
        }
    }
}

struct ShoppingListRowActionsView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListRowActionsView(shoppingListItem: ShoppingListItem(id: 1, productID: 1, note: "note", amount: 1, shoppingListID: 1, done: 0, quID: 1, rowCreatedTimestamp: ""), toastType: Binding.constant(nil))
    }
}
