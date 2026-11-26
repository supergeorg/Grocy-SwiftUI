//
//  MDUserFieldsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 11.12.20.
//

import SwiftUI

struct MDUserFieldRowView: View {
    var userField: MDUserField

    var body: some View {
        VStack(alignment: .leading) {
            Text(userField.caption)
                .font(.headline)
            Text("\(Text("Name")): \(userField.name)")
            Text("\(Text("Entity")): \(userField.entity)")
            Text("\(Text("Type")): \(Text(LocalizedStringKey(UserFieldType(rawValue: userField.type)?.getDescription() ?? userField.type)))")
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDUserFieldsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Environment(\.dismiss) var dismiss

    @State private var searchString: String = ""
    @State private var showAddUserField: Bool = false
    /// The form for a new object zooms out of the create button.
    @Namespace private var addTransition

    @State private var shownEditPopover: MDUserField? = nil

    @State private var userFieldToDelete: MDUserField? = nil
    @State private var showDeleteConfirmation: Bool = false

    private let dataToUpdate: [ObjectEntities] = [.userfields]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private var filteredUserFields: MDUserFields {
        grocyVM.mdUserFields
            .filter {
                searchString.isEmpty
                    ? true : ($0.name.localizedCaseInsensitiveContains(searchString) || $0.caption.localizedCaseInsensitiveContains(searchString))
            }
            .sorted { ($0.entity, $0.sortNumber ?? .max, $0.caption) < ($1.entity, $1.sortNumber ?? .max, $1.caption) }
    }

    private func deleteItem(itemToDelete: MDUserField) {
        userFieldToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }
    private func deleteUserField(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .userfields, id: toDelID)
            GrocyLogger.info("Deleting userfield was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Deleting userfield failed. \(error)")
        }
    }

    var body: some View {
        if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count == 0 {
            bodyContent
        } else {
            ServerProblemView()
                .navigationTitle("Userfields")
        }
    }

    var bodyContent: some View {
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        action: {
                            showAddUserField.toggle()
                        },
                        label: { Label("Create", systemImage: MySymbols.new) }
                    )
                }
                #if os(iOS)
                    .matchedTransitionSource(id: ZoomTransitionID.add, in: addTransition)
                #endif
            }
            .navigationTitle("Userfields")
            #if os(iOS)
                .sheet(
                    isPresented: self.$showAddUserField,
                    content: {
                        NavigationStack {
                            MDUserFieldFormView(isNewUserField: true, showAddUserField: $showAddUserField)
                        }
                        .navigationTransition(.zoom(sourceID: ZoomTransitionID.add, in: addTransition))
                    }
                )
            #else
                .navigationDestination(
                    isPresented: $showAddUserField,
                    destination: { MDUserFieldFormView(isNewUserField: true, showAddUserField: $showAddUserField) }
                )
            #endif
    }

    var content: some View {
        List {
            if grocyVM.mdUserFields.isEmpty {
                ContentUnavailableView("No userfields found.", systemImage: MySymbols.userfields)
            } else if filteredUserFields.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(filteredUserFields) { userField in
                NavigationLink(destination: MDUserFieldFormView(isNewUserField: false, userField: userField, showAddUserField: .constant(false))) {
                    MDUserFieldRowView(userField: userField)
                }
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true,
                    content: {
                        Button(
                            role: .destructive,
                            action: { deleteItem(itemToDelete: userField) },
                            label: { Label("Delete", systemImage: MySymbols.delete) }
                        )
                    }
                )
            }
        }
        .task {
            await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await updateData()
        }
        .animation(.default, value: filteredUserFields.count)
        .alert(
            "Are you sure you want to delete user field \"\(userFieldToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let toDelID = userFieldToDelete?.id {
                        Task {
                            await deleteUserField(toDelID: toDelID)
                        }
                    }
                }
            }
        )
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        MDUserFieldsView()
    }
}
