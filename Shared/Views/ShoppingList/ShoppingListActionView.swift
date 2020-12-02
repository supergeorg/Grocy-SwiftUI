//
//  ShoppingListActionView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 27.11.20.
//

import SwiftUI

struct ShoppingListActionView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    let cornerRadiusValue: CGFloat = 3.0
    let paddingAmount: CGFloat = 4.0
    
    @State private var showAddItem: Bool = false
    
    @Binding var selectedShoppingListID: String
    
    private func slAction(_ actionType: ShoppingListActionType) {
        grocyVM.shoppingListAction(content: ShoppingListAction(listID: Int(selectedShoppingListID)!), actionType: actionType)
        grocyVM.getShoppingList()
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false){
            HStack(spacing: 5){
                Text("str.shL.action.addItem".localized)
                    .padding(paddingAmount)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(cornerRadiusValue)
                    .onTapGesture {
                        showAddItem.toggle()
                    }
                    .popover(isPresented: $showAddItem, content: {
                        ShoppingListEntryFormView(isNewShoppingListEntry: true, selectedShoppingListID: selectedShoppingListID)
                            .padding()
                    })
                Text("str.shL.action.clearList".localized)
                    .padding(paddingAmount)
                    .foregroundColor(.red)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadiusValue)
                            .stroke(Color.red, lineWidth: 1)
                    )
                    .onTapGesture {
                        slAction(.clear)
                    }
                Text("str.shL.action.addListItemsToStock".localized)
                    .padding(paddingAmount)
                    .foregroundColor(.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadiusValue)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    .onTapGesture {
                        print("not implemented")
                    }
                Text("str.shL.action.addBelowMinStock".localized)
                    .padding(paddingAmount)
                    .foregroundColor(.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadiusValue)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    .onTapGesture {
                        slAction(.addMissing)
                    }
                Text("str.shL.action.addOverdue".localized)
                    .padding(paddingAmount)
                    .foregroundColor(.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadiusValue)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    .onTapGesture {
                        slAction(.addExpired)
                        slAction(.addOverdue)
                    }
            }
        }
    }
}

struct ShoppingListActionView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListActionView(selectedShoppingListID: Binding.constant("1"))
    }
}
