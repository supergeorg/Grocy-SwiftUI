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
    
    @State private var selectedShoppingListID: Int = 1
    
    @State private var searchString: String = ""
    @State private var filteredStatus: ShoppingListStatus = ShoppingListStatus.all
    
    @State private var showSHLDeleteAlert: Bool = false
    @State private var shlItemToDelete: ShoppingListItem? = nil
    @State private var showEntryDeleteAlert: Bool = false
    
    @State private var toastType: ShoppingListToastType?
    
    #if os(macOS)
    @State private var showNewShoppingList: Bool = false
    @State private var showEditShoppingList: Bool = false
    #elseif os(iOS)
    private enum InteractionSheet: Identifiable {
        case newShoppingList, editShoppingList
        var id: Int {
            self.hashValue
        }
    }
    @State private var activeSheet: InteractionSheet?
    #endif
    
    func checkBelowStock(item: ShoppingListItem) -> Bool {
        if let product = grocyVM.mdProducts.first(where: {$0.id == item.productID}) {
            if product.minStockAmount > item.amount {
                return true
            }
        }
        return false
    }
    
    var selectedShoppingList: ShoppingList {
        grocyVM.shoppingList
//            .filter{
//                selectedShoppingListID.isEmpty ? true : $0.shoppingListID == selectedShoppingListID
//            }
            .filter{shLItem in
                if !searchString.isEmpty {
                    if let product = grocyVM.mdProducts.first(where: {$0.id == shLItem.productID}) {
                        return product.name.localizedCaseInsensitiveContains(searchString)
                    } else { return false }} else { return true }
            }
    }
    
    var filteredShoppingList: ShoppingList {
        selectedShoppingList
            .filter{ shLItem in
                switch filteredStatus {
                case .all:
                    return true
                case .belowMinStock:
                    return checkBelowStock(item: shLItem)
                case .undone:
                    return shLItem.done == 0
                }
            }
    }
    
    var shoppingListProductGroups: MDProductGroups {
        var groupIDs = Set<Int>()
        for shLItem in filteredShoppingList {
            if let product = grocyVM.mdProducts.first(where: {$0.id == shLItem.productID}) {
                if let productGroupID = product.productGroupID {
                    groupIDs.insert(productGroupID)
                }
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
    
    var groupedShoppingList: [Int : ShoppingList] {
        var dict: [Int : ShoppingList] = [:]
        for listItem in filteredShoppingList {
            let product = grocyVM.mdProducts.first(where: { $0.id == listItem.productID})
            let productGroup = grocyVM.mdProductGroups.first(where: { $0.id == product?.productGroupID})
            if (dict[productGroup?.id ?? 0] == nil) {
                dict[productGroup?.id ?? 0] = []
            }
            dict[productGroup?.id ?? 0]?.append(listItem)
        }
        return dict
    }
    
    var numBelowStock: Int {
        selectedShoppingList
            .filter{ shLItem in
                checkBelowStock(item: shLItem)
            }
            .count
    }
    
    private func deleteItem(at offsets: IndexSet, shL: ShoppingList) {
        for offset in offsets {
            shlItemToDelete = shL[offset]
            showEntryDeleteAlert.toggle()
        }
    }
    
    private func deleteSHLItem(toDelID: Int) {
        grocyVM.deleteMDObject(object: .shopping_list, id: toDelID, completion: { result in
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
    
    func deleteShoppingList() {
        grocyVM.deleteMDObject(object: .shopping_lists, id: selectedShoppingListID, completion: { result in
            switch result {
            case let .success(message):
                print(message)
                grocyVM.requestData(objects: [.shopping_lists])
            case let .failure(error):
                print("\(error)")
                toastType = .shLActionFail
            }
        })
    }
    
    func updateData() {
        grocyVM.requestData(objects: [.products, .product_groups, .quantity_units, .shopping_lists, .shopping_list])
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.count == 0 && grocyVM.failedToLoadAdditionalObjects.count == 0 {
            bodyContent
        } else {
            ServerOfflineView()
                .navigationTitle(LocalizedStringKey("str.shL"))
        }
    }
    
    #if os(macOS)
    var bodyContent: some View {
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
                        Label(LocalizedStringKey("str.shL.new"), systemImage: MySymbols.new)
                    })
                    .popover(isPresented: $showNewShoppingList, content: {
                        ShoppingListFormView(isNewShoppingListDescription: true)
                            .padding()
                            .frame(width: 250, height: 150)
                    })
                    Button(action: {
                        showEditShoppingList.toggle()
                    }, label: {
                        Label(LocalizedStringKey("str.shL.edit"), systemImage: MySymbols.edit)
                    })
                    .popover(isPresented: $showEditShoppingList, content: {
                        ShoppingListFormView(isNewShoppingListDescription: false, shoppingListDescription: grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID}))
                            .padding()
                            .frame(width: 250, height: 150)
                    })
                    Button(action: {
                        showSHLDeleteAlert.toggle()
                    }, label: {
                        Label(LocalizedStringKey("str.shL.delete"), systemImage: MySymbols.delete)
                            .foregroundColor(.red)
                    })
                    .alert(isPresented: $showSHLDeleteAlert) {
                        Alert(title: Text(LocalizedStringKey("str.shL.delete.confirm")), message: Text(grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID})?.name ?? "Fehler"), primaryButton: .destructive(Text(LocalizedStringKey("str.delete"))) {
                            deleteShoppingList()
                        }, secondaryButton: .cancel())
                    }
                    Button(action: {
                        withAnimation {
                            self.reloadRotationDeg += 360
                        }
                        updateData()
                    }, label: {
                        Image(systemName: MySymbols.reload)
                            .rotationEffect(Angle.degrees(reloadRotationDeg))
                    })
                })
            })
    }
    #elseif os(iOS)
    var bodyContent: some View {
        content
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic) {
                    HStack{
                        Menu(content: {
                            Button(action: {
                                activeSheet = .newShoppingList
                            }, label: {
                                Label(LocalizedStringKey("str.shL.new"), systemImage: MySymbols.new)
                            })
                            Button(action: {
                                activeSheet = .editShoppingList
                            }, label: {
                                Label(LocalizedStringKey("str.shL.edit"), systemImage: MySymbols.edit)
                            })
                            Button(action: {
                                showSHLDeleteAlert.toggle()
                            }, label: {
                                Label(LocalizedStringKey("str.shL.delete"), systemImage: MySymbols.delete)
                                    .foregroundColor(.red)
                            })
                            .alert(isPresented: $showSHLDeleteAlert) {
                                Alert(title: Text(LocalizedStringKey("str.shL.delete.confirm")), message: Text(grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID})?.name ?? "Error"), primaryButton: .destructive(Text(LocalizedStringKey("str.delete"))) {
                                    deleteShoppingList()
                                }, secondaryButton: .cancel())
                            }
                            Picker(selection: $selectedShoppingListID, label: Text(""), content: {
                                ForEach(grocyVM.shoppingListDescriptions, id:\.id) { shoppingListDescription in
                                    Text(shoppingListDescription.name).tag(shoppingListDescription.id)
                                }
                            })
                        }, label: { HStack(spacing: 2){
                            Text(grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID})?.name ?? "No selected list")
                            Image(systemName: "chevron.down.square.fill")
                        }})
                        Image(systemName: MySymbols.reload)
                            .foregroundColor(.blue)
                            .onTapGesture {
                                updateData()
                            }
                    }
                }
            })
            .sheet(item: $activeSheet, content: { item in
                switch item {
                case .newShoppingList:
                    ShoppingListFormView(isNewShoppingListDescription: true)
                case .editShoppingList:
                    ShoppingListFormView(isNewShoppingListDescription: false, shoppingListDescription: grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID}))
                }
            })
    }
    #endif
    
    var content: some View {
        List{
            Group {
                ShoppingListFilterActionView(filteredStatus: $filteredStatus, numBelowStock: numBelowStock)
                ShoppingListActionView(selectedShoppingListID: $selectedShoppingListID, toastType: $toastType)
                ShoppingListFilterView(searchString: $searchString, filteredStatus: $filteredStatus)
            }
            ForEach(shoppingListProductGroups, id:\.id) {productGroup in
                Section(header: Text(productGroup.name).bold()) {
                    ForEach(groupedShoppingList[productGroup.id] ?? [], id:\.id) {shItem in
                        ShoppingListRowView(shoppingListItem: shItem, isBelowStock: checkBelowStock(item: shItem), toastType: $toastType)
                    }
                    .onDelete(perform: { indexSet in
                        deleteItem(at: indexSet, shL: groupedShoppingList[productGroup.id] ?? [])
                    })
                }
            }
            if !(groupedShoppingList[0]?.isEmpty ?? true) {
                Section(header: Text(LocalizedStringKey("str.shL.ungrouped")).italic()) {
                    ForEach(groupedShoppingList[0] ?? [], id:\.id) {shItem in
                        ShoppingListRowView(shoppingListItem: shItem, isBelowStock: checkBelowStock(item: shItem), toastType: $toastType)
                    }
                    .onDelete(perform: { indexSet in
                        deleteItem(at: indexSet, shL: groupedShoppingList[0] ?? [])
                    })
                }
            }
        }
        .navigationTitle(LocalizedStringKey("str.shL"))
        .animation(.default)
        .toast(item: $toastType, isSuccess: Binding.constant(false), content: {item in
            switch item {
            case .shLActionFail:
                Label(LocalizedStringKey("str.shL.action.failed"), systemImage: MySymbols.failure)
            }
        })
        .onAppear(perform: {
            grocyVM.requestData(objects: [.products, .product_groups, .quantity_units, .shopping_lists, .shopping_list], ignoreCached: false)
        })
        .alert(isPresented: $showEntryDeleteAlert) {
            Alert(title: Text(LocalizedStringKey("str.shL.entry.delete.confirm")), message: Text(grocyVM.mdProducts.first(where: {$0.id == shlItemToDelete?.productID})?.name ?? "product name error"), primaryButton: .destructive(Text(LocalizedStringKey("str.delete"))) {
                if let deleteID = shlItemToDelete?.id {
                    deleteSHLItem(toDelID: deleteID)
                } else {print("delete error")}
            }, secondaryButton: .cancel())
        }
    }
}

struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListView()
    }
}
