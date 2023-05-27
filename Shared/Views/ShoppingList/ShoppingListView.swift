//
//  ShoppingListView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct ShoppingListItemWrapped {
    let shoppingListItem: ShoppingListItem
    let product: MDProduct?
}

struct ShoppingListView: View {
    @ObservedObject var grocyVM: GrocyViewModel = .shared
    
    @State private var selectedShoppingListID: Int = 1
    
    @State private var searchString: String = ""
    @State private var filteredStatus: ShoppingListStatus = .all
    private enum ShoppingListGrouping: Identifiable {
        case none, productGroup, defaultStore
        var id: Int {
            hashValue
        }
    }
    @State private var shoppingListGrouping: ShoppingListGrouping = .productGroup
    @State private var sortSetting = [KeyPathComparator(\ShoppingListItemWrapped.product?.name)]
    @State private var sortOrder: SortOrder = .forward
    
    @State private var showSHLDeleteAlert: Bool = false
    @State var toastType: ToastType?
    @State var infoString: String?
    @State private var showClearListAlert: Bool = false
    @State private var showClearDoneAlert: Bool = false
    
#if os(macOS)
    @State private var showNewShoppingList: Bool = false
    @State private var showEditShoppingList: Bool = false
    @State private var showAddItem: Bool = false
#elseif os(iOS)
    private enum InteractionSheet: Identifiable {
        case newShoppingList, editShoppingList, newShoppingListEntry
        var id: Int {
            hashValue
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
    func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    func checkBelowStock(item: ShoppingListItem) -> Bool {
        if let product = grocyVM.mdProducts.first(where: { $0.id == item.productID }) {
            if product.minStockAmount > item.amount {
                return true
            }
        }
        return false
    }
    
    var selectedShoppingList: ShoppingList {
        grocyVM.shoppingList
            .filter {
                $0.shoppingListID == selectedShoppingListID
            }
            .filter { shLItem in
                if !searchString.isEmpty {
                    if let product = grocyVM.mdProducts.first(where: { $0.id == shLItem.productID }) {
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
            .filter { shLItem in
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
    
    var groupedShoppingList: [String: [ShoppingListItemWrapped]] {
        var dict: [String: [ShoppingListItemWrapped]] = [:]
        for listItem in filteredShoppingList {
            let product = grocyVM.mdProducts.first(where: { $0.id == listItem.productID })
            switch shoppingListGrouping {
            case .productGroup:
                let productGroup = grocyVM.mdProductGroups.first(where: { $0.id == product?.productGroupID })
                if dict[productGroup?.name ?? ""] == nil {
                    dict[productGroup?.name ?? ""] = []
                }
                dict[productGroup?.name ?? ""]?.append(
                    ShoppingListItemWrapped(shoppingListItem: listItem, product: product)
                )
            case .defaultStore:
                let store = grocyVM.mdStores.first(where: { $0.id == product?.storeID })
                if dict[store?.name ?? ""] == nil {
                    dict[store?.name ?? ""] = []
                }
                dict[store?.name ?? ""]?.append(
                    ShoppingListItemWrapped(shoppingListItem: listItem, product: product)
                )
            default:
                if dict[""] == nil {
                    dict[""] = []
                }
                dict[""]?.append(
                    ShoppingListItemWrapped(shoppingListItem: listItem, product: product)
                )
            }
        }
        return dict
    }
    
    var numBelowStock: Int {
        selectedShoppingList
            .filter { shLItem in
                checkBelowStock(item: shLItem)
            }
            .count
    }
    
    var numUndone: Int {
        selectedShoppingList
            .filter { shLItem in
                shLItem.done == 0
            }
            .count
    }
    
    func deleteShoppingList() async {
        do {
            try await grocyVM.deleteMDObject(object: .shopping_lists, id: selectedShoppingListID)
            grocyVM.postLog("Deleting shopping list was successful.", type: .info)
            await grocyVM.requestData(objects: [.shopping_lists])
        } catch {
            grocyVM.postLog("Deleting shopping list failed. \(error)", type: .error)
            toastType = .shLActionFail
        }
    }
    
    private func slAction(_ actionType: ShoppingListActionType) async {
        do {
            if actionType == .clearDone {
                // this is not clean, but was the fastest way to work around the different data types
                let jsonContent = try! JSONEncoder().encode(ShoppingListClearAction(listID: selectedShoppingListID, doneOnly: true))
                try await grocyVM.grocyApi.shoppingListAction(content: jsonContent, actionType: actionType)
            } else {
                try await grocyVM.shoppingListAction(content: ShoppingListAction(listID: selectedShoppingListID), actionType: actionType)
            }
            grocyVM.postLog("SHLAction \(actionType) successful.", type: .info)
            await grocyVM.requestData(objects: [.shopping_list])
        } catch {
            grocyVM.postLog("SHLAction failed. \(error)", type: .error)
            toastType = .shLActionFail
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count == 0 {
            bodyContent
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.shL"))
        }
    }
    
    var bodyContent: some View {
        content
#if os(macOS)
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic, content: {
                    shoppingListActionContent
                    RefreshButton(updateData: { Task { await updateData() } })
                        .help(LocalizedStringKey("str.refresh"))
                    sortGroupMenu
                    Button(action: {
                        showAddItem.toggle()
                    }, label: {
                        Label(LocalizedStringKey("str.shL.action.addItem"), systemImage: MySymbols.new)
                    })
                    .help(LocalizedStringKey("str.shL.action.addItem"))
                    .popover(isPresented: $showAddItem, content: {
                        ScrollView {
                            ShoppingListEntryFormView(isNewShoppingListEntry: true, selectedShoppingListID: selectedShoppingListID)
                                .frame(width: 500, height: 400)
                        }
                    })
                })
            })
#else
            .toolbar(content: {
                HStack {
                    Menu(content: {
                        shoppingListActionContent
                    }, label: { HStack(spacing: 2) {
                        Text(grocyVM.shoppingListDescriptions.first(where: { $0.id == selectedShoppingListID })?.name ?? "No selected list")
                        Image(systemName: "chevron.down.square.fill")
                    }})
                    sortGroupMenu
                    Button(action: {
                        activeSheet = .newShoppingListEntry
                    }, label: {
                        Label(LocalizedStringKey("str.shL.action.addItem"), systemImage: MySymbols.new)
                    })
                    .help(LocalizedStringKey("str.shL.action.addItem"))
                }
            })
#endif
            .alert(LocalizedStringKey("str.shL.delete.confirm"), isPresented: $showSHLDeleteAlert, actions: {
                Button(LocalizedStringKey("str.cancel"), role: .cancel) {}
                Button(LocalizedStringKey("str.delete"), role: .destructive) {
                    Task {
                        await deleteShoppingList()
                    }
                }
            }, message: { Text(grocyVM.shoppingListDescriptions.first(where: { $0.id == selectedShoppingListID })?.name ?? "Name not found") })
#if os(iOS)
            .sheet(item: $activeSheet, content: { item in
                switch item {
                case .newShoppingList:
                    ShoppingListFormView(isNewShoppingListDescription: true)
                case .editShoppingList:
                    ShoppingListFormView(isNewShoppingListDescription: false, shoppingListDescription: grocyVM.shoppingListDescriptions.first(where: { $0.id == selectedShoppingListID }))
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
#if os(macOS)
            .popover(isPresented: $showEditShoppingList, content: {
                ShoppingListFormView(
                    isNewShoppingListDescription: false,
                    shoppingListDescription: grocyVM.shoppingListDescriptions.first(where: { $0.id == selectedShoppingListID })
                )
                .padding()
                .frame(width: 250, height: 150)
            })
#endif
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
                ForEach(grocyVM.shoppingListDescriptions, id: \.id) { shoppingListDescription in
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
            Button(role: .destructive, action: {
                showClearDoneAlert.toggle()
            }, label: {
                Label(LocalizedStringKey("str.shL.action.clearDone"), systemImage: MySymbols.done)
            })
            .help(LocalizedStringKey("str.shL.action.clearDone"))
            Button(action: {
                Task {
                    await slAction(.addMissing)
                }
            }, label: {
                Label(LocalizedStringKey("str.shL.action.addBelowMinStock"), systemImage: MySymbols.addToShoppingList)
            })
            .help(LocalizedStringKey("str.shL.action.addBelowMinStock"))
            Button(action: {
                Task {
                    await slAction(.addExpired)
                    await slAction(.addOverdue)
                }
            }, label: {
                Label(LocalizedStringKey("str.shL.action.addOverdue"), systemImage: MySymbols.addToShoppingList)
            })
            .help(LocalizedStringKey("str.shL.action.addOverdue"))
        }
    }
    
    var content: some View {
        List {
            Section {
                ShoppingListFilterActionView(
                    filteredStatus: $filteredStatus,
                    numBelowStock: numBelowStock,
                    numUndone: numUndone
                )
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
                        VStack {
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
            ForEach(groupedShoppingList.sorted(by: { $0.key < $1.key }), id: \.key) { groupName, groupElements in
#if os(macOS)
                DisclosureGroup(
                    isExpanded: Binding.constant(true),
                    content: {
                        ForEach(groupElements.sorted(using: sortSetting), id: \.shoppingListItem.productID, content: { element in
                            ShoppingListEntriesView(
                                shoppingListItem: element.shoppingListItem,
                                selectedShoppingListID: $selectedShoppingListID,
                                toastType: $toastType,
                                infoString: $infoString
                            )
                        })
                    }, label: {
                        if shoppingListGrouping == .productGroup, groupName.isEmpty {
                            Text(LocalizedStringKey("str.shL.ungrouped")).italic()
                        } else if shoppingListGrouping == .none {
                            EmptyView()
                        } else {
                            Text(groupName).bold()
                        }
                    }
                )
#else
                Section(content: {
                    ForEach(groupElements.sorted(using: sortSetting), id: \.shoppingListItem.productID, content: { element in
                        ShoppingListEntriesView(
                            shoppingListItem: element.shoppingListItem,
                            selectedShoppingListID: $selectedShoppingListID,
                            toastType: $toastType,
                            infoString: $infoString
                        )
                    })
                }, header: {
                    if shoppingListGrouping == .productGroup, groupName.isEmpty {
                        Text(LocalizedStringKey("str.shL.ungrouped")).italic()
                    } else if shoppingListGrouping == .none {
                        EmptyView()
                    } else {
                        Text(groupName).bold()
                    }
                })
#endif
            }
        }
        .navigationTitle(LocalizedStringKey("str.shL"))
        .task {
            await updateData()
        }
        .searchable(text: $searchString,
                    prompt: LocalizedStringKey("str.search"))
        .refreshable {
            await updateData()
        }
        .animation(.default, value: groupedShoppingList.count)
        .alert(LocalizedStringKey("str.shL.action.clearList.confirm"), isPresented: $showClearListAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) {}
            Button(LocalizedStringKey("str.confirm"), role: .destructive) {
                Task {
                    await slAction(.clear)
                }
            }
        }, message: { Text(grocyVM.shoppingListDescriptions.first(where: { $0.id == selectedShoppingListID })?.name ?? "Name not found") })
        .alert(LocalizedStringKey("str.shL.action.clearDone"), isPresented: $showClearDoneAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) {}
            Button(LocalizedStringKey("str.confirm"), role: .destructive) {
                Task {
                    await slAction(.clearDone)
                }
            }
        }, message: { Text(grocyVM.shoppingListDescriptions.first(where: { $0.id == selectedShoppingListID })?.name ?? "Name not found") })
        .toast(
            item: $toastType,
            isSuccess: Binding.constant(false),
            isShown: [.shLActionFail].contains(toastType),
            text: { item in
                switch item {
                case .shLActionFail:
                    return LocalizedStringKey("str.shL.action.failed")
                default:
                    return LocalizedStringKey("str.error")
                }
            }
        )
    }
    
    var sortGroupMenu: some View {
        Menu(content: {
            Picker(LocalizedStringKey("str.group.category"), selection: $shoppingListGrouping, content: {
                Label(LocalizedStringKey("str.none"), systemImage: MySymbols.product)
                    .labelStyle(.titleAndIcon)
                    .tag(ShoppingListGrouping.none)
                Label(LocalizedStringKey("str.stock.productGroup"), systemImage: MySymbols.amount)
                    .labelStyle(.titleAndIcon)
                    .tag(ShoppingListGrouping.productGroup)
                Label(LocalizedStringKey("str.md.product.store"), systemImage: MySymbols.amount)
                    .labelStyle(.titleAndIcon)
                    .tag(ShoppingListGrouping.defaultStore)
            })
#if os(iOS)
            .pickerStyle(.menu)
#else
            .pickerStyle(.inline)
#endif
            Picker(LocalizedStringKey("str.sort.category"), selection: $sortSetting, content: {
                if sortOrder == .forward {
                    Label(LocalizedStringKey("str.md.product.name"), systemImage: MySymbols.product)
                        .labelStyle(.titleAndIcon)
                        .tag([KeyPathComparator(\ShoppingListItemWrapped.product?.name, order: .forward)])
                    Label(LocalizedStringKey("str.stock.product.amount"), systemImage: MySymbols.amount)
                        .labelStyle(.titleAndIcon)
                        .tag([KeyPathComparator(\ShoppingListItemWrapped.shoppingListItem.amount, order: .forward)])
                } else {
                    Label(LocalizedStringKey("str.md.product.name"), systemImage: MySymbols.product)
                        .labelStyle(.titleAndIcon)
                        .tag([KeyPathComparator(\ShoppingListItemWrapped.product?.name, order: .reverse)])
                    Label(LocalizedStringKey("str.stock.product.amount"), systemImage: MySymbols.amount)
                        .labelStyle(.titleAndIcon)
                        .tag([KeyPathComparator(\ShoppingListItemWrapped.shoppingListItem.amount, order: .reverse)])
                }
            })
#if os(iOS)
            .pickerStyle(.menu)
#else
            .pickerStyle(.inline)
#endif
            Picker(LocalizedStringKey("str.sort.order"), selection: $sortOrder, content: {
                Label(LocalizedStringKey("str.sort.order.forward"), systemImage: MySymbols.sortForward)
                    .labelStyle(.titleAndIcon)
                    .tag(SortOrder.forward)
                Label(LocalizedStringKey("str.sort.order.reverse"), systemImage: MySymbols.sortReverse)
                    .labelStyle(.titleAndIcon)
                    .tag(SortOrder.reverse)
            })
#if os(iOS)
            .pickerStyle(.menu)
#else
            .pickerStyle(.inline)
#endif
            .onChange(of: sortOrder, perform: { newOrder in
                if var sortElement = sortSetting.first {
                    sortElement.order = newOrder
                    sortSetting = [sortElement]
                }
            })
        }, label: {
            Label(LocalizedStringKey("str.sort"), systemImage: MySymbols.sort)
        })
    }
}

struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListView()
    }
}
