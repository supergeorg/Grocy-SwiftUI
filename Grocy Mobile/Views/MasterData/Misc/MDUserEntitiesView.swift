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
                .font(.headline)
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
    /// The form for a new object zooms out of the create button.
    @Namespace private var addTransition

    @State private var shownEditPopover: MDUserEntity? = nil

    @State private var userEntityToDelete: MDUserEntity? = nil
    @State private var showDeleteConfirmation: Bool = false

    private let dataToUpdate: [ObjectEntities] = [.userentities]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private var filteredUserEntities: MDUserEntities {
        grocyVM.mdUserEntities
            .filter {
                searchString.isEmpty
                    ? true : ($0.name.localizedCaseInsensitiveContains(searchString) || $0.caption.localizedCaseInsensitiveContains(searchString))
            }
    }

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
        if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count == 0 {
            bodyContent
        } else {
            ServerProblemView()
                .navigationTitle("Userentities")
        }
    }

    var bodyContent: some View {
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        action: {
                            showAddUserEntity.toggle()
                        },
                        label: { Label("Create", systemImage: MySymbols.new) }
                    )
                }
                #if os(iOS)
                    .matchedTransitionSource(id: ZoomTransitionID.add, in: addTransition)
                #endif
            }
            .navigationTitle("Userentities")
            .sheet(
                isPresented: self.$showAddUserEntity,
                content: {
                    NavigationStack {
                        MDUserEntityFormView(isNewUserEntity: true, showAddUserEntity: $showAddUserEntity)
                    }
                    #if os(iOS)
                        .navigationTransition(.zoom(sourceID: ZoomTransitionID.add, in: addTransition))
                    #else
                        .presentationSizing(.form)
                    #endif
                }
            )
    }

    var content: some View {
        List {
            ForEach(filteredUserEntities) { userEntity in
                NavigationLink(destination: UserObjectsView(userEntity: userEntity)) {
                    MDUserEntityRowView(userEntity: userEntity)
                }
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true,
                    content: {
                        Button(
                            role: .destructive,
                            action: { deleteItem(itemToDelete: userEntity) },
                            label: { Label("Delete", systemImage: MySymbols.delete) }
                        )
                    }
                )
            }
        }
        .overlay {
            if grocyVM.mdUserEntities.isEmpty {
                ContentUnavailableView("No userentities found.", systemImage: MySymbols.userEntities)
            } else if filteredUserEntities.isEmpty {
                ContentUnavailableView.search
            }
        }
        .task {
            await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await updateData()
        }
        .animation(.default, value: filteredUserEntities.count)
        .alert(
            "Are you sure you want to delete userentity \"\(userEntityToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let toDelID = userEntityToDelete?.id {
                        Task {
                            await deleteUserEntity(toDelID: toDelID)
                        }
                    }
                }
            }
        )
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        MDUserEntitiesView()
    }
}
