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
    
    @State private var barcode: String = ""
    @State private var amount: Int?
    @State private var quantityUnitID: String?
    @State private var shoppingLocationID: String?
    @State private var note: String = ""
    
    var isNewBarcode: Bool
    var productID: String
    var editBarcode: MDProductBarcode?
    
    private func saveBarcode() {
        let amountStr = amount != nil ? String(amount!) : nil
        let saveBarcode = MDProductBarcode(id: isNewBarcode ? String(grocyVM.findNextID(.product_barcodes)) : editBarcode?.id ?? "", productID: productID, barcode: barcode, quID: quantityUnitID, amount: amountStr, shoppingLocationID: shoppingLocationID, lastPrice: nil, rowCreatedTimestamp: isNewBarcode ? Date().iso8601withFractionalSeconds : editBarcode?.rowCreatedTimestamp ?? "", note: note, userfields: nil)
        if isNewBarcode{
            grocyVM.postMDObject(object: .product_barcodes, content: saveBarcode)
        } else {
            if let id = editBarcode?.id {
                grocyVM.putMDObjectWithID(object: .product_barcodes, id: id, content: saveBarcode)
            }
        }
    }
    
    private func resetForm() {
        barcode = editBarcode?.barcode ?? ""
        amount = Int(editBarcode?.amount ?? "")
        quantityUnitID = editBarcode?.quID
        shoppingLocationID = editBarcode?.shoppingLocationID
        note = editBarcode?.note ?? ""
    }
    
    private func updateData() {
        
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
        content
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
                    Button(LocalizedStringKey("str.md.save \("str.md.barcode".localized)")) {
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
            HStack(alignment: .center){
                Text(LocalizedStringKey("str.md.barcode.new"))
                    .font(.title)
                Spacer()
                Text(LocalizedStringKey("str.md.barcode.for \("pr")"))
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            #endif
            HStack{
                TextField(LocalizedStringKey("str.md.barcode"), text: $barcode)
                #if os(iOS)
                Button(action: {
                    isShowingScanner.toggle()
                }, label: {
                    Image(systemName: "barcode.viewfinder")
                })
                .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(codeTypes: [.ean8, .ean13], simulatedData: "5901234123457", completion: self.handleScan)
                }
                #endif
            }
            Section(header: Text(LocalizedStringKey("str.md.barcode.amount")).font(.headline)) {
                MyIntStepper(amount: $amount, description: "str.md.barcode.amount", minAmount: 0, amountName: "", systemImage: "number.circle")
                Picker(selection: $quantityUnitID, label: Label(LocalizedStringKey("str.md.barcode.quantityUnit"), systemImage: "scalemass"), content: {
                    Text("").tag(nil as String?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id as String?)
                    }
                }).disabled(true)
            }
            Picker(LocalizedStringKey("str.md.barcode.shoppingLocation"), selection: $shoppingLocationID, content: {
                ForEach(grocyVM.mdShoppingLocations, id:\.id) { grocyShoppingLocation in
                    Text(grocyShoppingLocation.name).tag(grocyShoppingLocation.id as String?)
                }
            })
            
            MyTextField(textToEdit: $note, description: "str.md.barcode.note", isCorrect: Binding.constant(true), leadingIcon: "text.justifyleft", isEditing: true)
            
            #if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveBarcode()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
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

struct MDBarcodeFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            NavigationView{
                MDBarcodeFormView(isNewBarcode: true, productID: "1")
            }
            NavigationView{
                MDBarcodeFormView(isNewBarcode: false, productID: "1", editBarcode: MDProductBarcode(id: "1", productID: "1", barcode: "1234567891011", quID: "3", amount: "1", shoppingLocationID: "1", lastPrice: "1", rowCreatedTimestamp: "ts", note: "note", userfields: nil))
            }
        }
    }
}
