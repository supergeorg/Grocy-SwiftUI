//
//  MDStoresView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDStoreRowView: View {
    var store: MDStore
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(store.name)
                .font(.title)
                .foregroundColor(store.active ? .primary : .gray)
            if let description = store.mdStoreDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDStoresView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @State private var searchString: String = ""
    
    @State private var showAddStore: Bool = false
    @State private var storeToDelete: MDStore? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var toastType: ToastType?
    
    private let dataToUpdate: [ObjectEntities] = [.shopping_locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredStores: MDStores {
        grocyVM.mdStores
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDStore) {
        storeToDelete = itemToDelete
        showDeleteAlert.toggle()
    }
    private func deleteStore(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .shopping_locations, id: toDelID)
            grocyVM.postLog("Deleting store was successful.", type: .info)
            await updateData()
        } catch {
            grocyVM.postLog("Deleting store failed. \(error)", type: .error)
            toastType = .failDelete
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter( {dataToUpdate.contains($0) })
            .count == 0 {
#if os(macOS)
            NavigationView{
                bodyContent
                    .frame(minWidth: Constants.macOSNavWidth)
            }
#else
            bodyContent
#endif
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.md.stores"))
        }
    }
    
    var bodyContent: some View {
        content
            .toolbar(content: {
                ToolbarItemGroup(placement: .primaryAction, content: {
#if os(macOS)
                    RefreshButton(updateData: { Task { await updateData() } })
#endif
                    Button(action: {
                        showAddStore.toggle()
                    }, label: {
                        Image(systemName: MySymbols.new)
                    })
                })
            })
            .navigationTitle(LocalizedStringKey("str.md.stores"))
#if os(iOS)
            .sheet(isPresented: self.$showAddStore, content: {
                NavigationView {
                    MDStoreFormView(isNewStore: true, showAddStore: $showAddStore)
                }
            })
#endif
    }
    
    var content: some View {
        List{
            if grocyVM.mdStores.isEmpty {
                ContentUnavailableView("str.md.stores.empty", systemImage: MySymbols.store)
            } else if filteredStores.isEmpty {
                ContentUnavailableView.search
            }
#if os(macOS)
            if showAddStore {
                NavigationLink(destination: MDStoreFormView(isNewStore: true, showAddStore: $showAddStore), isActive: $showAddStore, label: {
                    NewMDRowLabel(title: "str.md.store.new")
                })
            }
#endif
            ForEach(filteredStores, id:\.id) { store in
                NavigationLink(destination: MDStoreFormView(isNewStore: false, store: store, showAddStore: Binding.constant(false))) {
                    MDStoreRowView(store: store)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: store) },
                           label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .task {
            Task {
                await updateData()
            }
        }
        .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
        .refreshable {
            await updateData()
        }
        .animation(.default,
                   value: filteredStores.count)
        .toast(
            item: $toastType,
            isSuccess: Binding.constant(toastType == .successAdd || toastType == .successEdit),
            isShown: [.successAdd, .failAdd, .successEdit, .failEdit, .failDelete].contains(toastType),
            text: { item in
                switch item {
                case .successAdd:
                    return LocalizedStringKey("str.md.new.success")
                case .failAdd:
                    return LocalizedStringKey("str.md.new.fail")
                case .successEdit:
                    return LocalizedStringKey("str.md.edit.success")
                case .failEdit:
                    return LocalizedStringKey("str.md.edit.fail")
                case .failDelete:
                    return LocalizedStringKey("str.md.delete.fail")
                default:
                    return LocalizedStringKey("str.error")
                }
            })
        .alert(LocalizedStringKey("str.md.store.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = storeToDelete?.id {
                    Task {
                        await deleteStore(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(storeToDelete?.name ?? "Name not found") })
    }
}

struct MDStoresView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            List {
                MDStoreRowView(store: MDStore(id: 0, name: "Location", active: true, mdStoreDescription: "Description", rowCreatedTimestamp: ""))
            }
#if os(macOS)
            MDStoresView()
#else
            NavigationView() {
                MDStoresView()
            }
#endif
        }
    }
}
