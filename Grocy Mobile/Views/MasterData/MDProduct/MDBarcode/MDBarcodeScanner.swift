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
    
    @State private var isShowingScanner = false

    var body: some View {
#if os(iOS)
        Button(action: {
            isShowingScanner.toggle()
        }, label: {
            Image(systemName: MySymbols.barcodeScan)
        })
        .sheet(isPresented: $isShowingScanner) {
            CodeScannerSheetView { result in
                barcode = result.value
            }
        }
#else
        Text("Not available on this platform.")
#endif
    }
}

#Preview {
    MDBarcodeScanner(barcode: Binding.constant(""))
}
