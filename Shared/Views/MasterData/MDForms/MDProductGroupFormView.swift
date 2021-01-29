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
    
    @State private var name: String = ""
    @State private var mdProductGroupDescription: String = ""
    
    var isNewProductGroup: Bool
    var productGroup: MDProductGroup?
    
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
        grocyVM.getMDProductGroups()
    }
    
    private func finishForm() {
        #if os(iOS)
        presentationMode.wrappedValue.dismiss()
        #elseif os(macOS)
        if isNewProductGroup {
            NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        }
        #endif
    }
    
    private func saveProductGroup() {
        if isNewProductGroup {
            let productGroupPOST = MDProductGroupPOST(id: grocyVM.findNextID(.product_groups), name: name, mdProductGroupDescription: mdProductGroupDescription, rowCreatedTimestamp: Date().iso8601withFractionalSeconds, userfields: nil)
            grocyVM.postMDObject(object: .product_groups, content: productGroupPOST, completion: { result in
                switch result {
                case let .success(message):
                    print(message)
                    toastType = .successAdd
                    resetForm()
                    updateData()
                    finishForm()
                case let .failure(error):
                    print("\(error)")
                    toastType = .failAdd
                }
            })
        } else {
            let productGroupPOST = MDProductGroupPOST(id: Int(productGroup!.id)!, name: name, mdProductGroupDescription: mdProductGroupDescription, rowCreatedTimestamp: productGroup!.rowCreatedTimestamp, userfields: nil)
            grocyVM.putMDObjectWithID(object: .product_groups, id: productGroup!.id, content: productGroupPOST, completion: { result in
                switch result {
                case let .success(message):
                    print(message)
                    toastType = .successEdit
                    updateData()
                    finishForm()
                case let .failure(error):
                    print("\(error)")
                    toastType = .failEdit
                }
            })
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text(LocalizedStringKey("str.md.productGroup.info"))){
                MyTextField(textToEdit: $name, description: "str.md.productGroup.name", isCorrect: $isNameCorrect, leadingIcon: "tag", isEditing: true, errorMessage: "str.md.productGroup.name.required")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $mdProductGroupDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: "text.justifyleft", isEditing: true)
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
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
        .navigationTitle(isNewProductGroup ? LocalizedStringKey("str.md.productGroup.new") : LocalizedStringKey("str.md.productGroup.edit"))
        .animation(.default)
        .onAppear(perform: {
            if firstAppear {
                updateData()
                resetForm()
                firstAppear = false
            }
        })
        .toolbar(content: {
            #if os(iOS)
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
                }.disabled(!isNameCorrect)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                // Back not shown without it
                if !isNewProductGroup{
                    Text("")
                }
            }
            #endif
        })
    }
}

struct MDProductGroupFormView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        Group {
            MDProductGroupFormView(isNewProductGroup: true, toastType: Binding.constant(nil))
            MDProductGroupFormView(isNewProductGroup: false, productGroup: MDProductGroup(id: "0", name: "Name", mdProductGroupDescription: "Description", rowCreatedTimestamp: "", userfields: nil), toastType: Binding.constant(nil))
        }
        #else
        Group {
            NavigationView {
                MDProductGroupFormView(isNewProductGroup: true, toastType: Binding.constant(nil))
            }
            NavigationView {
                MDProductGroupFormView(isNewProductGroup: false, productGroup: MDProductGroup(id: "0", name: "Name", mdProductGroupDescription: "Description", rowCreatedTimestamp: "", userfields: nil), toastType: Binding.constant(nil))
            }
        }
        #endif
    }
}
