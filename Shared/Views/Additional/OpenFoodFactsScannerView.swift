//
//  OpenFoodFactsScannerView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 15.02.21.
//

import SwiftUI

struct OpenFoodFactsScannerView: View {
    @State private var scanBarcode: String = ""
    @State private var isShowingResult: Bool = false
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        switch result {
        case .success(let code):
            scanBarcode = code
            isShowingResult = true
        case .failure(let error):
            print("Scanning failed")
            print(error)
        }
    }
    
//    let simulatedData = "737628064502"
    let simulatedData = "20047559"
    
    var body: some View {
        // DOESNT WORK, https://stackoverflow.com/questions/67276205/swiftui-navigationlink-for-ios-14-5-not-working
        NavigationLink(destination: OpenFoodFactsView(barcode: scanBarcode), isActive: $isShowingResult) {
            CodeScannerView(codeTypes: getSavedCodeTypes().map{$0.type}, scanMode: .once, simulatedData: simulatedData, completion: self.handleScan)
        }
    }
}

//struct OpenFoodFactsScannerView_Previews: PreviewProvider {
//    static var previews: some View {
//        OpenFoodFactsScannerView()
//    }
//}
