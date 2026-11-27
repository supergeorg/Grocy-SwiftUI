//
//  UserObjectsView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.11.26.
//

import SwiftUI

/// The records of a user entity. Each record consists only of the entity's userfields.
struct UserObjectsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var userEntity: MDUserEntity

    @State private var searchString: String = ""
    @State private var showAddUserObject: Bool = false
    /// The form for a new object zooms out of the create button.
    @Namespace private var addTransition
    @State private var values: [Int: [String: String]] = [:]

    @State private var userObjectToDelete: MDUserObject? = nil
    @State private var showDeleteConfirmation: Bool = false

    private let dataToUpdate: [ObjectEntities] = [.userentities, .userfields, .userobjects]

    private var fields: MDUserFields {
        grocyVM.userfields(for: userEntity.userfieldEntity)
    }

    private var userObjects: MDUserObjects {
        grocyVM.mdUserObjects.filter { $0.userentityID == userEntity.id }
    }

    private var filteredUserObjects: MDUserObjects {
        guard !searchString.isEmpty else { return userObjects }
        return userObjects.filter { userObject in
            values[userObject.id, default: [:]].values.contains { $0.localizedCaseInsensitiveContains(searchString) }
        }
    }

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
        // Grocy returns the values per record, so they are loaded side by side.
        let entity = userEntity.userfieldEntity
        values = await withTaskGroup(of: (Int, [String: String]?).self) { group in
            for userObject in userObjects {
                group.addTask {
                    (userObject.id, try? await grocyVM.getUserfieldValues(entity: entity, objectID: userObject.id).values)
                }
            }
            var values: [Int: [String: String]] = [:]
            for await (id, objectValues) in group {
                values[id] = objectValues
            }
            return values
        }
    }

    private func deleteUserObject(_ userObject: MDUserObject) async {
        do {
            try await grocyVM.deleteMDObject(object: .userobjects, id: userObject.id)
            GrocyLogger.info("Deleting user object was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Deleting user object failed. \(error)")
        }
    }

    var body: some View {
        if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count == 0 {
            content
        } else {
            ServerProblemView()
                .navigationTitle(userEntity.caption)
        }
    }

    var content: some View {
        List {
            ForEach(filteredUserObjects) { userObject in
                NavigationLink {
                    UserObjectFormView(userEntity: userEntity, existingUserObject: userObject)
                } label: {
                    UserObjectRowView(fields: fields, values: values[userObject.id, default: [:]])
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button("Delete", systemImage: MySymbols.delete, role: .destructive) {
                        userObjectToDelete = userObject
                        showDeleteConfirmation = true
                    }
                }
            }
        }
        .overlay {
            if fields.isEmpty {
                ContentUnavailableView(
                    "No userfields found.",
                    systemImage: MySymbols.userfields,
                    description: Text("The records of a user entity consist of its userfields. Add them in the userfields.")
                )
            } else if userObjects.isEmpty {
                ContentUnavailableView("No records found.", systemImage: MySymbols.userEntities)
            } else if filteredUserObjects.isEmpty {
                ContentUnavailableView.search
            }
        }
        .navigationTitle(userEntity.caption)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    MDUserEntityFormView(isNewUserEntity: false, userEntity: userEntity, showAddUserEntity: .constant(false))
                } label: {
                    Label("Edit userentity", systemImage: MySymbols.edit)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Create", systemImage: MySymbols.new) {
                    showAddUserObject = true
                }
                .disabled(fields.isEmpty)
            }
            #if os(iOS)
                .matchedTransitionSource(id: ZoomTransitionID.add, in: addTransition)
            #endif
        }
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")
        .animation(.default, value: filteredUserObjects.count)
        #if os(iOS)
            .sheet(isPresented: $showAddUserObject, onDismiss: { Task { await updateData() } }) {
                NavigationStack {
                    UserObjectFormView(userEntity: userEntity)
                }
                .navigationTransition(.zoom(sourceID: ZoomTransitionID.add, in: addTransition))
            }
        #else
            .navigationDestination(isPresented: $showAddUserObject) {
                UserObjectFormView(userEntity: userEntity)
            }
        #endif
        .alert("Do you really want to delete this record?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let userObjectToDelete {
                    Task { await deleteUserObject(userObjectToDelete) }
                }
            }
        }
    }
}

/// A record: the first userfield as the title, the other fields shown in tables below it.
struct UserObjectRowView: View {
    var fields: MDUserFields
    var values: [String: String]

    private func text(of field: MDUserField) -> String {
        field.displayValue(values[field.name] ?? "")
    }

    var body: some View {
        VStack(alignment: .leading) {
            if let titleField = fields.first {
                Text(verbatim: text(of: titleField))
                    .font(.headline)
            }
            ForEach(fields.dropFirst().filter { $0.showAsColumnInTables && !text(of: $0).isEmpty }) { field in
                Text(verbatim: "\(field.caption): \(text(of: field))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        UserObjectsView(userEntity: MDUserEntity(id: 1, name: "exampleuserentity", caption: "Example userentity"))
    }
}
