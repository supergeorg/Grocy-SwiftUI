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
    
    @State private var selectedShoppingListID: String = "1"
    
    @State private var searchString: String = ""
    @State private var filteredStatus: ShoppingListStatus = ShoppingListStatus.all
    
    @State private var showSHLDeleteAlert: Bool = false
    @State private var shlItemToDelete: ShoppingListItem? = nil
    @State private var showEntryDeleteAlert: Bool = false
    
    #if os(macOS)
    @State private var showNewShoppingList: Bool = false
    @State private var showEditShoppingList: Bool = false
    #elseif os(iOS)
    @State private var isShowingSheet: Bool = false
    private enum InteractionSheet: Identifiable {
        case none, newShoppingList, editShoppingList
        var id: Int {
            self.hashValue
        }
    }
    @State private var activeSheet: InteractionSheet = .newShoppingList //.none
    #endif
    
    func checkBelowStock(item: ShoppingListItem) -> Bool {
        if let product = grocyVM.mdProducts.first(where: {$0.id == item.productID}) {
            if Double(product.minStockAmount) ?? 0 < Double(item.amount) ?? 1 {
                return true
            }
        }
        return false
    }
    
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
                    return shLItem.done == "0"
                }
            }
    }
    
    var shoppingListProductGroups: MDProductGroups {
        var groupIDs = Set<String>()
        for shLItem in filteredShoppingList {
            if let product = grocyVM.mdProducts.first(where: {$0.id == shLItem.productID ?? ""}) {
                if let productGroupID = product.productGroupID {groupIDs.insert(productGroupID)}
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
        for listItem in filteredShoppingList {
            let product = grocyVM.mdProducts.first(where: { $0.id == listItem.productID})
            let productGroup = grocyVM.mdProductGroups.first(where: { $0.id == product?.productGroupID})
            if (dict[productGroup?.id ?? "?"] == nil) {
                dict[productGroup?.id ?? "?"] = []
            }
            dict[productGroup?.id ?? "?"]?.append(listItem)
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
    
    private func deleteItem(at offsets: IndexSet) {
        for offset in offsets {
            shlItemToDelete = selectedShoppingList[offset]
            showEntryDeleteAlert.toggle()
        }
    }
    private func deleteSHLItem(toDelID: String) {
        grocyVM.deleteMDObject(object: .shopping_list, id: toDelID)
        updateData()
    }
    
    func deleteShoppingList() {
        grocyVM.deleteMDObject(object: .shopping_lists, id: selectedShoppingListID)
        grocyVM.getShoppingListDescriptions()
    }
    
    func updateData() {
        grocyVM.getMDProducts()
        grocyVM.getMDProductGroups()
        grocyVM.getMDQuantityUnits()
        grocyVM.getShoppingListDescriptions()
        grocyVM.getShoppingList()
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
                        Label(LocalizedStringKey("str.shL.new"), systemImage: "plus")
                    })
                    .popover(isPresented: $showNewShoppingList, content: {
                        ShoppingListFormView(isNewShoppingListDescription: true)
                            .padding()
                            .frame(width: 250, height: 150)
                    })
                    Button(action: {
                        showEditShoppingList.toggle()
                    }, label: {
                        Label(LocalizedStringKey("str.shL.edit"), systemImage: "square.and.pencil")
                    })
                    .popover(isPresented: $showEditShoppingList, content: {
                        ShoppingListFormView(isNewShoppingListDescription: false, shoppingListDescription: grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID}))
                            .padding()
                            .frame(width: 250, height: 150)
                    })
                    Button(action: {
                        showSHLDeleteAlert.toggle()
                    }, label: {
                        Label(LocalizedStringKey("str.shL.delete"), systemImage: "trash")
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
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(Angle.degrees(reloadRotationDeg))
                    })
                })
            })
        #elseif os(iOS)
        content
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic) {
                    HStack{
                        Menu(content: {
                            Button(action: {
                                activeSheet = .newShoppingList
                                isShowingSheet.toggle()
                            }, label: {
                                Label(LocalizedStringKey("str.shL.new"), systemImage: "plus")
                            })
                            Button(action: {
                                activeSheet = .editShoppingList
                                isShowingSheet.toggle()
                            }, label: {
                                Label(LocalizedStringKey("str.shL.edit"), systemImage: "square.and.pencil")
                            })
                            Button(action: {
                                showSHLDeleteAlert.toggle()
                            }, label: {
                                Label(LocalizedStringKey("str.shL.delete"), systemImage: "trash")
                                    .foregroundColor(.red)
                            })
                            Picker(selection: $selectedShoppingListID, label: Text(""), content: {
                                ForEach(grocyVM.shoppingListDescriptions, id:\.id) { shoppingListDescription in
                                    Text(shoppingListDescription.name).tag(shoppingListDescription.id)
                                }
                            })
                            //                        }, label: {Text("str.shL.manage".localized)})
                        }, label: { HStack(spacing: 2){
                            Text(grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID})?.name ?? "No selected list")
                            Image(systemName: "chevron.down.square.fill")
                        }})
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)
                            .onTapGesture {
                                updateData()
                            }
                    }
                }
            })
            .sheet(isPresented: $isShowingSheet, content: {
                switch activeSheet {
                case .newShoppingList:
                    ShoppingListFormView(isNewShoppingListDescription: true)
                case .editShoppingList:
                    ShoppingListFormView(isNewShoppingListDescription: false, shoppingListDescription: grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID}))
                case .none:
                    EmptyView()
                }
            })
            .alert(isPresented: $showSHLDeleteAlert) {
                Alert(title: Text(LocalizedStringKey("str.shL.delete.confirm")), message: Text(grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID})?.name ?? "Error"), primaryButton: .destructive(Text(LocalizedStringKey("str.delete"))) {
                    deleteShoppingList()
                }, secondaryButton: .cancel())
            }
        #endif
    }
    
    var content: some View {
        List{
            Group {
                ShoppingListFilterActionView(filteredStatus: $filteredStatus, numBelowStock: numBelowStock)
                ShoppingListActionView(selectedShoppingListID: $selectedShoppingListID)
                ShoppingListFilterView(searchString: $searchString, filteredStatus: $filteredStatus)
            }
            ForEach(shoppingListProductGroups, id:\.id) {productGroup in
                Section(header: Text(productGroup.name).bold()) {
                    ForEach(groupedShoppingList[productGroup.id] ?? [], id:\.id) {shItem in
                        ShoppingListRowView(shoppingListItem: shItem)
                    }
                    .onDelete(perform: deleteItem)
                }
            }
            if !(groupedShoppingList["?"]?.isEmpty ?? true) {
                Section(header: Text(LocalizedStringKey("str.shL.ungrouped")).italic()) {
                    ForEach(groupedShoppingList["?"] ?? [], id:\.id) {shItem in
                        ShoppingListRowView(shoppingListItem: shItem)
                    }
                    .onDelete(perform: deleteItem)
                }
            }
        }
        .navigationTitle(LocalizedStringKey("str.shL"))
        .onAppear(perform: {
            updateData()
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
