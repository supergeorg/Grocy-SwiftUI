//
//  MDProductGroupForm.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MDProductGroupFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var mdProductGroupDescription: String = ""
    
    var isNewProductGroup: Bool
    var productGroup: MDProductGroup?
    
    @Binding var showAddProductGroup: Bool
    @Binding var toastType: MDToastType?
    
    @State var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundProductGroup = grocyVM.mdProductGroups.first(where: {$0.name == name})
        return isNewProductGroup ? !(name.isEmpty || foundProductGroup != nil) : !(name.isEmpty || (foundProductGroup != nil && foundProductGroup!.id != productGroup!.id))
    }
    
    private func resetForm() {
        self.name = productGroup?.name ?? ""
        self.mdProductGroupDescription = productGroup?.mdProductGroupDescription ?? ""
        isNameCorrect = checkNameCorrect()
    }
    
    private func updateData() {
        grocyVM.requestData(objects: [.product_groups])
    }
    
    private func finishForm() {
        #if os(iOS)
        presentationMode.wrappedValue.dismiss()
        #elseif os(macOS)
        if isNewProductGroup {
            showAddProductGroup = false
        }
        #endif
    }
    
    private func saveProductGroup() {
        let id = isNewProductGroup ? grocyVM.findNextID(.product_groups) : productGroup!.id
        let timeStamp = isNewProductGroup ? Date().iso8601withFractionalSeconds : productGroup!.rowCreatedTimestamp
        let productGroupPOST = MDProductGroup(id: id, name: name, mdProductGroupDescription: mdProductGroupDescription, rowCreatedTimestamp: timeStamp)
        isProcessing = true
        if isNewProductGroup {
            grocyVM.postMDObject(object: .product_groups, content: productGroupPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog(message: "Product group add successful. \(message)", type: .info)
                    toastType = .successAdd
                    resetForm()
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog(message: "Product group add failed. \(error)", type: .error)
                    toastType = .failAdd
                }
                isProcessing = false
            })
        } else {
            grocyVM.putMDObjectWithID(object: .product_groups, id: id, content: productGroupPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog(message: "Product group edit successful. \(message)", type: .info)
                    toastType = .successEdit
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog(message: "Product group edit failed. \(error)", type: .error)
                    toastType = .failEdit
                }
                isProcessing = false
            })
        }
    }
    
    var body: some View {
        #if os(macOS)
        ScrollView {
            content
                .padding()
        }
        #elseif os(iOS)
        content
            .navigationTitle(isNewProductGroup ? LocalizedStringKey("str.md.productGroup.new") : LocalizedStringKey("str.md.productGroup.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewProductGroup {
                        Button(LocalizedStringKey("str.cancel")) {
                            finishForm()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("str.md.productGroup.save")) {
                        saveProductGroup()
                    }
                    .disabled(!isNameCorrect || isProcessing)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    // Back not shown without it
                    if !isNewProductGroup{
                        Text("")
                    }
                }
            })
        #endif
    }
    
    var content: some View {
        Form {
            Section(header: Text(LocalizedStringKey("str.md.productGroup.info"))){
                MyTextField(textToEdit: $name, description: "str.md.productGroup.name", isCorrect: $isNameCorrect, leadingIcon: "tag", isEditing: true, emptyMessage: "str.md.productGroup.name.required", errorMessage: "str.md.productGroup.name.exists")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $mdProductGroupDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description, isEditing: true)
            }
            #if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    if isNewProductGroup{
                        finishForm()
                    } else {
                        resetForm()
                    }
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveProductGroup()
                }
                .disabled(!isNameCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
        .animation(.default)
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: [.product_groups], ignoreCached: false)
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
                MDProductGroupFormView(isNewProductGroup: true, showAddProductGroup: Binding.constant(true), toastType: Binding.constant(nil))
            }
            NavigationView {
                MDProductGroupFormView(isNewProductGroup: false, productGroup: MDProductGroup(id: 0, name: "Name", mdProductGroupDescription: "Description", rowCreatedTimestamp: ""), showAddProductGroup: Binding.constant(false), toastType: Binding.constant(nil))
            }
        }
        #endif
    }
}
