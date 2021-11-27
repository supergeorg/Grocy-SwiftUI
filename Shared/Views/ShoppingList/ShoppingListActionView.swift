//
//  ShoppingListActionView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 27.11.20.
//

import SwiftUI

struct ShoppingListActionItem: View {
    var title: String
    var foregroundColor: Color
    var backgroundColor: Color?
    var hasBorder: Bool?
    
    let cornerRadiusValue: CGFloat = 5.0
    let paddingAmount: CGFloat = 9.0
    
    var body: some View {
        Text(LocalizedStringKey(title))
            .fontWeight(.regular)
            .padding(paddingAmount)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .cornerRadius(cornerRadiusValue)
    }
}

struct ShoppingListActionView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var showAddItem: Bool = false
    
    @Binding var selectedShoppingListID: Int
    @Binding var toastType: ShoppingListToastType?
    
    @State private var showClearListAlert: Bool = false
    
    private func slAction(_ actionType: ShoppingListActionType) {
        grocyVM.shoppingListAction(content: ShoppingListAction(listID: selectedShoppingListID), actionType: actionType, completion: { result in
            switch result {
            case let .success(message):
                grocyVM.postLog(message: "SHLAction successful. \(message)", type: .info)
                grocyVM.requestData(objects: [.shopping_list])
            case let .failure(error):
                grocyVM.postLog(message: "SHLAction failed: \(error)", type: .error)
                toastType = .shLActionFail
            }
        })
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false){
            HStack(spacing: 5){
                ShoppingListActionItem(title: "str.shL.action.addItem", foregroundColor: .white, backgroundColor: .blue)
                    .onTapGesture {
                        showAddItem.toggle()
                    }
#if os(iOS)
                    .sheet(isPresented: $showAddItem, content: {
                        NavigationView {
                            ShoppingListEntryFormView(isNewShoppingListEntry: true, selectedShoppingListID: selectedShoppingListID)
                        }
                    })
#elseif os(macOS)
                    .popover(isPresented: $showAddItem, content: {
                        ScrollView{
                            ShoppingListEntryFormView(isNewShoppingListEntry: true, selectedShoppingListID: selectedShoppingListID)
                                .frame(width: 500, height: 400)
                        }
                    })
#endif
                
                ShoppingListActionItem(title: "str.shL.action.clearList", foregroundColor: .red, hasBorder: true)
                    .onTapGesture {
                        showClearListAlert.toggle()
                    }
                
                //                ShoppingListActionItem(title: "str.shL.action.addListItemsToStock", foregroundColor: .blue, hasBorder: true)
                //                                    .onTapGesture {
                //                                        print("not implemented")
                //                                    }
                
                ShoppingListActionItem(title: "str.shL.action.addBelowMinStock", foregroundColor: .blue, hasBorder: true)
                    .onTapGesture {
                        slAction(.addMissing)
                    }
                
                ShoppingListActionItem(title: "str.shL.action.addOverdue", foregroundColor: .blue, hasBorder: true)
                    .onTapGesture {
                        slAction(.addExpired)
                        slAction(.addOverdue)
                    }
            }
            .alert(LocalizedStringKey("str.shL.action.clearList.confirm"), isPresented: $showClearListAlert, actions: {
                Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
                Button(LocalizedStringKey("str.delete"), role: .destructive) {
                    slAction(.clear)
                }
            }, message: { Text(grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID})?.name ?? "Name not found") })
        }
    }
}

struct ShoppingListActionView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListActionView(selectedShoppingListID: Binding.constant(1), toastType: Binding.constant(nil))
    }
}
