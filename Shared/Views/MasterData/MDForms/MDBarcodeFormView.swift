//
//  MDBarcodeFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 03.12.20.
//

import SwiftUI

struct MDBarcodeFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var barcode: String = ""
    @State private var amount: Double?
    @State private var quantityUnitID: Int?
    @State private var storeID: Int?
    @State private var note: String = ""
    
    var isNewBarcode: Bool
    var productID: Int
    var editBarcode: MDProductBarcode?
    
    
    
    @State private var isBarcodeCorrect: Bool = false
    private func checkBarcodeCorrect() -> Bool {
        // check if Barcode is already used
        let foundBarcode = grocyVM.mdProductBarcodes.filter({ $0.barcode == barcode }).first
        return ((foundBarcode == nil || foundBarcode?.barcode == editBarcode?.barcode) && (!barcode.isEmpty))
    }
    
    private var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productID})
    }
    
    private func resetForm() {
        barcode = editBarcode?.barcode ?? ""
        if let doubleAmount = editBarcode?.amount {
            amount = doubleAmount
        } else {amount = nil}
        quantityUnitID = editBarcode?.quID ?? product?.quIDPurchase
        storeID = editBarcode?.storeID
        note = editBarcode?.note ?? ""
        isBarcodeCorrect = checkBarcodeCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.product_barcodes]
    private func updateData() async {
            await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if isNewBarcode {
            NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        }
#endif
    }
    
    private func saveBarcode() async {
        let saveBarcode = MDProductBarcode(id: isNewBarcode ? grocyVM.findNextID(.product_barcodes) : editBarcode!.id, productID: productID, barcode: barcode, quID: quantityUnitID, amount: amount, storeID: storeID, lastPrice: nil, rowCreatedTimestamp: isNewBarcode ? Date().iso8601withFractionalSeconds : editBarcode?.rowCreatedTimestamp ?? "", note: note)
        if isNewBarcode{
            do {
                _ = try await grocyVM.postMDObject(object: .product_barcodes, content: saveBarcode)
                grocyVM.postLog("Barcode added successfully.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Barcode add failed. \(error)", type: .error)
            }
        } else {
            if let id = editBarcode?.id {
                do {
                    try await grocyVM.putMDObjectWithID(object: .product_barcodes, id: id, content: saveBarcode)
                    grocyVM.postLog("Barcode edit successful.", type: .info)
                    await updateData()
                    finishForm()
                } catch {
                    grocyVM.postLog("Barcode edit failed. \(error)", type: .error)
                }
            }
        }
        isProcessing = false
    }
    
#if os(iOS)
    @State private var isTorchOn = false
    @State private var isFrontCamera = false
    @State private var isShowingScanner = false
    func handleScan(result: Result<CodeScannerView.ScanResult, CodeScannerView.ScanError>) {
        self.isShowingScanner = false
        switch result {
        case .success(let code):
            barcode = code.string
        case .failure(let error):
            grocyVM.postLog("Scanning barcode failed. \(error)", type: .error)
        }
    }
#endif
    
    var body: some View {
        content
            .navigationTitle(isNewBarcode ? "Add barcode" : "Edit barcode")
#if os(iOS)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewBarcode {
                        Button("Cancel") {
                            finishForm()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        Task {
                            await saveBarcode()
                        }
                    }, label: {
                        Label("Save barcode", systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                        .disabled(!isBarcodeCorrect || isProcessing)
                        .keyboardShortcut(.defaultAction)
                }
            })
#endif
    }
    
    var content: some View {
        Form {
#if os(macOS)
            if isNewBarcode {
                HStack(alignment: .center){
                    Text("Add barcode")
                        .font(.title)
                    Spacer()
                    Text("str.md.barcode.for \(product?.name ?? "PRODUCT""))
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
            }
#endif
            HStack{
                MyTextField(textToEdit: $barcode, description: "Barcode", isCorrect: $isBarcodeCorrect, leadingIcon: MySymbols.barcode, emptyMessage: "A barcode is required", errorMessage: "The barcode is invalid or already in use.", helpText: nil)
                    .onChange(of: barcode) {
                        isBarcodeCorrect = checkBarcodeCorrect()
                    }
#if os(iOS)
                Button(action: {
                    isShowingScanner.toggle()
                }, label: {
                    Image(systemName: MySymbols.barcodeScan)
                })
                    .sheet(isPresented: $isShowingScanner) {
                        CodeScannerView(
                            codeTypes: getSavedCodeTypes().map{$0.type},
                            scanMode: .once,
                            simulatedData: "5901234123457",
                            isTorchOn: $isTorchOn,
                            isFrontCamera: $isFrontCamera,
                            completion: self.handleScan
                        )
                            .overlay(
                                HStack{
                                    Button(action: {
                                        isTorchOn.toggle()
                                    }, label: {
                                        Image(systemName: isTorchOn ? "bolt.circle" : "bolt.slash.circle")
                                            .font(.title)
                                    })
                                        .disabled(!checkForTorch() || isFrontCamera)
                                        .padding()
                                    if getFrontCameraAvailable() {
                                        Button(action: {
                                            isFrontCamera.toggle()
                                        }, label: {
                                            Image(systemName: MySymbols.changeCamera)
                                                .font(.title)
                                        })
                                        .disabled(isTorchOn)
                                            .padding()
                                    }
                                }
                                , alignment: .topTrailing)
                    }
#endif
            }
            Section(header: Text("Amount").font(.headline)) {
                MyDoubleStepperOptional(amount: $amount, description: "Amount", minAmount: 0, amountName: "", systemImage: MySymbols.amount)
                Picker(selection: $quantityUnitID, label: Label("Quantity unit", systemImage: "scalemass"), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits.filter({$0.active}), id:\.id) { pickerQU in
                        if let namePlural = pickerQU.namePlural {
                            Text("\(pickerQU.name) (\(namePlural))").tag(pickerQU.id as Int?)
                        } else {
                            Text("\(pickerQU.name)").tag(pickerQU.id as Int?)
                        }
                    }
                }).disabled(true)
            }
            
            Picker(selection: $storeID, label: Label("Store", systemImage: MySymbols.store).foregroundStyle(.primary), content: {
                Text("").tag(nil as Int?)
                ForEach(grocyVM.mdStores.filter({$0.active}), id:\.id) { grocyStore in
                    Text(grocyStore.name).tag(grocyStore.id as Int?)
                }
            })
            
            MyTextField(textToEdit: $note, description: "Note", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            
#if os(macOS)
            HStack{
                Button("Cancel") {
                    if isNewBarcode{
                        finishForm()
                    } else {
                        resetForm()
                    }
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    Task {
                        await saveBarcode()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
#endif
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

//struct MDBarcodeFormView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group{
//            NavigationView{
//                MDBarcodeFormView(isNewBarcode: true, productID: 1)
//            }
//            NavigationView{
//                MDBarcodeFormView(isNewBarcode: false, productID: 1, editBarcode: MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 3, amount: 1, storeID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note"))
//            }
//        }
//    }
//}
