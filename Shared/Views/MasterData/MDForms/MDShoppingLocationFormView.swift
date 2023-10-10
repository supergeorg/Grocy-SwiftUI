//
//  MDStoreFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDStoreFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var isActive: Bool = true
    @State private var mdStoreDescription: String = ""
    
    var isNewStore: Bool
    var store: MDStore?
    
    @Binding var showAddStore: Bool
    
    
    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundStore = grocyVM.mdStores.first(where: {$0.name == name})
        return isNewStore ? !(name.isEmpty || foundStore != nil) : !(name.isEmpty || (foundStore != nil && foundStore!.id != store!.id))
    }
    
    private func resetForm() {
        self.name = store?.name ?? ""
        self.isActive = store?.active ?? true
        self.mdStoreDescription = store?.mdStoreDescription ?? ""
        isNameCorrect = checkNameCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.shopping_locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
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
    
    private func saveStore() async {
        let id = isNewStore ? grocyVM.findNextID(.shopping_locations) : store!.id
        let timeStamp = isNewStore ? Date().iso8601withFractionalSeconds : store!.rowCreatedTimestamp
        let storePOST = MDStore(id: id, name: name, active: isActive, mdStoreDescription: mdStoreDescription, rowCreatedTimestamp: timeStamp)
        isProcessing = true
        if isNewStore {
            do {
                _ = try await grocyVM.postMDObject(object: .shopping_locations, content: storePOST)
                grocyVM.postLog("Store added successfully.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Store add failed. \(error)", type: .error)
            }
        } else {
            do {
                try await grocyVM.putMDObjectWithID(object: .shopping_locations, id: id, content: storePOST)
                grocyVM.postLog("Store \(storePOST.name) edited successfully.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Store edit failed. \(error)", type: .error)
            }
        }
        isProcessing = false
    }
    
    var body: some View {
        content
            .navigationTitle(isNewStore ? "New store" : "Edit store")
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await saveStore() } },
                           label: {
                        Label("Save store", systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!isNameCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
#if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    if isNewStore {
                        Button("Cancel", role: .cancel, action: finishForm)
                    }
                }
#endif
            })
    }
    
    var content: some View {
        Form {
#if os(macOS)
            Text(isNewStore ? "New store" : "Edit store")
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            
            Section(header: Text("Store info")){
                MyTextField(textToEdit: $name, description: "Store", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "A name is required", errorMessage: "Name already exists")
                    .onChange(of: name) {
                        isNameCorrect = checkNameCorrect()
                    }
                MyToggle(isOn: $isActive, description: "Active")
                MyTextField(textToEdit: $mdStoreDescription, description: "Description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
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

//struct MDStoreFormView_Previews: PreviewProvider {
//    static var previews: some View {
//#if os(macOS)
//        Group {
//            MDStoreFormView(isNewStore: true, showAddStore: Binding.constant(true))
//            MDStoreFormView(isNewStore: false, store: MDStore(id: 0, name: "Shoppingloc", active: true, mdStoreDescription: "Descr", rowCreatedTimestamp: ""), showAddStore: Binding.constant(false))
//        }
//#else
//        Group {
//            NavigationView {
//                MDStoreFormView(isNewStore: true, showAddStore: Binding.constant(true))
//            }
//            NavigationView {
//                MDStoreFormView(isNewStore: false, store: MDStore(id: 0, name: "Store", active: true, mdStoreDescription: "Descr", rowCreatedTimestamp: ""), showAddStore: Binding.constant(false))
//            }
//        }
//#endif
//    }
//}
