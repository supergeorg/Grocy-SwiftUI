//
//  MDProductGroupForm.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MDProductGroupFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil
    
    var existingProductGroup: MDProductGroup?
    @State var productGroup: MDProductGroup    
    
    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundProductGroup = grocyVM.mdProductGroups.first(where: {$0.name == productGroup.name})
        return !(productGroup.name.isEmpty || (foundProductGroup != nil && foundProductGroup!.id != productGroup.id))
    }
    
    init(existingProductGroup: MDProductGroup? = nil) {
        self.existingProductGroup = existingProductGroup
        let initialProductGroup = existingProductGroup ?? MDProductGroup(
            id: 0,
            name: "",
            active: true,
            mdProductGroupDescription: "",
            rowCreatedTimestamp: Date().iso8601withFractionalSeconds
        )
        _productGroup = State(initialValue: initialProductGroup)
        _isNameCorrect = State(initialValue: true)
    }
    
    private let dataToUpdate: [ObjectEntities] = [.product_groups]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func finishForm() {
        self.dismiss()
    }
    
    private func saveProductGroup() async {
        if productGroup.id == 0 {
            productGroup.id = grocyVM.findNextID(.product_groups)
        }
        isProcessing = true
        isSuccessful = nil
        do {
            if existingProductGroup == nil {
                _ = try await grocyVM.postMDObject(object: .product_groups, content: productGroup)
            } else {
                try await grocyVM.putMDObjectWithID(object: .product_groups, id: productGroup.id, content: productGroup)
            }
            grocyVM.postLog("Product group \(productGroup.name) successful.", type: .info)
            await updateData()
            isSuccessful = true
        } catch {
            grocyVM.postLog("Product group \(productGroup.name) failed. \(error)", type: .error)
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
            MyTextField(textToEdit: $productGroup.name, description: "Product group name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "A name is required", errorMessage: "Name already exists")
            MyToggle(isOn: $productGroup.active, description: "Active")
            MyTextField(textToEdit: $productGroup.mdProductGroupDescription, description: "Description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
        }
        .formStyle(.grouped)
        .onChange(of: productGroup.name) {
            isNameCorrect = checkNameCorrect()
        }
        .navigationTitle(existingProductGroup == nil ? "Create product group" : "Edit product group")
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    Task {
                        await saveProductGroup()
                    }
                }, label: {
                    if isProcessing == false {
                        Label("Save product group", systemImage: MySymbols.save)
                    } else {
                        ProgressView()
                    }
                })
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
