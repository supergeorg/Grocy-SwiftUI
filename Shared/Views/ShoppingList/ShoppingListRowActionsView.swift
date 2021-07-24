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
    
    #if os(macOS)
    let ismacOS = true
    #else
    let ismacOS = false
    #endif
    
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
        grocyVM.putMDObjectWithID(object: .shopping_list, id: shoppingListItem.id, content: ShoppingListItem(id: shoppingListItem.id, productID: shoppingListItem.productID, note: shoppingListItem.note, amount: shoppingListItem.amount, rowCreatedTimestamp: shoppingListItem.rowCreatedTimestamp, shoppingListID: shoppingListItem.shoppingListID, done: shoppingListItem.done == 1 ? 0 : 1, quID: shoppingListItem.quID), completion: { result in
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
                .modifier(if: ismacOS, then: {$0.popover(isPresented: $showEdit, content: {
                    ScrollView{
                        ShoppingListEntryFormView(isNewShoppingListEntry: false, shoppingListEntry: shoppingListItem)
                            .frame(width: 500, height: 400)
                    }
                })}, else: {$0.sheet(isPresented: $showEdit, content: {
                    ShoppingListEntryFormView(isNewShoppingListEntry: false, shoppingListEntry: shoppingListItem)
                })})
            RowInteractionButton(image: "trash.fill", backgroundColor: Color.grocyDelete, helpString: LocalizedStringKey("str.shL.entry.delete"))
                .onTapGesture {
                    deleteSHItem()
                }
            #if os(macOS)
            RowInteractionButton(image: "shippingbox", backgroundColor: Color.blue, helpString: LocalizedStringKey("str.shL.entry.add \("\(shoppingListItem.amount) \(getQUString(amount: shoppingListItem.amount)) \(productName)")"))
                .onTapGesture {
                    showPurchase.toggle()
                }
                .popover(isPresented: $showPurchase, content: {
                    PurchaseProductView(productToPurchaseID: shoppingListItem.productID, productToPurchaseAmount: shoppingListItem.amount)
                        .padding()
                })
            #elseif os(iOS)
            RowInteractionButton(image: "shippingbox", backgroundColor: Color.blue, helpString: LocalizedStringKey("str.shL.entry.add \("\(shoppingListItem.amount) \(shoppingListItem.amount == 1 ? quantityUnit.name : quantityUnit.namePlural) \(productName)")"))
                .onTapGesture {
                    showPurchase.toggle()
                }
                .sheet(isPresented: $showPurchase, content: {
                        NavigationView{
                            PurchaseProductView(productToPurchaseID: shoppingListItem.productID, productToPurchaseAmount: shoppingListItem.amount)
                        }
                })
            #endif
        }
    }
}

//struct ShoppingListRowActionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        ShoppingListRowActionsView(shoppingListItem: ShoppingListItem(id: "1", productID: "1", note: "note", amount: "1", rowCreatedTimestamp: "", shoppingListID: "", done: "0", quID: "", userfields: nil), toastType: Binding.constant(nil))
//    }
//}
