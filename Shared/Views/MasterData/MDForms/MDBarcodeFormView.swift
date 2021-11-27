//
//  MDBarcodeFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 03.12.20.
//

import SwiftUI

struct MDBarcodeFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var barcode: String = ""
    @State private var amount: Double?
    @State private var quantityUnitID: Int?
    @State private var shoppingLocationID: Int?
    @State private var note: String = ""
    
    var isNewBarcode: Bool
    var productID: Int
    var editBarcode: MDProductBarcode?
    
    @Binding var toastType: MDToastType?
    
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
        shoppingLocationID = editBarcode?.shoppingLocationID
        note = editBarcode?.note ?? ""
        isBarcodeCorrect = checkBarcodeCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.product_barcodes]
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#endif
    }
    
    private func saveBarcode() {
        let saveBarcode = MDProductBarcode(id: isNewBarcode ? grocyVM.findNextID(.product_barcodes) : editBarcode!.id, productID: productID, barcode: barcode, quID: quantityUnitID, amount: amount, shoppingLocationID: shoppingLocationID, lastPrice: nil, rowCreatedTimestamp: isNewBarcode ? Date().iso8601withFractionalSeconds : editBarcode?.rowCreatedTimestamp ?? "", note: note)
        if isNewBarcode{
            grocyVM.postMDObject(object: .product_barcodes, content: saveBarcode, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog(message: "Barcode add successful. \(message)", type: .info)
                    toastType = .successAdd
                    resetForm()
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog(message: "Barcode add failed. \(error)", type: .info)
                    toastType = .failAdd
                }
            })
        } else {
            if let id = editBarcode?.id {
                grocyVM.putMDObjectWithID(object: .product_barcodes, id: id, content: saveBarcode, completion: { result in
                    switch result {
                    case let .success(message):
                        grocyVM.postLog(message: "Barcode edit successful. \(message)", type: .info)
                        toastType = .successEdit
                        updateData()
                        finishForm()
                    case let .failure(error):
                        grocyVM.postLog(message: "Barcode edit failed. \(error)", type: .info)
                        toastType = .failEdit
                    }
                })
            }
        }
    }
    
#if os(iOS)
    @State private var isScannerFlash = false
    @State private var isScannerFrontCamera = false
    @State private var isShowingScanner = false
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        self.isShowingScanner = false
        switch result {
        case .success(let code):
            barcode = code
        case .failure(let error):
            print("Scanning failed")
            print(error)
        }
    }
#endif
    
    var body: some View {
        content
            .navigationTitle(isNewBarcode ? LocalizedStringKey("str.md.barcode.new") : LocalizedStringKey("str.md.barcode.edit"))
#if os(iOS)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewBarcode {
                        Button(LocalizedStringKey("str.cancel")) {
                            finishForm()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("str.md.barcode.save")) {
                        saveBarcode()
                        finishForm()
                    }.disabled(!isBarcodeCorrect)
                }
            })
#endif
    }
    
    var content: some View {
        Form {
#if os(macOS)
            if isNewBarcode {
                HStack(alignment: .center){
                    Text(LocalizedStringKey("str.md.barcode.new"))
                        .font(.title)
                    Spacer()
                    Text(LocalizedStringKey("str.md.barcode.for \(product?.name ?? "PRODUCT")"))
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
#endif
            HStack{
                MyTextField(textToEdit: $barcode, description: "str.md.barcode.barcode", isCorrect: $isBarcodeCorrect, leadingIcon: MySymbols.barcode, emptyMessage: "str.md.barcode.barcode.required", errorMessage: "str.md.barcode.barcode.invalid", helpText: nil)
                    .onChange(of: barcode, perform: {newBC in
                        isBarcodeCorrect = checkBarcodeCorrect()
                    })
#if os(iOS)
                Button(action: {
                    isShowingScanner.toggle()
                }, label: {
                    Image(systemName: MySymbols.barcodeScan)
                })
                    .sheet(isPresented: $isShowingScanner) {
                        CodeScannerView(codeTypes: getSavedCodeTypes().map{$0.type}, scanMode: .once, simulatedData: "5901234123457", isFrontCamera: $isScannerFrontCamera, completion: self.handleScan)
                            .overlay(
                                HStack{
                                    Button(action: {
                                        isScannerFlash.toggle()
                                        toggleTorch(on: isScannerFlash)
                                    }, label: {
                                        Image(systemName: isScannerFlash ? "bolt.circle" : "bolt.slash.circle")
                                            .font(.title)
                                    })
                                        .disabled(!checkForTorch())
                                        .padding()
                                    if getFrontCameraAvailable() {
                                        Button(action: {
                                            isScannerFrontCamera.toggle()
                                        }, label: {
                                            Image(systemName: MySymbols.changeCamera)
                                                .font(.title)
                                        })
                                            .padding()
                                    }
                                }
                                , alignment: .topTrailing)
                    }
#endif
            }
            Section(header: Text(LocalizedStringKey("str.md.barcode.amount")).font(.headline)) {
                MyDoubleStepperOptional(amount: $amount, description: "str.md.barcode.amount", minAmount: 0, amountName: "", systemImage: MySymbols.amount)
                Picker(selection: $quantityUnitID, label: Label(LocalizedStringKey("str.md.barcode.quantityUnit"), systemImage: "scalemass"), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id as Int?)
                    }
                }).disabled(true)
            }
            
            Picker(selection: $shoppingLocationID, label: Label(LocalizedStringKey("str.md.barcode.shoppingLocation"), systemImage: MySymbols.shoppingLocation).foregroundColor(.primary), content: {
                Text("").tag(nil as Int?)
                ForEach(grocyVM.mdShoppingLocations, id:\.id) { grocyShoppingLocation in
                    Text(grocyShoppingLocation.name).tag(grocyShoppingLocation.id as Int?)
                }
            })
            
            MyTextField(textToEdit: $note, description: "str.md.barcode.note", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            
#if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    if isNewBarcode{
                        finishForm()
                    } else {
                        resetForm()
                    }
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveBarcode()
                }
                .keyboardShortcut(.defaultAction)
            }
#endif
        }
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: dataToUpdate, ignoreCached: false)
                resetForm()
                firstAppear = false
            }
        })
    }
}

struct MDBarcodeFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            NavigationView{
                MDBarcodeFormView(isNewBarcode: true, productID: 1, toastType: Binding.constant(.successAdd))
            }
            NavigationView{
                MDBarcodeFormView(isNewBarcode: false, productID: 1, editBarcode: MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 3, amount: 1, shoppingLocationID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note"), toastType: Binding.constant(.successAdd))
            }
        }
    }
}
