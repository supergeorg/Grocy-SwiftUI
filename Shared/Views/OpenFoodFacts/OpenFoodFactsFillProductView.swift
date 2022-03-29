//
//  OpenFoodFactsFillProductView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 22.03.22.
//

import SwiftUI

struct OpenFoodFactsFillProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    @ObservedObject var offVM: OpenFoodFactsViewModel = OpenFoodFactsViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var productName: String
    @State private var selectedProductName: String = ""
    
    @State private var scanBarcode: String = ""
    
    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundProduct = grocyVM.mdProducts.first(where: {$0.name == selectedProductName})
        return (foundProduct == nil)
    }
    
    var productNames: [String: String] {
        if let offData = offVM.offData {
            let allProductNames = [
                "generic": offData.product.productName,
                "en": offData.product.productNameEn?.isEmpty ?? true ? nil : offData.product.productNameEn,
                "de": offData.product.productNameDe?.isEmpty ?? true ? nil : offData.product.productNameDe,
                "fr": offData.product.productNameFr?.isEmpty ?? true ? nil : offData.product.productNameFr,
                "pl": offData.product.productNamePl?.isEmpty ?? true ? nil : offData.product.productNamePl,
                "nl": offData.product.productNameNl?.isEmpty ?? true ? nil : offData.product.productNameNl
            ]
            return allProductNames.compactMapValues({ $0 })
        } else {
            return [:]
        }
    }
    
#if os(iOS)
    @State private var isScannerFlash = false
    @State private var isScannerFrontCamera = false
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        switch result {
        case .success(let code):
            scanBarcode = code
            offVM.updateBarcode(barcode: scanBarcode)
        case .failure(let error):
            grocyVM.postLog("Scanning open food facts barcode failed. \(error)", type: .error)
        }
    }
#endif
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
#endif
    }
    
    func confirmData() {
        productName = selectedProductName
        finishForm()
    }
    
    let simulatedData = "20047559"
    
    var body: some View {
#if os(iOS)
        if productNames.count == 0 {
            CodeScannerView(codeTypes: getSavedCodeTypes().map{$0.type}, scanMode: .once, simulatedData: simulatedData, isFrontCamera: $isScannerFrontCamera, completion: self.handleScan)
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
        List {
#if os(macOS)
            Text("Open Food Facts")
                .font(.title)
            HStack(alignment: .center) {
                MyTextField(textToEdit: $scanBarcode, description: "str.md.barcode", isCorrect: Binding.constant(true), leadingIcon: MySymbols.barcodeScan)
                Button(action: {
                    offVM.updateBarcode(barcode: scanBarcode)
                }, label: {
                    Text(LocalizedStringKey("str.search"))
                })
            }
#endif
            if productNames.count > 0 {
                if let imageLink = offVM.offData?.product.imageURL, let imageURL = URL(string: imageLink) {
                    AsyncImage(url: imageURL, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(Color.white)
                    }, placeholder: {
                        ProgressView()
                    })
                    .frame(maxWidth: 200.0, maxHeight: 200.0)
                }
                Section() {
                    Picker(selection: $selectedProductName, content: {
                        ForEach(productNames.sorted(by: >), id: \.key) { key, value in
                            Text("\(value) (\(key))").tag(value)
                        }
                    }, label: {
                        HStack{
                            Image(systemName: "tag")
                            VStack(alignment: .leading){
                                Text(LocalizedStringKey("str.md.product.name"))
                                if selectedProductName.isEmpty {
                                    Text(LocalizedStringKey("str.md.product.name.required"))
                                        .font(.caption)
                                        .foregroundColor(Color.red)
                                } else if !isNameCorrect {
                                    Text("str.md.product.name.exists")
                                        .font(.caption)
                                        .foregroundColor(Color.red)
                                }
                            }
                        }
                    })
                    .onChange(of: selectedProductName, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                }
            }
#if os(macOS)
            if !selectedProductName.isEmpty {
                Button(action: confirmData, label: {
                    Label(LocalizedStringKey("str.confirm"), systemImage: MySymbols.save)
                        .labelStyle(.titleAndIcon)
                })
                .disabled(!isNameCorrect)
                .keyboardShortcut(.defaultAction)
            }
#endif
        }
        .navigationTitle("Open Food Facts")
#if os(iOS)
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button(LocalizedStringKey("str.cancel"), role: .cancel, action: finishForm)
                    .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(action: confirmData, label: {
                    Label(LocalizedStringKey("str.confirm"), systemImage: MySymbols.save)
                        .labelStyle(.titleAndIcon)
                })
                .disabled(!isNameCorrect)
                .keyboardShortcut(.defaultAction)
            }
        })
#endif
    }
}

//struct OpenFoodFactsFillProductView_Previews: PreviewProvider {
//    static var previews: some View {
//        OpenFoodFactsFillProductView()
//    }
//}
