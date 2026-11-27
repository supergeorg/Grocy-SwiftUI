//
//  UserObjectFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.11.26.
//

import SwiftUI

/// Creates or edits a record of a user entity. A record has no properties of its own, only the entity's userfields.
struct UserObjectFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil
    @State private var userfieldChanges = UserfieldChanges()

    var userEntity: MDUserEntity
    var existingUserObject: MDUserObject?

    private func saveUserObject() async {
        isProcessing = true
        isSuccessful = nil
        do {
            var id = existingUserObject?.id
            if id == nil {
                id = try await grocyVM.postMDObject(object: .userobjects, content: MDUserObject(userentityID: userEntity.id)).createdObjectID
            }
            if let id {
                try await grocyVM.saveUserfields(entity: userEntity.userfieldEntity, objectID: id, changes: userfieldChanges)
            }
            GrocyLogger.info("User object \(existingUserObject == nil ? "add" : "edit") successful.")
            await grocyVM.requestData(objects: [.userobjects])
            isSuccessful = true
        } catch {
            GrocyLogger.error("User object \(existingUserObject == nil ? "add" : "edit") failed. \(error)")
            isSuccessful = false
            errorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            UserfieldsSection(entity: userEntity.userfieldEntity, objectID: existingUserObject?.id, changes: $userfieldChanges)
        }
        .formStyle(.grouped)
        .navigationTitle(userEntity.caption)
        .toolbar {
            if existingUserObject == nil, !FormPresentation.createFormIsPushed {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) {
                    Task {
                        await saveUserObject()
                    }
                } label: {
                    Label("Save", systemImage: isProcessing ? MySymbols.progress : MySymbols.save)
                        .symbolEffect(.variableColor.iterative, isActive: isProcessing)
                }
                .disabled(isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        }
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                dismiss()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        UserObjectFormView(userEntity: MDUserEntity(id: 1, name: "exampleuserentity", caption: "Example userentity"))
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        UserObjectFormView(
            userEntity: MDUserEntity(id: 1, name: "exampleuserentity", caption: "Example userentity"),
            existingUserObject: MDUserObject(id: 1, userentityID: 1)
        )
    }
}
