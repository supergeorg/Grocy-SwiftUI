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
    
    @State private var barcode: String = ""
    @State private var amount: Int = 0
    @State private var quantityUnitID: String = ""
    @State private var shoppingLocationID: String = ""
    
    var isNewBarcode: Bool
    var productID: String
    var editBarcode: MDProductBarcode?
    
    private func saveBarcode() {
        let quID = quantityUnitID.isEmpty ? nil : quantityUnitID
        if isNewBarcode{
            let saveBarcode = MDProductBarcode(id: String(grocyVM.findNextID(.product_barcodes)), productID: productID, barcode: barcode, quID: quID, amount: String(amount), shoppingLocationID: shoppingLocationID, lastPrice: nil, rowCreatedTimestamp: Date().iso8601withFractionalSeconds, userfields: nil)
            grocyVM.postMDObject(object: .product_barcodes, content: saveBarcode)
        }
    }
    
    private func initForm() {
        barcode = editBarcode?.barcode ?? ""
        amount = Int(editBarcode?.amount ?? "") ?? 0
        quantityUnitID = editBarcode?.quID ?? ""
        shoppingLocationID = editBarcode?.shoppingLocationID ?? ""
    }
    
    var body: some View {
        #if os(macOS)
        content
        #elseif os(iOS)
        content
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
            TextField(LocalizedStringKey("str.md.barcode"), text: $barcode)
            Section(header: Text("str.md.barcode.amount".localized).font(.headline)) {
                MyIntStepper(amount: $amount, description: "str.md.barcode.amount", minAmount: 0, amountName: "", systemImage: "number.circle")
                Picker(selection: $quantityUnitID, label: Label("str.md.barcode.quantityUnit".localized, systemImage: "scalemass"), content: {
                    Text("").tag("")
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id)
                    }
                }).disabled(true)
            }
            Picker("str.md.barcode.shoppingLocation", selection: $shoppingLocationID, content: {
                ForEach(grocyVM.mdShoppingLocations, id:\.id) { grocyShoppingLocation in
                    Text(grocyShoppingLocation.name).tag(grocyShoppingLocation.id)
                }
            })
            #if os(macOS)
            HStack{
                Button("str.cancel") {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("str.save") {
                    saveBarcode()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
    }
}

struct MDBarcodeFormView_Previews: PreviewProvider {
    static var previews: some View {
        MDBarcodeFormView(isNewBarcode: true, productID: "1")
    }
}
