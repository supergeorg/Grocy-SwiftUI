//
//  MDBarcodeScanner.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 24.10.23.
//

import SwiftUI

struct MDBarcodeScanner: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Binding var barcode: String
    
    @State private var isTorchOn = false
    @State private var isFrontCamera = false
    @State private var isShowingScanner = false
    
#if os(iOS)
    func handleScan(result: Result<CodeScannerView.ScanResult, CodeScannerView.ScanError>) {
        self.isShowingScanner = false
        switch result {
        case .success(let code):
            barcode = code.string
        case .failure(let error):
            //            GrocyLogger.error("Scanning barcode failed. \(error)")
            print("Scanning barcode failed. \(error)")
        }
    }
#endif
    
    var body: some View {
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
                }, alignment: .topTrailing)
        }
#else
        Text("Not implemented on this platform.")
#endif
    }
}

#Preview {
    MDBarcodeScanner(barcode: Binding.constant(""))
}
