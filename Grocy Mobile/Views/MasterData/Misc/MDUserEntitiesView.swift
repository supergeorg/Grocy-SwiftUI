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
    @State private var showDeleteConfirmation: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.userentities]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
//    private var filteredUserEntities: MDUserEntities {
//        grocyVM.mdUserEntities
//            .filter {
//                searchString.isEmpty ? true : ($0.name.localizedCaseInsensitiveContains(searchString) || $0.caption.localizedCaseInsensitiveContains(searchString))
//            }
//    }
    
    private func deleteItem(itemToDelete: MDUserEntity) {
        userEntityToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }
    private func deleteUserEntity(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .userentities, id: toDelID)
            GrocyLogger.info("Deleting user entity was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Deleting user entity failed. \(error)")
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
                .navigationTitle("Userentities")
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
            .navigationTitle("Userentities")
#if os(iOS)
            .sheet(isPresented: self.$showAddUserEntity, content: {
                NavigationView {
                    MDUserEntityFormView(isNewUserEntity: true, showAddUserEntity: $showAddUserEntity)
                } })
#endif
    }
    
    var content: some View {
        List{
//            if grocyVM.mdUserEntities.isEmpty {
//                Text("No userentities found.")
//            } else if filteredUserEntities.isEmpty {
//                ContentUnavailableView.search
//            }
//            ForEach(filteredUserEntities, id:\.id) { userEntity in
//                NavigationLink(destination: MDUserEntityFormView(isNewUserEntity: false, userEntity: userEntity, showAddUserEntity: Binding.constant(false))) {
//                    MDUserEntityRowView(userEntity: userEntity)
//                }
//                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
//                    Button(role: .destructive,
//                           action: { deleteItem(itemToDelete: userEntity) },
//                           label: { Label("Delete", systemImage: MySymbols.delete) }
//                    )
//                })
//            }
        }
        .task {
            Task {
                await updateData()
            }
        }
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await updateData()
        }
//        .animation(.default, value: filteredUserEntities.count)
        .alert("Do you really want to delete this user entity?", isPresented: $showDeleteConfirmation, actions: {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let toDelID = userEntityToDelete?.id {
                    Task {
                        await deleteUserEntity(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(userEntityToDelete?.name ?? "Name not found") })
    }
}

#Preview {
    MDUserEntitiesView()
}
