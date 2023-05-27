//
//  MDProductGroupsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDProductGroupRowView: View {
    var productGroup: MDProductGroup
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(productGroup.name)
                .font(.title)
            if let description = productGroup.mdProductGroupDescription, !description.isEmpty {
                Text(productGroup.mdProductGroupDescription!)
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDProductGroupsView: View {
    @ObservedObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var searchString: String = ""
    @State private var showAddProductGroup: Bool = false
    
    @State private var shownEditPopover: MDProductGroup? = nil
    
    @State private var productGroupToDelete: MDProductGroup? = nil
    @State private var showDeleteAlert: Bool = false
    
    @State private var toastType: ToastType?
    
    private let dataToUpdate: [ObjectEntities] = [.product_groups]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredProductGroups: MDProductGroups {
        grocyVM.mdProductGroups
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDProductGroup) {
        productGroupToDelete = itemToDelete
        showDeleteAlert.toggle()
    }
    private func deleteProductGroup(toDelID: Int?) async {
        if let toDelID = toDelID {
            do {
                try await grocyVM.deleteMDObject(object: .product_groups, id: toDelID)
                grocyVM.postLog("Deleting product group was successful.", type: .info)
                await updateData()
            } catch {
                grocyVM.postLog("Deleting product group failed. \(error)", type: .error)
                toastType = .failDelete
            }
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
#if os(macOS)
            NavigationView {
                bodyContent
                    .frame(minWidth: Constants.macOSNavWidth)
            }
#else
            bodyContent
#endif
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.md.productGroups"))
        }
    }
    
    var bodyContent: some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
#if os(macOS)
                    RefreshButton(updateData: { Task { await updateData() } })
#endif
                    Button(action: {
                        showAddProductGroup.toggle()
                    }, label: {Image(systemName: MySymbols.new)})
                }
            }
            .navigationTitle(LocalizedStringKey("str.md.productGroups"))
#if os(iOS)
            .sheet(isPresented: self.$showAddProductGroup, content: {
                NavigationView {
                    MDProductGroupFormView(isNewProductGroup: true, showAddProductGroup: $showAddProductGroup, toastType: $toastType)
                }
            })
#endif
    }
    
    var content: some View {
        List {
            if grocyVM.mdProductGroups.isEmpty {
                Text(LocalizedStringKey("str.md.productGroups.empty"))
            } else if filteredProductGroups.isEmpty {
                Text(LocalizedStringKey("str.noSearchResult"))
            }
#if os(macOS)
            if showAddProductGroup {
                NavigationLink(destination: MDProductGroupFormView(isNewProductGroup: true, showAddProductGroup: $showAddProductGroup, toastType: $toastType), isActive: $showAddProductGroup, label: {
                    NewMDRowLabel(title: "str.md.productGroup.new")
                })
            }
#endif
            ForEach(filteredProductGroups, id:\.id) { productGroup in
                NavigationLink(destination: MDProductGroupFormView(isNewProductGroup: false, productGroup: productGroup, showAddProductGroup: $showAddProductGroup, toastType: $toastType)) {
                    MDProductGroupRowView(productGroup: productGroup)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: productGroup) },
                           label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .task {
            await updateData()
        }
        .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
        .refreshable {
            await updateData()
        }
        .animation(.default, value: filteredProductGroups.count)
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
        .alert(LocalizedStringKey("str.md.productGroup.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = productGroupToDelete?.id {
                    Task {
                        await deleteProductGroup(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(productGroupToDelete?.name ?? "Name not found") })
    }
}

struct MDProductGroupsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDProductGroupRowView(productGroup: MDProductGroup(id: 0, name: "Name", mdProductGroupDescription: "Description", rowCreatedTimestamp: ""))
#if os(macOS)
            MDProductGroupsView()
#else
            NavigationView() {
                MDProductGroupsView()
            }
#endif
        }
    }
}
