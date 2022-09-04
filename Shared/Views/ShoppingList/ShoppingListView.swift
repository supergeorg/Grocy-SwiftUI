//
//  ShoppingListView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct ShoppingListView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var selectedShoppingListID: Int = 1
    
    @State private var searchString: String = ""
    @State private var filteredStatus: ShoppingListStatus = ShoppingListStatus.all
    
    @State private var showSHLDeleteAlert: Bool = false
    @State var toastType: ToastType?
    @State var infoString: String?
    
    @State private var showClearListAlert: Bool = false
    
#if os(macOS)
    @State private var showNewShoppingList: Bool = false
    @State private var showEditShoppingList: Bool = false
    @State private var showAddItem: Bool = false
#elseif os(iOS)
    private enum InteractionSheet: Identifiable {
        case newShoppingList, editShoppingList, newShoppingListEntry
        var id: Int {
            self.hashValue
        }
    }
    @State private var activeSheet: InteractionSheet?
#endif
    
    private let dataToUpdate: [ObjectEntities] = [
        .products,
        .product_groups,
        .quantity_units,
        .quantity_unit_conversions,
        .shopping_lists,
        .shopping_list,
    ]
    func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
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
            .filter{
                $0.shoppingListID == selectedShoppingListID
            }
            .filter{ shLItem in
                if !searchString.isEmpty {
                    if let product = grocyVM.mdProducts.first(where: {$0.id == shLItem.productID}) {
                        return product.name.localizedCaseInsensitiveContains(searchString)
                    } else {
                        return false
                    }
                } else {
                    return true
                }
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
                case .done:
                    return shLItem.done == 1
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
    
    func deleteShoppingList() {
        grocyVM.deleteMDObject(object: .shopping_lists, id: selectedShoppingListID, completion: { result in
            switch result {
            case let .success(message):
                grocyVM.postLog("Shopping list delete successful. \(message)", type: .info)
                grocyVM.requestData(objects: [.shopping_lists])
            case let .failure(error):
                grocyVM.postLog("Shopping list delete failed. \(error)", type: .error)
                toastType = .shLActionFail
            }
        })
    }
    
    private func slAction(_ actionType: ShoppingListActionType) {
        grocyVM.shoppingListAction(content: ShoppingListAction(listID: selectedShoppingListID), actionType: actionType, completion: { result in
            switch result {
            case let .success(message):
                grocyVM.postLog("SHLAction successful. \(message)", type: .info)
                grocyVM.requestData(objects: [.shopping_list])
            case let .failure(error):
                grocyVM.postLog("SHLAction failed. \(error)", type: .error)
                toastType = .shLActionFail
            }
        })
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
            bodyContent
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.shL"))
        }
    }
    
    var bodyContent: some View {
        content
            .toolbar(content: {
                HStack {
#if os(iOS)
                    Menu(content: {
                        shoppingListActionContent
                    }, label: { HStack(spacing: 2){
                        Text(grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID})?.name ?? "No selected list")
                        Image(systemName: "chevron.down.square.fill")
                    }})
#elseif os(macOS)
                    shoppingListActionContent
#endif
#if os(macOS)
                    RefreshButton(updateData: { updateData() })
                        .help(LocalizedStringKey("str.refresh"))
#endif
                    Button(action: {
#if os(iOS)
                        activeSheet = .newShoppingListEntry
#elseif os(macOS)
                        showAddItem.toggle()
#endif
                    }, label: {
                        Label(LocalizedStringKey("str.shL.action.addItem"), systemImage: MySymbols.new)
                    })
                    .help(LocalizedStringKey("str.shL.action.addItem"))
#if os(macOS)
                    .popover(isPresented: $showAddItem, content: {
                        ScrollView{
                            ShoppingListEntryFormView(isNewShoppingListEntry: true, selectedShoppingListID: selectedShoppingListID)
                                .frame(width: 500, height: 400)
                        }
                    })
#endif
                }
            })
            .alert(LocalizedStringKey("str.shL.delete.confirm"), isPresented: $showSHLDeleteAlert, actions: {
                Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
                Button(LocalizedStringKey("str.delete"), role: .destructive) {
                    deleteShoppingList()
                }
            }, message: { Text(grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID})?.name ?? "Name not found") })
#if os(iOS)
            .sheet(item: $activeSheet, content: { item in
                switch item {
                case .newShoppingList:
                    ShoppingListFormView(isNewShoppingListDescription: true)
                case .editShoppingList:
                    ShoppingListFormView(isNewShoppingListDescription: false, shoppingListDescription: grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID}))
                case .newShoppingListEntry:
                    NavigationView {
                        ShoppingListEntryFormView(isNewShoppingListEntry: true, selectedShoppingListID: selectedShoppingListID)
                    }
                }
            })
