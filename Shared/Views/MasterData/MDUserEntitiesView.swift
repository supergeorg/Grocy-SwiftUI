//
//  MDUserEntitiesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 14.12.20.
//

import SwiftUI

struct MDUserEntityRowView: View {
    var userEntity: MDUserEntity
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(userEntity.caption)
                .font(.title)
            Text(userEntity.name)
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDUserEntitiesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var searchString: String = ""
    @State private var showAddUserEntity: Bool = false
    
    @State private var shownEditPopover: MDUserEntity? = nil
    
    @State private var userEntityToDelete: MDUserEntity? = nil
    @State private var showDeleteAlert: Bool = false
    
    @State private var toastType: ToastType?
    
    private let dataToUpdate: [ObjectEntities] = [.userentities]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredUserEntities: MDUserEntities {
        grocyVM.mdUserEntities
            .filter {
                searchString.isEmpty ? true : ($0.name.localizedCaseInsensitiveContains(searchString) || $0.caption.localizedCaseInsensitiveContains(searchString))
            }
    }
    
    private func deleteItem(itemToDelete: MDUserEntity) {
        userEntityToDelete = itemToDelete
        showDeleteAlert.toggle()
    }
    private func deleteUserEntity(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .userentities, id: toDelID)
            grocyVM.postLog("Deleting user entity was successful.", type: .info)
            await updateData()
        } catch {
            grocyVM.postLog("Deleting user entity failed. \(error)", type: .error)
            toastType = .failDelete
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
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
                .navigationTitle(LocalizedStringKey("str.md.userEntities"))
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
                        showAddUserEntity.toggle()
                    }, label: {Image(systemName: MySymbols.new)})
                }
            }
            .navigationTitle(LocalizedStringKey("str.md.userEntities"))
#if os(iOS)
            .sheet(isPresented: self.$showAddUserEntity, content: {
                NavigationView {
                    MDUserEntityFormView(isNewUserEntity: true, showAddUserEntity: $showAddUserEntity)
                } })
#endif
    }
    
    var content: some View {
        List{
            if grocyVM.mdUserEntities.isEmpty {
                Text(LocalizedStringKey("str.md.userEntities.empty"))
            } else if filteredUserEntities.isEmpty {
                ContentUnavailableView.search
            }
#if os(macOS)
            if showAddUserEntity {
                NavigationLink(destination: MDUserEntityFormView(isNewUserEntity: true, showAddUserEntity: $showAddUserEntity), isActive: $showAddUserEntity, label: {
                    NewMDRowLabel(title: "str.md.userEntity.new")
                })
            }
#endif
            ForEach(filteredUserEntities, id:\.id) { userEntity in
                NavigationLink(destination: MDUserEntityFormView(isNewUserEntity: false, userEntity: userEntity, showAddUserEntity: Binding.constant(false))) {
                    MDUserEntityRowView(userEntity: userEntity)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: userEntity) },
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
        .animation(.default, value: filteredUserEntities.count)
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
        .alert(LocalizedStringKey("str.md.userEntity.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = userEntityToDelete?.id {
                    Task {
                        await deleteUserEntity(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(userEntityToDelete?.name ?? "Name not found") })
    }
}

struct MDUserEntitiesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
#if os(macOS)
            MDUserEntitiesView()
#else
            NavigationView() {
                MDUserEntitiesView()
            }
#endif
        }
    }
}
