//
//  MDProductGroupForm.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftData
import SwiftUI

struct MDProductGroupFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups

    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingProductGroup: MDProductGroup?
    @State private var productGroup: MDProductGroup

    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundProductGroup = mdProductGroups.first(where: { $0.name == productGroup.name })
        return !(productGroup.name.isEmpty || (foundProductGroup != nil && foundProductGroup!.id != productGroup.id))
    }

    init(existingProductGroup: MDProductGroup? = nil) {
        self.existingProductGroup = existingProductGroup
        self.productGroup = existingProductGroup ?? MDProductGroup()
    }

    private let dataToUpdate: [ObjectEntities] = [.product_groups]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func finishForm() {
        self.dismiss()
    }

    private func saveProductGroup() async {
        if productGroup.id == -1 {
            do {
                productGroup.id = try grocyVM.findNextID(.product_groups)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        do {
            try productGroup.modelContext?.save()
            if existingProductGroup == nil {
                _ = try await grocyVM.postMDObject(object: .product_groups, content: productGroup)
            } else {
                try await grocyVM.putMDObjectWithID(object: .product_groups, id: productGroup.id, content: productGroup)
            }
            GrocyLogger.info("Product group \(productGroup.name) successful.")
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Product group \(productGroup.name) failed. \(error)")
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
            isSuccessful = false
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage = errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            MyTextField(
                textToEdit: $productGroup.name,
                description: "Name",
                isCorrect: $isNameCorrect,
                leadingIcon: MySymbols.name,
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: productGroup.name) {
                isNameCorrect = checkNameCorrect()
            }
            MyToggle(
                isOn: $productGroup.active,
                description: "Active",
                icon: MySymbols.active
            )
            MyTextEditor(
                textToEdit: $productGroup.mdProductGroupDescription,
                description: "Description",
                leadingIcon: MySymbols.description
            )
        }
        .formStyle(.grouped)
        .navigationTitle(existingProductGroup == nil ? "Create product group" : "Edit product group")
        .toolbar(content: {
            if existingProductGroup == nil {
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button(
                            role: .cancel,
                            action: {
                                finishForm()
                            }
                        )
                        .keyboardShortcut(.cancelAction)
                    }
                )
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await saveProductGroup()
                        }
                    },
                    label: {
                        if !isProcessing {
                            // Label style is left to the system, so the confirm button gets the standard Liquid Glass look.
                            Label("Save", systemImage: MySymbols.save)
                        } else {
                            ProgressView().progressViewStyle(.circular)
                        }
                    }
                )
                .disabled(!isNameCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        })
        .task {
            await updateData()
            self.isNameCorrect = checkNameCorrect()
        }
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                finishForm()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        MDProductGroupFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        MDProductGroupFormView(existingProductGroup: MDProductGroup(name: "Product group"))
    }
}
