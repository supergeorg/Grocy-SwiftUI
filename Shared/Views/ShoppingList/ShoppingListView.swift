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
    
    @State private var showDeleteAlert: Bool = false
    
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
            .filter{shLItem in
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
    
    func deleteShoppingList() {
        grocyVM.deleteMDObject(object: .shopping_lists, id: selectedShoppingListID)
        grocyVM.getShoppingListDescriptions()
    }
    
    func refreshData() {
        grocyVM.getMDProducts()
        grocyVM.getMDProductGroups()
        grocyVM.getMDQuantityUnits()
        grocyVM.getShoppingListDescriptions()
        grocyVM.getShoppingList()
        //        if selectedShoppingListID.isEmpty {
        //            selectedShoppingListID = grocyVM.shoppingListDescriptions.sorted(by: {$0.id < $1.id}).first?.id ?? ""
        //        }
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
                        showDeleteAlert.toggle()
                    }, label: {
                        Label("str.shL.delete".localized, systemImage: "trash")
                            .foregroundColor(.red)
                    })
                    .alert(isPresented: $showDeleteAlert) {
                        Alert(title: Text("str.shL.delete.confirm".localized), message: Text(grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID})?.name ?? "Fehler"), primaryButton: .destructive(Text("str.delete".localized)) {
                            deleteShoppingList()
                        }, secondaryButton: .cancel())
                    }
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
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic) {
                    HStack{
                        Menu(content: {
                            Button(action: {
                                activeSheet = .newShoppingList
                                isShowingSheet.toggle()
                            }, label: {
                                Label("str.shL.new", systemImage: "plus")
                            })
                            Button(action: {
                                activeSheet = .editShoppingList
                                isShowingSheet.toggle()
                            }, label: {
                                Label("str.shL.edit", systemImage: "square.and.pencil")
                            })
                            Button(action: {
                                showDeleteAlert.toggle()
                            }, label: {
                                Label("str.shL.delete".localized, systemImage: "trash")
                                    .foregroundColor(.red)
                            })
                            Picker(selection: $selectedShoppingListID, label: Text("list: "), content: {
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
                                refreshData()
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
            .alert(isPresented: $showDeleteAlert) {
                Alert(title: Text("str.shL.delete.confirm".localized), message: Text(grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID})?.name ?? "Fehler"), primaryButton: .destructive(Text("str.delete".localized)) {
                    deleteShoppingList()
                }, secondaryButton: .cancel())
            }
        #endif
    }
    
    var content: some View {
        List{
            Group {
                //                ShoppingListFilterActionView()
                ShoppingListActionView(selectedShoppingListID: $selectedShoppingListID)
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
