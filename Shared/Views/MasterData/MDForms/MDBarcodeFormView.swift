//
//  MDBarcodeFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 03.12.20.
//

import SwiftUI

struct MDBarcodeFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var barcode: String = ""
    @State private var amount: Int?
    @State private var quantityUnitID: String?
    @State private var shoppingLocationID: String?
    @State private var note: String = ""
    
    var isNewBarcode: Bool
    var productID: String
    var editBarcode: MDProductBarcode?
    
    @Binding var toastType: MDToastType?
    
    @State var isBarcodeCorrect: Bool = false
    private func checkBarcodeCorrect() -> Bool {
        // check if EAN8 or EAN13, or PZN 8/9
        return (Int(barcode) != nil) && (barcode.count == 8 || barcode.count == 13 || barcode.count == 9)
    }
    
    private var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productID})
    }
    
    private func resetForm() {
        barcode = editBarcode?.barcode ?? ""
        if let doubleAmount = Double(editBarcode?.amount ?? "") {
            amount = Int(doubleAmount)
        } else {amount = nil}
        quantityUnitID = editBarcode?.quID ?? product?.quIDPurchase
        shoppingLocationID = editBarcode?.shoppingLocationID
        note = editBarcode?.note ?? ""
        isBarcodeCorrect = checkBarcodeCorrect()
    }
    
    private func updateData() {
        grocyVM.requestData(objects: [.product_barcodes])
    }
    
    private func finishForm() {
        #if os(iOS)
        presentationMode.wrappedValue.dismiss()
        #elseif os(macOS)
        if isNewBarcode {
            NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        }
        #endif
    }
    
    private func saveBarcode() {
        let amountStr = amount != nil ? String(amount!) : nil
        let saveBarcode = MDProductBarcode(id: isNewBarcode ? String(grocyVM.findNextID(.product_barcodes)) : editBarcode?.id ?? "", productID: productID, barcode: barcode, quID: quantityUnitID, amount: amountStr, shoppingLocationID: shoppingLocationID, lastPrice: nil, rowCreatedTimestamp: isNewBarcode ? Date().iso8601withFractionalSeconds : editBarcode?.rowCreatedTimestamp ?? "", note: note, userfields: nil)
        if isNewBarcode{
            grocyVM.postMDObject(object: .product_barcodes, content: saveBarcode, completion: { result in
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
            if let id = editBarcode?.id {
                grocyVM.putMDObjectWithID(object: .product_barcodes, id: id, content: saveBarcode, completion: { result in
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
    }
    
    #if os(iOS)
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
        #if os(macOS)
        ScrollView {
            content
                .padding()
        }
        #elseif os(iOS)
        content
            .navigationTitle(isNewBarcode ? LocalizedStringKey("str.md.barcode.new") : LocalizedStringKey("str.md.barcode.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewBarcode {
                        Button(LocalizedStringKey("str.cancel")) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("str.md.barcode.save")) {
                        saveBarcode()
                        presentationMode.wrappedValue.dismiss()
                    }.disabled(barcode.isEmpty)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    // Back not shown without it
                    if !isNewBarcode{
                        Text("")
                    }
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
                MyTextField(textToEdit: $barcode, description: "str.md.barcode.barcode", isCorrect: $isBarcodeCorrect, leadingIcon: MySymbols.barcode, isEditing: true, emptyMessage: "str.md.barcode.barcode.required", errorMessage: "str.md.barcode.barcode.invalid", helpText: nil)
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
                    CodeScannerView(codeTypes: [.ean8, .ean13, .code39], scanMode: .once, simulatedData: "5901234123457", completion: self.handleScan)
                }
                #endif
            }
            Section(header: Text(LocalizedStringKey("str.md.barcode.amount")).font(.headline)) {
                MyIntStepperOptional(amount: $amount, description: "str.md.barcode.amount", minAmount: 0, amountName: "", systemImage: MySymbols.amount)
                Picker(selection: $quantityUnitID, label: Label(LocalizedStringKey("str.md.barcode.quantityUnit"), systemImage: "scalemass"), content: {
                    Text("").tag(nil as String?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id as String?)
                    }
                }).disabled(true)
            }

            Picker(selection: $shoppingLocationID, label: Label(LocalizedStringKey("str.md.barcode.shoppingLocation"), systemImage: MySymbols.shoppingLocation).foregroundColor(.primary), content: {
                ForEach(grocyVM.mdShoppingLocations, id:\.id) { grocyShoppingLocation in
                    Text(grocyShoppingLocation.name).tag(grocyShoppingLocation.id as String?)
                }
            })
            
            MyTextField(textToEdit: $note, description: "str.md.barcode.note", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description, isEditing: true)
            
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
                grocyVM.requestData(objects: [.product_barcodes], ignoreCached: false)
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
                MDBarcodeFormView(isNewBarcode: true, productID: "1", toastType: Binding.constant(.successAdd))
            }
            NavigationView{
                MDBarcodeFormView(isNewBarcode: false, productID: "1", editBarcode: MDProductBarcode(id: "1", productID: "1", barcode: "1234567891011", quID: "3", amount: "1", shoppingLocationID: "1", lastPrice: "1", rowCreatedTimestamp: "ts", note: "note", userfields: nil), toastType: Binding.constant(.successAdd))
            }
        }
    }
}
