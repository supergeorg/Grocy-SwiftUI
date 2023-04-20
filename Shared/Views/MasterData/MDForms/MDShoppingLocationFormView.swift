//
//  MDStoreFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDStoreFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var mdStoreDescription: String = ""
    
    var isNewStore: Bool
    var store: MDStore?
    
    @Binding var showAddStore: Bool
    @Binding var toastType: ToastType?
    
    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundStore = grocyVM.mdStores.first(where: {$0.name == name})
        return isNewStore ? !(name.isEmpty || foundStore != nil) : !(name.isEmpty || (foundStore != nil && foundStore!.id != store!.id))
    }
    
    private func resetForm() {
        self.name = store?.name ?? ""
        self.mdStoreDescription = store?.mdStoreDescription ?? ""
        isNameCorrect = checkNameCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.shopping_locations]
    private func updateData() {
        Task {
            await grocyVM.requestData(objects: dataToUpdate)
        }
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if isNewStore {
            showAddStore = false
        }
#endif
    }
    
    private func saveStore() {
        let id = isNewStore ? grocyVM.findNextID(.shopping_locations) : store!.id
        let timeStamp = isNewStore ? Date().iso8601withFractionalSeconds : store!.rowCreatedTimestamp
        let storePOST = MDStore(id: id, name: name, mdStoreDescription: mdStoreDescription, rowCreatedTimestamp: timeStamp)
        isProcessing = true
        if isNewStore {
//            grocyVM.postMDObject(object: .shopping_locations, content: storePOST, completion: { result in
//                switch result {
//                case let .success(message):
//                    grocyVM.postLog("Store add successful. \(message)", type: .info)
//                    toastType = .successAdd
//                    updateData()
//                    finishForm()
//                case let .failure(error):
//                    grocyVM.postLog("Store add failed. \(error)", type: .error)
//                    toastType = .failAdd
//                }
//                isProcessing = false
//            })
        } else {
//            grocyVM.putMDObjectWithID(object: .shopping_locations, id: id, content: storePOST, completion: { result in
//                switch result {
//                case let .success(message):
//                    grocyVM.postLog("Store edit successful. \(message)", type: .info)
//                    toastType = .successEdit
//                    updateData()
//                    finishForm()
//                case let .failure(error):
//                    grocyVM.postLog("Store add failed. \(error)", type: .error)
//                    toastType = .failEdit
//                }
//                isProcessing = false
//            })
        }
        
    }
    
    var body: some View {
        content
            .navigationTitle(isNewStore ? LocalizedStringKey("str.md.store.new") : LocalizedStringKey("str.md.store.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveStore, label: {
                        Label(LocalizedStringKey("str.md.store.save"), systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!isNameCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
#if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    if isNewStore {
                        Button(LocalizedStringKey("str.cancel"), role: .cancel, action: finishForm)
                    }
                }
#endif
            })
    }
    
    var content: some View {
        Form {
#if os(macOS)
            Text(isNewStore ? LocalizedStringKey("str.md.store.new") : LocalizedStringKey("str.md.store.edit"))
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            
            Section(header: Text(LocalizedStringKey("str.md.store.info"))){
                MyTextField(textToEdit: $name, description: "str.md.store.name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "str.md.store.name.required", errorMessage: "str.md.store.name.exists")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $mdStoreDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
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

struct MDStoreFormView_Previews: PreviewProvider {
    static var previews: some View {
#if os(macOS)
        Group {
            MDStoreFormView(isNewStore: true, showAddStore: Binding.constant(true), toastType: Binding.constant(nil))
            MDStoreFormView(isNewStore: false, store: MDStore(id: 0, name: "Shoppingloc", mdStoreDescription: "Descr", rowCreatedTimestamp: ""), showAddStore: Binding.constant(false), toastType: Binding.constant(nil))
        }
#else
        Group {
            NavigationView {
                MDStoreFormView(isNewStore: true, showAddStore: Binding.constant(true), toastType: Binding.constant(nil))
            }
            NavigationView {
                MDStoreFormView(isNewStore: false, store: MDStore(id: 0, name: "Store", mdStoreDescription: "Descr", rowCreatedTimestamp: ""), showAddStore: Binding.constant(false), toastType: Binding.constant(nil))
            }
        }
#endif
    }
}
