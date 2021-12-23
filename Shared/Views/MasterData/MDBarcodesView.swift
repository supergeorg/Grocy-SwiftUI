//
//  MDBarcodesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 03.12.20.
//

import SwiftUI

struct MDBarcodeRowView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var barcode: MDProductBarcode
    
    var shoppingLocationName: String? {
        grocyVM.mdShoppingLocations.first(where: {$0.id == barcode.shoppingLocationID})?.name
    }
    var quIDName: String? {
        grocyVM.mdQuantityUnits.first(where: {$0.id == barcode.quID})?.name
    }
    
    var body: some View {
        VStack(alignment: .leading){
            Text(barcode.barcode)
                .font(.title)
            HStack{
                if let amount = barcode.amount {
                    Text(LocalizedStringKey("str.md.barcode.info.amount \("\(amount.formattedAmount) \(quIDName ?? String(barcode.quID ?? 0))")"))
                }
                if let storeName = shoppingLocationName {
                    Text(LocalizedStringKey("str.md.barcode.info.store \(storeName)"))
                }
            }.font(.caption)
        }
    }
}

struct MDBarcodesView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var productID: Int
    
    @State private var productBarcodeToDelete: MDProductBarcode? = nil
    @State private var showDeleteAlert: Bool = false
    
    @State private var showAddBarcode: Bool = false
    
    @Binding var toastType: MDToastType?
    
    private let dataToUpdate: [ObjectEntities] = [.product_barcodes]
    
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    var filteredBarcodes: MDProductBarcodes {
        grocyVM.mdProductBarcodes
            .filter{
                $0.productID == productID
            }
    }
    
    private func deleteItem(itemToDelete: MDProductBarcode) {
        productBarcodeToDelete = itemToDelete
        showDeleteAlert.toggle()
    }
    private func deleteProductBarcode(toDelID: Int) {
        grocyVM.deleteMDObject(object: .product_barcodes, id: toDelID, completion: { result in
            switch result {
            case let .success(message):
                grocyVM.postLog("Deleting barcode was successful. \(message)", type: .info)
                updateData()
            case let .failure(error):
                grocyVM.postLog("Deleting barcode failed. \(error)", type: .error)
                toastType = .failDelete
            }
        })
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
            bodyContent
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.md.barcodes"))
        }
    }
    
#if os(macOS)
    var bodyContent: some View {
        Section(header: Text(LocalizedStringKey("str.md.barcodes")).font(.headline)) {
            
            Button(action: {showAddBarcode.toggle()}, label: {Image(systemName: MySymbols.new)})
                .popover(isPresented: $showAddBarcode, content: {
                    MDBarcodeFormView(isNewBarcode: true, productID: productID, toastType: $toastType)
                })
            if filteredBarcodes.isEmpty {
                Text(LocalizedStringKey("str.md.barcodes.empty"))
            }
            NavigationView{
                List{
                    ForEach(filteredBarcodes, id:\.id) {productBarcode in
                        NavigationLink(
                            destination: ScrollView{
                                MDBarcodeFormView(isNewBarcode: false, productID: productID, editBarcode: productBarcode, toastType: $toastType)
                            },
                            label: {
                                MDBarcodeRowView(barcode: productBarcode)
                            })
                            .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                                Button(role: .destructive,
                                       action: { deleteItem(itemToDelete: productBarcode) },
                                       label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                                )
                            })
                    }
                }
                .frame(minWidth: 200, minHeight: 400)
            }
        }
        .onAppear(perform: { grocyVM.requestData(objects: dataToUpdate, ignoreCached: false) })
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successAdd || toastType == .successEdit), text: { item in
            switch item {
            case .successAdd:
                return LocalizedStringKey("str.md.new.success")
            case .failAdd:
                return LocalizedStringKey("str.md.new.fail")
            case .successEdit:
                return LocalizedStringKey("str.md.edit.success")
            case .failEdit:
                return LocalizedStringKey("str.md.edit.fail")
            case .failDelete:
                return LocalizedStringKey("str.md.delete.fail")
            }
        })
        .alert(LocalizedStringKey("str.md.barcode.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = productBarcodeToDelete?.id {
                    deleteProductBarcode(toDelID: toDelID)
                }
            }
        }, message: { Text(productBarcodeToDelete?.barcode ?? "Name not found") })
    }
#elseif os(iOS)
    var bodyContent: some View {
        Form {
            if filteredBarcodes.isEmpty {
                Text(LocalizedStringKey("str.md.barcodes.empty"))
            } else {
                ForEach(filteredBarcodes, id:\.id) {productBarcode in
                    NavigationLink(
                        destination: MDBarcodeFormView(isNewBarcode: false, productID: productID, editBarcode: productBarcode, toastType: $toastType),
                        label: {
                            MDBarcodeRowView(barcode: productBarcode)
                        })
                        .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                            Button(role: .destructive,
                                   action: { deleteItem(itemToDelete: productBarcode) },
                                   label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                            )
                        })
                }
            }
        }
        .navigationTitle(LocalizedStringKey("str.md.barcodes"))
        .onAppear(perform: { grocyVM.requestData(objects: dataToUpdate, ignoreCached: false) })
        .refreshable { updateData() }
        .animation(.default, value: filteredBarcodes.count)
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successAdd || toastType == .successEdit), text: { item in
            switch item {
            case .successAdd:
                return LocalizedStringKey("str.md.new.success")
            case .failAdd:
                return LocalizedStringKey("str.md.new.fail")
            case .successEdit:
                return LocalizedStringKey("str.md.edit.success")
            case .failEdit:
                return LocalizedStringKey("str.md.edit.fail")
            case .failDelete:
                return LocalizedStringKey("str.md.delete.fail")
            }
        })
        .toolbar(content: {
            ToolbarItem(placement: .automatic, content: {
                Button(action: {showAddBarcode.toggle()}, label: {
                    Label("str.md.barcode.new", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                })
            })
        })
        .sheet(isPresented: $showAddBarcode, content: {
            NavigationView{
                MDBarcodeFormView(isNewBarcode: true, productID: productID, toastType: $toastType)
            }
        })
        .alert(LocalizedStringKey("str.md.barcode.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = productBarcodeToDelete?.id {
                    deleteProductBarcode(toDelID: toDelID)
                }
            }
        }, message: { Text(productBarcodeToDelete?.barcode ?? "Name not found") })
    }
#endif
}

struct MDBarcodesView_Previews: PreviewProvider {
    @StateObject var grocyVM: GrocyViewModel = .shared
    static var previews: some View {
        NavigationView{
            MDBarcodesView(productID: 27, toastType: Binding.constant(nil))
        }
    }
}
