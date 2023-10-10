//
//  OpenFoodFactsFillProductView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 22.03.22.
//

import SwiftUI

struct OpenFoodFactsFillProductView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @ObservedObject var offVM: OpenFoodFactsViewModel = OpenFoodFactsViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var productName: String
    @State private var selectedProductName: String = ""
    @Binding var queuedBarcode: String
    
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
    @State private var isTorchOn = false
    @State private var isFrontCamera = false
    func handleScan(result: Result<CodeScannerView.ScanResult, CodeScannerView.ScanError>) {
        switch result {
        case .success(let code):
            scanBarcode = code.string
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
        queuedBarcode = offVM.offData?.code ?? ""
        finishForm()
    }
    
    let simulatedData = "20047559"
    
    var body: some View {
#if os(iOS)
        if productNames.count == 0 {
            CodeScannerView(
                codeTypes: getSavedCodeTypes().map{$0.type},
                scanMode: .once,
                simulatedData: simulatedData,
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
        List {
#if os(macOS)
            Text("Open Food Facts")
                .font(.title)
            HStack(alignment: .center) {
                MyTextField(textToEdit: $scanBarcode, description: "Barcode", isCorrect: Binding.constant(true), leadingIcon: MySymbols.barcodeScan)
                Button(action: {
                    offVM.updateBarcode(barcode: scanBarcode)
                }, label: {
                    Text("Search")
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
                                Text("Product name")
                                if selectedProductName.isEmpty {
                                    Text("A name is required")
                                        .font(.caption)
                                        .foregroundStyle(Color.red)
                                } else if !isNameCorrect {
                                    Text("Name already exists")
                                        .font(.caption)
                                        .foregroundStyle(Color.red)
                                }
                            }
                        }
                    })
                    .onChange(of: selectedProductName) {
                        isNameCorrect = checkNameCorrect()
                    }
                }
            } else if let errorMessage = offVM.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundStyle(.red)
            }
#if os(macOS)
            if !selectedProductName.isEmpty {
                Button(action: confirmData, label: {
                    Label("Confirm", systemImage: MySymbols.save)
                        .labelStyle(.titleAndIcon)
                })
                .disabled(!isNameCorrect || selectedProductName.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
#endif
        }
        .navigationTitle("Open Food Facts")
#if os(iOS)
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel, action: finishForm)
                    .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(action: confirmData, label: {
                    Label("Confirm", systemImage: MySymbols.save)
                        .labelStyle(.titleAndIcon)
                })
                .disabled(!isNameCorrect || selectedProductName.isEmpty)
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
