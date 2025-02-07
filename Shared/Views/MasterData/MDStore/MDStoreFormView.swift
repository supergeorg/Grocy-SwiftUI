//
//  MDStoreFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI
import SwiftData

struct MDStoreFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDStore.name, order: .forward) var mdStores: MDStores
    
    @Environment(\.dismiss) var dismiss
    
    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil
    
    var existingStore: MDStore?
    @State var store: MDStore
    
    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundStore = mdStores.first(where: { $0.name == store.name })
        return !(store.name.isEmpty || (foundStore != nil && foundStore!.id != store.id))
    }
    
    init(existingStore: MDStore? = nil) {
        self.existingStore = existingStore
        let initialStore = existingStore ?? MDStore(
            id: 0,
            name: "",
            active: true,
            mdStoreDescription: "",
            rowCreatedTimestamp: Date().iso8601withFractionalSeconds
        )
        _store = State(initialValue: initialStore)
        _isNameCorrect = State(initialValue: true)
    }
    
    private let dataToUpdate: [ObjectEntities] = [.shopping_locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func finishForm() {
        self.dismiss()
    }
    
    private func saveStore() async {
        if store.id == 0 {
            store.id = grocyVM.findNextID(.shopping_locations)
        }
        isProcessing = true
        isSuccessful = nil
        do {
            if existingStore == nil {
                _ = try await grocyVM.postMDObject(object: .shopping_locations, content: store)
            } else {
                try await grocyVM.putMDObjectWithID(object: .shopping_locations, id: store.id, content: store)
            }
            grocyVM.postLog("Store \(store.name) successful.", type: .info)
            await updateData()
            isSuccessful = true
        } catch {
            grocyVM.postLog("Store \(store.name) failed. \(error)", type: .error)
            errorMessage = error.localizedDescription
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
            MyToggle(isOn: $store.active, description: "Active", icon: MySymbols.active)
            MyTextField(textToEdit: $store.mdStoreDescription, description: "Description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
        }
        .formStyle(.grouped)
        .task {
            await updateData()
            self.isNameCorrect = checkNameCorrect()
        }
        .navigationTitle(existingStore == nil ? "New store" : "Edit store")
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                           Task {
                               await saveStore()
                           }
                       },
                       label: {
                           Label("Save", systemImage: MySymbols.save)
                       })
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