#endif
    }
    
    var shoppingListActionContent: some View {
        Group {
            Button(action: {
#if os(iOS)
                activeSheet = .newShoppingList
#elseif os(macOS)
                showNewShoppingList.toggle()
#endif
            }, label: {
                Label(LocalizedStringKey("str.shL.new"), systemImage: MySymbols.shoppingList)
            })
            .help(LocalizedStringKey("str.shL.new"))
#if os(macOS)
            .popover(isPresented: $showNewShoppingList, content: {
                ShoppingListFormView(isNewShoppingListDescription: true)
                    .padding()
                    .frame(width: 250, height: 150)
            })
#endif
            Button(action: {
#if os(iOS)
                activeSheet = .editShoppingList
#elseif os(macOS)
                showEditShoppingList.toggle()
#endif
            }, label: {
                Label(LocalizedStringKey("str.shL.edit"), systemImage: MySymbols.edit)
            })
            .help(LocalizedStringKey("str.shL.edit"))
            Button(role: .destructive, action: {
                showSHLDeleteAlert.toggle()
            }, label: {
                Label(LocalizedStringKey("str.shL.delete"), systemImage: MySymbols.delete)
            })
            .help(LocalizedStringKey("str.shL.delete"))
            Divider()
            shoppingListItemActionContent
            Divider()
            Picker(selection: $selectedShoppingListID, label: Text(""), content: {
                ForEach(grocyVM.shoppingListDescriptions, id:\.id) { shoppingListDescription in
                    Text(shoppingListDescription.name).tag(shoppingListDescription.id)
                }
            })
            .help(LocalizedStringKey("str.shL"))
        }
    }
    
    var shoppingListItemActionContent: some View {
        Group {
            Button(role: .destructive, action: {
                showClearListAlert.toggle()
            }, label: {
                Label(LocalizedStringKey("str.shL.action.clearList"), systemImage: MySymbols.clear)
            })
            .help(LocalizedStringKey("str.shL.action.clearList"))
            //            Button(action: {
            //                print("Not implemented")
            //            }, label: {
            //                Label(LocalizedStringKey("str.shL.action.addListItemsToStock"), systemImage: "questionmark")
            //            })
            //            .help(LocalizedStringKey("str.shL.action.addListItemsToStock"))
            //                .disabled(true)
            Button(action: {
                slAction(.addMissing)
            }, label: {
                Label(LocalizedStringKey("str.shL.action.addBelowMinStock"), systemImage: MySymbols.addToShoppingList)
            })
            .help(LocalizedStringKey("str.shL.action.addBelowMinStock"))
            Button(action: {
                slAction(.addExpired)
                slAction(.addOverdue)
            }, label: {
                Label(LocalizedStringKey("str.shL.action.addOverdue"), systemImage: MySymbols.addToShoppingList)
            })
            .help(LocalizedStringKey("str.shL.action.addOverdue"))
        }
    }
    
    var content: some View {
        List {
            Section {
                ShoppingListFilterActionView(filteredStatus: $filteredStatus, numBelowStock: numBelowStock)
#if os(iOS)
                Menu {
                    Picker("", selection: $filteredStatus, content: {
                        Text(LocalizedStringKey(ShoppingListStatus.all.rawValue)).tag(ShoppingListStatus.all)
                        Text(LocalizedStringKey(ShoppingListStatus.belowMinStock.rawValue)).tag(ShoppingListStatus.belowMinStock)
                        Text(LocalizedStringKey(ShoppingListStatus.done.rawValue)).tag(ShoppingListStatus.done)
                        Text(LocalizedStringKey(ShoppingListStatus.undone.rawValue)).tag(ShoppingListStatus.undone)
                    })
                    .labelsHidden()
                } label: {
                    HStack {
                        Image(systemName: MySymbols.filter)
                        VStack{
                            Text(LocalizedStringKey("str.shL.filter.status"))
                            if filteredStatus != ShoppingListStatus.all {
                                Text(LocalizedStringKey(filteredStatus.rawValue))
                                    .font(.caption)
                            }
                        }
                    }
                }
#else
                Picker(selection: $filteredStatus,
                       label: Label(LocalizedStringKey("str.shL.filter.status"), systemImage: MySymbols.filter),
                       content: {
                    Text(LocalizedStringKey(ShoppingListStatus.all.rawValue)).tag(ShoppingListStatus.all)
                    Text(LocalizedStringKey(ShoppingListStatus.belowMinStock.rawValue)).tag(ShoppingListStatus.belowMinStock)
                    Text(LocalizedStringKey(ShoppingListStatus.done.rawValue)).tag(ShoppingListStatus.done)
                    Text(LocalizedStringKey(ShoppingListStatus.undone.rawValue)).tag(ShoppingListStatus.undone)
                })
#endif
            }
            ForEach(shoppingListProductGroups, id:\.id) {productGroup in
                Section(header: Text(productGroup.name).bold()) {
                    ForEach(groupedShoppingList[productGroup.id] ?? [], id:\.id) { shItem in
                        ShoppingListEntriesView(shoppingListItem: shItem, selectedShoppingListID: $selectedShoppingListID, toastType: $toastType, infoString: $infoString)
                    }
                }
            }
            if !(groupedShoppingList[0]?.isEmpty ?? true) {
                Section(header: Text(LocalizedStringKey("str.shL.ungrouped")).italic()) {
                    ForEach(groupedShoppingList[0] ?? [], id:\.id) { shItem in
                        ShoppingListEntriesView(shoppingListItem: shItem, selectedShoppingListID: $selectedShoppingListID, toastType: $toastType, infoString: $infoString)
                    }
                }
            }
        }
        .navigationTitle(LocalizedStringKey("str.shL"))
        .onAppear(perform: {
            grocyVM.requestData(objects: dataToUpdate, ignoreCached: false)
        })
        .searchable(text: $searchString,
                    prompt: LocalizedStringKey("str.search"))
        .refreshable {
            updateData()
        }
        .animation(.default, value: groupedShoppingList.count)
        .alert(LocalizedStringKey("str.shL.action.clearList.confirm"), isPresented: $showClearListAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                slAction(.clear)
            }
        }, message: { Text(grocyVM.shoppingListDescriptions.first(where: {$0.id == selectedShoppingListID})?.name ?? "Name not found") })
        .toast(
            item: $toastType,
            isSuccess: Binding.constant(false),
            isShown: [.shLActionFail].contains(toastType),
            text: {item in
                switch item {
                case .shLActionFail:
                    return LocalizedStringKey("str.shL.action.failed")
                default:
                    return LocalizedStringKey("str.error")
                }
            })
    }
}

struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListView()
    }
}
