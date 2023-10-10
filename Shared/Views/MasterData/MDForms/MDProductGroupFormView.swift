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
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var isActive: Bool = true
    @State private var mdProductGroupDescription: String = ""
    
    var isNewProductGroup: Bool
    var productGroup: MDProductGroup?
    
    @Binding var showAddProductGroup: Bool
    
    
    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundProductGroup = grocyVM.mdProductGroups.first(where: {$0.name == name})
        return isNewProductGroup ? !(name.isEmpty || foundProductGroup != nil) : !(name.isEmpty || (foundProductGroup != nil && foundProductGroup!.id != productGroup!.id))
    }
    
    private func resetForm() {
        self.name = productGroup?.name ?? ""
        self.isActive = productGroup?.active ?? true
        self.mdProductGroupDescription = productGroup?.mdProductGroupDescription ?? ""
        isNameCorrect = checkNameCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.product_groups]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if isNewProductGroup {
            showAddProductGroup = false
        }
#endif
    }
    
    private func saveProductGroup() async {
        let id = isNewProductGroup ? grocyVM.findNextID(.product_groups) : productGroup!.id
        let timeStamp = isNewProductGroup ? Date().iso8601withFractionalSeconds : productGroup!.rowCreatedTimestamp
        let productGroupPOST = MDProductGroup(
            id: id,
            name: name,
            active: isActive,
            mdProductGroupDescription: mdProductGroupDescription,
            rowCreatedTimestamp: timeStamp
        )
        isProcessing = true
        if isNewProductGroup {
            do {
                _ = try await grocyVM.postMDObject(object: .product_groups, content: productGroupPOST)
                grocyVM.postLog("Product group added successfully.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Product group add failed. \(error)", type: .error)
            }
        } else {
            do {
                try await grocyVM.putMDObjectWithID(object: .product_groups, id: id, content: productGroupPOST)
                grocyVM.postLog("Product group edited successfully.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Product group edit failed. \(error)", type: .error)
            }
        }
        isProcessing = false
    }
    
    var body: some View {
        content
            .navigationTitle(isNewProductGroup ? "Create product group" : "Edit product group")
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await saveProductGroup() } }, label: {
                        Label("Save product group", systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!isNameCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
#if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    if isNewProductGroup {
                        Button("Cancel") {
                            finishForm()
                        }
                    }
                }
#endif
            })
    }
    
    var content: some View {
        Form {
#if os(macOS)
            Text(isNewProductGroup ? "Create product group" : "Edit product group")
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            Section(header: Text("Product group info")){
                MyTextField(textToEdit: $name, description: "Product group name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "A name is required", errorMessage: "Name already exists")
                    .onChange(of: name) {
                        isNameCorrect = checkNameCorrect()
                    }
                MyToggle(isOn: $isActive, description: "Active")
                MyTextField(textToEdit: $mdProductGroupDescription, description: "Description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            }
        }
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
    }
}

//struct MDProductGroupFormView_Previews: PreviewProvider {
//    static var previews: some View {
//#if os(macOS)
//        Group {
//            MDProductGroupFormView(isNewProductGroup: true, showAddProductGroup: Binding.constant(true))
//            MDProductGroupFormView(isNewProductGroup: false, productGroup: MDProductGroup(id: 0, name: "Name", active: true, mdProductGroupDescription: "Description", rowCreatedTimestamp: ""), showAddProductGroup: Binding.constant(false))
//        }
//#else
//        Group {
//            NavigationView {
//                MDProductGroupFormView(isNewProductGroup: true, showAddProductGroup: Binding.constant(false))
//            }
//            NavigationView {
//                MDProductGroupFormView(isNewProductGroup: false, productGroup: MDProductGroup(id: 0, name: "Name", active: true, mdProductGroupDescription: "Description", rowCreatedTimestamp: ""), showAddProductGroup: Binding.constant(false))
//            }
//        }
//#endif
//    }
//}
