//
//  ShoppingListView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct ShoppingListView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var reloadRotationDeg: Double = 0.0
    
    @State private var selectedShoppingListID: String = ""
    
    @State private var searchString: String = ""
    @State private var filteredStatus: ShoppingListStatus = ShoppingListStatus.all
    
    #if os(macOS)
    @State private var showNewShoppingList: Bool = false
    @State private var showEditShoppingList: Bool = false
    #endif
    
    var selectedShoppingList: ShoppingList {
        grocyVM.shoppingList
            .filter{
                selectedShoppingListID.isEmpty ? true : $0.shoppingListID == selectedShoppingListID
            }
            .filter{shLItem in
                if !searchString.isEmpty {
                if let product = grocyVM.mdProducts.first(where: {$0.id == shLItem.productID ?? ""}) {
                    return product.name.localizedCaseInsensitiveContains(searchString)
                } else { return false }} else { return true }
            }
            .filter{shLItem in
                switch filteredStatus {
                case .all:
                    return true
//                case .belowMinStock:
//                    return shLItem.amount
                case .undone:
                    return shLItem.done == "0"
                default: return true
                }
            }
    }
    
    var shoppingListProductGroups: MDProductGroups {
        var groupIDs = Set<String>()
        for shLItem in selectedShoppingList {
            if let product = grocyVM.mdProducts.first(where: {$0.id == shLItem.productID ?? ""}) {
                groupIDs.insert(product.productGroupID)
            }
        }
        var groups: MDProductGroups = []
        for groupID in groupIDs {
            if let group = grocyVM.mdProductGroups.first(where: {$0.id == groupID}) {
                groups.append(group)
            }
        }
        let sortedGroups = groups.sorted(by: {$0.name < $1.name})
        return sortedGroups
    }
    
    var groupedShoppingList: [String : ShoppingList] {
        var dict: [String : ShoppingList] = [:]
        for listItem in selectedShoppingList {
            let product = grocyVM.mdProducts.first(where: { $0.id == listItem.productID})
            let productGroup = grocyVM.mdProductGroups.first(where: { $0.id == product?.productGroupID})
            if (dict[productGroup?.id ?? "?"] == nil) {
                dict[productGroup?.id ?? "?"] = []
            }
            dict[productGroup?.id ?? "?"]?.append(listItem)
        }
        return dict
    }
    
    func refreshData() {
        grocyVM.getMDProducts()
        grocyVM.getMDProductGroups()
        grocyVM.getMDQuantityUnits()
        grocyVM.getShoppingListDescriptions()
        grocyVM.getShoppingList()
        if selectedShoppingListID.isEmpty {
            selectedShoppingListID = grocyVM.shoppingListDescriptions.first?.id ?? ""
        }
    }
    
    var body: some View {
        #if os(macOS)
        content
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic, content: {
                    Picker(selection: $selectedShoppingListID, label: Text("list: "), content: {
                        ForEach(grocyVM.shoppingListDescriptions, id:\.id) { shoppingListDescription in
                            Text(shoppingListDescription.name).tag(shoppingListDescription.id)
                        }
                    })
                    Button(action: {
                        showNewShoppingList.toggle()
                    }, label: {
                        Label("str.shL.new", systemImage: "plus")
                    })
                    .popover(isPresented: $showNewShoppingList, content: {
                        ShoppingListFormView(isNewShoppingListDescription: true)
                            .padding()
                            .frame(width: 250, height: 150)
                    })
                    Button(action: {
                        showEditShoppingList.toggle()
                    }, label: {
                        Label("str.shL.edit", systemImage: "square.and.pencil")
                    })
                    .popover(isPresented: $showEditShoppingList, content: {
                        ShoppingListFormView(isNewShoppingListDescription: false, shoppingListDescription: grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID}))
                            .padding()
                            .frame(width: 250, height: 150)
                    })
                    Button(action: {
                        print("delete")
                    }, label: {
                        Label("str.shL.delete", systemImage: "trash")
                            .foregroundColor(.red)
                    })
                    Button(action: {
                        withAnimation {
                            self.reloadRotationDeg += 360
                        }
                        refreshData()
                    }, label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(Angle.degrees(reloadRotationDeg))
                    })
                })
            })
        #elseif os(iOS)
        content
        #endif
    }
    
    var content: some View {
        List{
            Group {
                ShoppingListFilterActionView()
                ShoppingListInteractionView()
                ShoppingListFilterView(searchString: $searchString, filteredStatus: $filteredStatus)
            }
            ForEach(shoppingListProductGroups, id:\.id) {productGroup in
                Section(header: Text(productGroup.name)) {
                    ForEach(groupedShoppingList[productGroup.id] ?? [], id:\.id) {shItem in
                        ShoppingListRowView(shoppingListItem: shItem)
                    }
                }
            }
        }
        .navigationTitle("str.shL".localized)
        .onAppear(perform: {
            refreshData()
        })
    }
}

struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListView()
    }
}
