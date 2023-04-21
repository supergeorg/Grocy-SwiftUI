//
//  MDProductGroupForm.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MDProductGroupFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var mdProductGroupDescription: String = ""
    
    var isNewProductGroup: Bool
    var productGroup: MDProductGroup?
    
    @Binding var showAddProductGroup: Bool
    @Binding var toastType: ToastType?
    
    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundProductGroup = grocyVM.mdProductGroups.first(where: {$0.name == name})
        return isNewProductGroup ? !(name.isEmpty || foundProductGroup != nil) : !(name.isEmpty || (foundProductGroup != nil && foundProductGroup!.id != productGroup!.id))
    }
    
    private func resetForm() {
        self.name = productGroup?.name ?? ""
        self.mdProductGroupDescription = productGroup?.mdProductGroupDescription ?? ""
        isNameCorrect = checkNameCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.product_groups]
    private func updateData() {
        Task {
            await grocyVM.requestData(objects: dataToUpdate)
        }
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
        let productGroupPOST = MDProductGroup(id: id, name: name, mdProductGroupDescription: mdProductGroupDescription, rowCreatedTimestamp: timeStamp)
        isProcessing = true
        if isNewProductGroup {
            do {
                _ = try await grocyVM.postMDObject(object: .product_groups, content: productGroupPOST)
                grocyVM.postLog("Product group added successfully.", type: .info)
                toastType = .successAdd
                updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Product group add failed. \(error)", type: .error)
                toastType = .failAdd
            }
        } else {
            do {
                try await grocyVM.putMDObjectWithID(object: .shopping_locations, id: id, content: productGroupPOST)
                grocyVM.postLog("Product group edited successfully.", type: .info)
                toastType = .successAdd
                updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Product group edit failed. \(error)", type: .error)
                toastType = .failAdd
            }
        }
        isProcessing = false
    }
    
    var body: some View {
        content
            .navigationTitle(isNewProductGroup ? LocalizedStringKey("str.md.productGroup.new") : LocalizedStringKey("str.md.productGroup.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await saveProductGroup() } }, label: {
                        Label(LocalizedStringKey("str.md.productGroup.save"), systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!isNameCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
#if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    if isNewProductGroup {
                        Button(LocalizedStringKey("str.cancel")) {
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
            Text(isNewProductGroup ? LocalizedStringKey("str.md.productGroup.new") : LocalizedStringKey("str.md.productGroup.edit"))
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            Section(header: Text(LocalizedStringKey("str.md.productGroup.info"))){
                MyTextField(textToEdit: $name, description: "str.md.productGroup.name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "str.md.productGroup.name.required", errorMessage: "str.md.productGroup.name.exists")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $mdProductGroupDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            }
        }
        .onAppear(perform: {
            if firstAppear {
                updateData()
                resetForm()
                firstAppear = false
            }
        })
    }
}

struct MDProductGroupFormView_Previews: PreviewProvider {
    static var previews: some View {
#if os(macOS)
        Group {
            MDProductGroupFormView(isNewProductGroup: true, showAddProductGroup: Binding.constant(true), toastType: Binding.constant(nil))
            MDProductGroupFormView(isNewProductGroup: false, productGroup: MDProductGroup(id: 0, name: "Name", mdProductGroupDescription: "Description", rowCreatedTimestamp: ""), showAddProductGroup: Binding.constant(false), toastType: Binding.constant(nil))
        }
#else
        Group {
            NavigationView {
                MDProductGroupFormView(isNewProductGroup: true, showAddProductGroup: Binding.constant(false), toastType: Binding.constant(nil))
            }
            NavigationView {
                MDProductGroupFormView(isNewProductGroup: false, productGroup: MDProductGroup(id: 0, name: "Name", mdProductGroupDescription: "Description", rowCreatedTimestamp: ""), showAddProductGroup: Binding.constant(false), toastType: Binding.constant(nil))
            }
        }
#endif
    }
}
