//
//  ShoppingListRowView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct ShoppingListRowActionsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var shoppingListItem: ShoppingListItem
    
    let paddingValue: CGFloat = 7
    let cornerRadiusValue: CGFloat = 3
    let fontSizeValue: CGFloat = 15
    
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
            Image(systemName: shoppingListItem.done == "0" ? "checkmark" : "checkmark.circle")
                .frame(width: fontSizeValue, height: fontSizeValue)
                .font(Font.system(size: fontSizeValue, weight: .bold))
                .padding(paddingValue)
                .background(Color.grocyGreen)
                .foregroundColor(.white)
                .cornerRadius(cornerRadiusValue)
                .help(LocalizedStringKey("str.shL.entry.done"))
                .onTapGesture {
                    changeDoneStatus()
                }
            Image(systemName: "square.and.pencil")
                .frame(width: fontSizeValue, height: fontSizeValue)
                .font(Font.system(size: fontSizeValue, weight: .bold))
                .padding(paddingValue)
                .background(Color.grocyTurquoise)
                .foregroundColor(.white)
                .cornerRadius(cornerRadiusValue)
                .help(LocalizedStringKey("str.shL.entry.edit"))
                .onTapGesture {
                    showEdit.toggle()
                }
                .popover(isPresented: $showEdit, content: {
                    ShoppingListEntryFormView(isNewShoppingListEntry: false, shoppingListEntry: shoppingListItem)
                        .padding()
                })
            Image(systemName: "trash.fill")
                .frame(width: fontSizeValue, height: fontSizeValue)
                .font(Font.system(size: fontSizeValue, weight: .bold))
                .padding(paddingValue)
                .background(Color.grocyDelete)
                .foregroundColor(.white)
                .cornerRadius(cornerRadiusValue)
                .help(LocalizedStringKey("str.shL.entry.delete"))
                .onTapGesture {
                    deleteSHItem()
                }
            Image(systemName: "shippingbox")
                .frame(width: fontSizeValue, height: fontSizeValue)
                .font(Font.system(size: fontSizeValue, weight: .bold))
                .padding(paddingValue)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(cornerRadiusValue)
                //                .help("str.shL.entry.add \("\(shoppingListItem.amount) \(shoppingListItem.amount == "1" ? quantityUnit.name : quantityUnit.namePlural) \(productName)")".localized)
                .help(LocalizedStringKey("str.shL.entry.add \("\(shoppingListItem.amount) \(shoppingListItem.amount == "1" ? quantityUnit.name : quantityUnit.namePlural) \(productName)")"))
                .onTapGesture {
                    showPurchase.toggle()
                }
                .popover(isPresented: $showPurchase, content: {
                    PurchaseProductView(productToPurchaseID: shoppingListItem.productID, productToPurchaseAmount: Double(shoppingListItem.amount)!)
                        .padding()
                })
        }
    }
}

struct ShoppingListRowView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var shoppingListItem: ShoppingListItem
    
    var product: MDProduct {
        grocyVM.mdProducts.first(where: {$0.id == shoppingListItem.productID}) ?? MDProduct(id: "0", name: "Error Product", mdProductDescription: "error", productGroupID: "0", active: "0", locationID: "0", shoppingLocationID: nil, quIDPurchase: "0", quIDStock: "0", quFactorPurchaseToStock: "0", minStockAmount: "0", defaultBestBeforeDays: "0", defaultBestBeforeDaysAfterOpen: "0", defaultBestBeforeDaysAfterFreezing: "0", defaultBestBeforeDaysAfterThawing: "0", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "0", notCheckStockFulfillmentForRecipes: "0", parentProductID: nil, calories: "0", cumulateMinStockAmountOfSubProducts: "0", dueType: "0", quickConsumeAmount: "0", rowCreatedTimestamp: "0", userfields: nil)
    }
    
    var quantityUnit: MDQuantityUnit {
        grocyVM.mdQuantityUnits.first(where: {$0.id == product.quIDStock}) ?? MDQuantityUnit(id: "0", name: "Error QU", mdQuantityUnitDescription: nil, rowCreatedTimestamp: "", namePlural: "Error QU", pluralForms: nil, userfields: nil)
    }
    
    var body: some View {
        HStack{
            ShoppingListRowActionsView(shoppingListItem: shoppingListItem)
            Divider()
            VStack(alignment: .leading){
                Text(product.name)
                    .font(.headline)
                    .strikethrough(shoppingListItem.done == "1")
                Text("\("str.shL.amount".localized): \(shoppingListItem.amount) \(shoppingListItem.amount == "1" ? quantityUnit.name : quantityUnit.namePlural)")
                    .strikethrough(shoppingListItem.done == "1")
            }
            .foregroundColor(shoppingListItem.done == "1" ? Color.gray : Color.primary)
        }
    }
}

struct ShoppingListRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            ShoppingListRowActionsView(shoppingListItem: ShoppingListItem(id: "1", productID: "1", note: "note", amount: "1", rowCreatedTimestamp: "", shoppingListID: "", done: "0", quID: "", userfields: ""))
            ShoppingListRowView(shoppingListItem: ShoppingListItem(id: "1", productID: "1", note: "note", amount: "2", rowCreatedTimestamp: "ts", shoppingListID: "1", done: "0", quID: "1", userfields: nil))
        }
    }
}
