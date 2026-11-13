//
//  MDStoreFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftData
import SwiftUI

struct MDStoreFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(sort: \MDStore.name, order: .forward) var mdStores: MDStores

    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingStore: MDStore?
    @State private var store: MDStore

    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundStore = mdStores.first(where: { $0.name == store.name })
        return !(store.name.isEmpty || (foundStore != nil && foundStore!.id != store.id))
    }

    init(existingStore: MDStore? = nil) {
        self.existingStore = existingStore
        self.store = existingStore ?? MDStore()
    }

    private let dataToUpdate: [ObjectEntities] = [.shopping_locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func finishForm() {
        self.dismiss()
    }

    private func saveStore() async {
        if store.id == -1 {
            do {
                store.id = try grocyVM.findNextID(.shopping_locations)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        do {
            try store.modelContext?.save()
            if existingStore == nil {
                _ = try await grocyVM.postMDObject(object: .shopping_locations, content: store)
            } else {
                try await grocyVM.putMDObjectWithID(object: .shopping_locations, id: store.id, content: store)
            }
            GrocyLogger.info("Store \(store.name) successful.")
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Store \(store.name) failed. \(error)")
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
                textToEdit: $store.name,
                description: "Store",
                isCorrect: $isNameCorrect,
                leadingIcon: MySymbols.name,
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: store.name) {
                isNameCorrect = checkNameCorrect()
            }
            MyToggle(
                isOn: $store.active,
                description: "Active",
                icon: MySymbols.active
            )
            MyTextEditor(
                textToEdit: $store.mdStoreDescription,
                description: "Description",
                leadingIcon: MySymbols.description
            )
        }
        .formStyle(.grouped)
        .task {
            await updateData()
            self.isNameCorrect = checkNameCorrect()
        }
        .navigationTitle(existingStore == nil ? "Create store" : "Edit store")
        .toolbar(content: {
            if existingStore == nil {
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
                            await saveStore()
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
        MDStoreFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        MDStoreFormView(existingStore: MDStore(name: "Store"))
    }
}
