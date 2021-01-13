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
                #if os(macOS)
                Text(LocalizedStringKey("str.shL.action.addItem"))
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
                #elseif os(iOS)
                Text(LocalizedStringKey("str.shL.action.addItem"))
                    .padding(paddingAmount)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(cornerRadiusValue)
                    .onTapGesture {
                        showAddItem.toggle()
                    }
                    .sheet(isPresented: $showAddItem, content: {
                        ShoppingListEntryFormView(isNewShoppingListEntry: true, selectedShoppingListID: selectedShoppingListID)
                    })
                #endif
                Text(LocalizedStringKey("str.shL.action.clearList"))
                    .padding(paddingAmount)
                    .foregroundColor(.red)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadiusValue)
                            .stroke(Color.red, lineWidth: 1)
                    )
                    .onTapGesture {
                        slAction(.clear)
                    }
                Text(LocalizedStringKey("str.shL.action.addListItemsToStock"))
                    .padding(paddingAmount)
                    .foregroundColor(.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadiusValue)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    .onTapGesture {
                        print("not implemented")
                    }
                Text(LocalizedStringKey("str.shL.action.addBelowMinStock"))
                    .padding(paddingAmount)
                    .foregroundColor(.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadiusValue)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    .onTapGesture {
                        slAction(.addMissing)
                    }
                Text(LocalizedStringKey("str.shL.action.addOverdue"))
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
