//
//  MDUserEntityFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 22.01.21.
//

import SwiftUI

struct MDUserEntityFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Environment(\.dismiss) var dismiss

    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    @State private var name: String = ""
    @State private var caption: String = ""
    @State private var mdUserEntityDescription: String = ""
    @State private var showInSidebarMenu: Bool = false

    var isNewUserEntity: Bool
    var userEntity: MDUserEntity?

    @Binding var showAddUserEntity: Bool

    @State private var isNameCorrect: Bool = true
    /// Grocy only accepts letters and numbers, and each name once.
    private func checkNameCorrect() -> Bool {
        guard name.wholeMatch(of: /[A-Za-z0-9]+/) != nil else { return false }
        let foundUserEntity = grocyVM.mdUserEntities.first { $0.name == name }
        return foundUserEntity == nil || foundUserEntity?.id == userEntity?.id
    }

    @State private var isCaptionCorrect: Bool = true
    private func checkCaptionCorrect() -> Bool {
        return !caption.isEmpty
    }

    private func resetForm() {
        name = userEntity?.name ?? ""
        caption = userEntity?.caption ?? ""
        mdUserEntityDescription = userEntity?.mdUserEntityDescription ?? ""
        showInSidebarMenu = userEntity?.showInSidebarMenu == 1
        isNameCorrect = checkNameCorrect()
        isCaptionCorrect = checkCaptionCorrect()
    }

    private let dataToUpdate: [ObjectEntities] = [.userentities]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func finishForm() {
        #if os(iOS)
            self.dismiss()
        #elseif os(macOS)
            if isNewUserEntity {
                showAddUserEntity = false
            }
        #endif
    }

    private func showError(_ error: Error) {
        errorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
        isSuccessful = false
    }

    private func saveUserEntity() async {
        let id: Int
        if isNewUserEntity {
            do {
                id = try grocyVM.findNextID(.userentities)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        } else {
            id = userEntity!.id
        }
        let timeStamp = isNewUserEntity ? Date() : userEntity!.rowCreatedTimestamp
        let userEntityPOST = MDUserEntity(
            id: id,
            name: name,
            caption: caption,
            mdUserEntityDescription: mdUserEntityDescription,
            showInSidebarMenu: showInSidebarMenu ? 1 : 0,
            iconCSSClass: nil,
            rowCreatedTimestamp: timeStamp
        )
        isSuccessful = nil
        isProcessing = true
        if isNewUserEntity {
            do {
                _ = try await grocyVM.postMDObject(object: .userentities, content: userEntityPOST)
                GrocyLogger.info("User entity add successful.")
                isSuccessful = true
                resetForm()
                await updateData()
                finishForm()
            } catch {
                GrocyLogger.error("User entity add failed. \(error)")
                showError(error)
            }
        } else {
            do {
                try await grocyVM.putMDObjectWithID(object: .userentities, id: id, content: userEntityPOST)
                GrocyLogger.info("User entity edit successful.")
                isSuccessful = true
                await updateData()
                finishForm()
            } catch {
                GrocyLogger.error("User entity edit failed. \(error)")
                showError(error)
            }
        }
        isProcessing = false
    }

    var body: some View {
        content
            .navigationTitle(isNewUserEntity ? "Create userentity" : "Edit userentity")
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        role: .confirm,
                        action: {
                            Task {
                                await saveUserEntity()
                            }
                        },
                        label: {
                            // Label style is left to the system, so the confirm button gets the standard Liquid Glass look.
                            // While it runs, the icon becomes an animated progress symbol. It stays an image: with a ProgressView as its icon,
                            // the item loses its icon and leaves iPhone Duo's vertical bar for a text-only button at the bottom.
                            Label("Save", systemImage: isProcessing ? MySymbols.progress : MySymbols.save)
                                .symbolEffect(.variableColor.iterative, isActive: isProcessing)
                        }
                    )
                    .disabled(!isNameCorrect || !isCaptionCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
                ToolbarItem(placement: .cancellationAction) {
                    if isNewUserEntity {
                        Button(role: .cancel) {
                            finishForm()
                        }
                    }
                }
            })
            .sensoryFeedback(.success, trigger: isSuccessful == true)
            .sensoryFeedback(.error, trigger: isSuccessful == false)
    }

    var content: some View {
        Form {
            #if os(macOS)
                Text(isNewUserEntity ? "Create userentity" : "Edit userentity")
                    .font(.title)
                    .bold()
                    .padding(.bottom, Spacing.xLarge)
            #endif
            if isSuccessful == false, let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            Section(header: Text("Name of the userentity")) {
                MyTextField(
                    textToEdit: $name,
                    description: "Name of the userentity",
                    isCorrect: $isNameCorrect,
                    leadingIcon: MySymbols.name,
                    emptyMessage: "This is required and can only contain letters and numbers",
                    errorMessage: "This is required and can only contain letters and numbers"
                )
                // The internal name only allows letters and numbers, so the keyboard doesn't change what's typed.
                #if os(iOS)
                    .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .onChange(of: name) {
                    isNameCorrect = checkNameCorrect()
                }
                MyTextField(
                    textToEdit: $caption,
                    description: "Caption",
                    isCorrect: $isCaptionCorrect,
                    leadingIcon: MySymbols.name,
                    emptyMessage: "A caption is required"
                )
                .onChange(of: caption) {
                    isCaptionCorrect = checkCaptionCorrect()
                }
            }

            MyTextField(textToEdit: $mdUserEntityDescription, description: "Description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)

            MyToggle(isOn: $showInSidebarMenu, description: "Show in sidebar menu", icon: MySymbols.tableColumn)
        }
        .formStyle(.grouped)
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        MDUserEntityFormView(isNewUserEntity: true, showAddUserEntity: .constant(true))
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        MDUserEntityFormView(
            isNewUserEntity: false,
            userEntity: MDUserEntity(id: 1, name: "recipesources", caption: "Recipe sources"),
            showAddUserEntity: .constant(false)
        )
    }
}
