//
//  QuickScanModeView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 06.01.21.
//

import SwiftUI

enum QuickScanMode {
    case consume, markAsOpened, purchase
    
    func getDescription() -> LocalizedStringKey {
        switch self {
        case .consume:
            return LocalizedStringKey("str.quickScan.consume")
        case .markAsOpened:
            return LocalizedStringKey("str.quickScan.markAsOpened")
        case .purchase:
            return LocalizedStringKey("str.quickScan.purchase")
        }
    }
}

struct QuickScanModeView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("devMode") private var devMode: Bool = false
    
    @State private var flashOn: Bool = false
    @AppStorage("isFrontCamera") private var isFrontCamera: Bool = false
    @State private var quickScanMode: QuickScanMode = .consume
    
    @State private var activeSheet: QSActiveSheet?
    
    @State private var firstInSession: Bool = true
    
    @State private var recognizedBarcode: MDProductBarcode? = nil
    @State private var notRecognizedBarcode: String? = nil
    
    @State private var toastTypeSuccess: QSToastTypeSuccess?
    @State private var infoString: String?
    
    @State private var lastConsumeLocationID: Int?
    @State private var lastPurchaseDueDate: Date = Date()
    @State private var lastPurchaseShoppingLocationID: Int?
    @State private var lastPurchaseLocationID: Int?
    
    @State private var isScanPaused: Bool = false
    func checkScanPause() {
        isScanPaused = (activeSheet != nil)
    }
    
    func updateData() {
        grocyVM.requestData(objects: [.product_barcodes, .products, .locations, .shopping_locations])
    }
    
    func searchForBarcode(barcodeString: String) -> MDProductBarcode? {
        return grocyVM.mdProductBarcodes.first(where: {$0.barcode == barcodeString})
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        switch result {
        case .success(let barcodeString):
            if let barcode = searchForBarcode(barcodeString: barcodeString) {
                recognizedBarcode = barcode
                activeSheet = .input
            } else {
                notRecognizedBarcode = barcodeString
                activeSheet = .selectProduct
            }
        case .failure(let error):
            print(error)
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.count == 0 && grocyVM.failedToLoadAdditionalObjects.count == 0 {
            bodyContent
        } else {
            ServerOfflineView()
                .navigationTitle(LocalizedStringKey("str.nav.quickScan"))
        }
    }
    
    var modePicker: some View {
        HStack{
            Picker(selection: $quickScanMode, label: Label(quickScanMode.getDescription(), systemImage: MySymbols.menuPick), content: {
                Label(QuickScanMode.consume.getDescription(), systemImage: MySymbols.consume)
                    .labelStyle(IconAboveTextLabelStyle())
                    .tag(QuickScanMode.consume)
                Label(QuickScanMode.markAsOpened.getDescription(), systemImage: MySymbols.open)
                    .labelStyle(IconAboveTextLabelStyle())
                    .tag(QuickScanMode.markAsOpened)
                Label(QuickScanMode.purchase.getDescription(), systemImage: MySymbols.purchase)
                    .labelStyle(IconAboveTextLabelStyle())
                    .tag(QuickScanMode.purchase)
            })
            .pickerStyle(SegmentedPickerStyle())
            Spacer()
            Button(action: {
                flashOn.toggle()
                toggleTorch(on: flashOn)
            }, label: {
                Image(systemName: flashOn ? "bolt.circle" : "bolt.slash.circle")
                    .font(.title)
            })
            .disabled(!checkForTorch())
            if getFrontCameraAvailable() {
                Button(action: {
                    isFrontCamera.toggle()
                }, label: {
                    Image(systemName: MySymbols.changeCamera)
                        .font(.title)
                })
            }
        }
    }
    
    var bodyContent: some View {
        CodeScannerView(codeTypes: getSavedCodeTypes().map{$0.type}, scanMode: .continuous, simulatedData: "5901234123457", isPaused: $isScanPaused, isFrontCamera: $isFrontCamera, completion: self.handleScan)
            .overlay(modePicker, alignment: .top)
            .sheet(item: $activeSheet) { item in
                switch item {
                case .input:
                    QuickScanModeInputView(quickScanMode: $quickScanMode, productBarcode: $recognizedBarcode, toastTypeSuccess: $toastTypeSuccess, infoString: $infoString, lastConsumeLocationID: $lastConsumeLocationID, lastPurchaseDueDate: $lastPurchaseDueDate, lastPurchaseShoppingLocationID: $lastPurchaseShoppingLocationID, lastPurchaseLocationID: $lastPurchaseLocationID)
                case .selectProduct:
                    QuickScanModeSelectProductView(barcode: notRecognizedBarcode, toastTypeSuccess: $toastTypeSuccess)
                }
            }
            .toast(item: $toastTypeSuccess, isSuccess: Binding.constant(toastTypeSuccess != QSToastTypeSuccess.invalidBarcode), content: { item in
                switch item {
                case .successQSAddProduct:
                    Label("str.quickScan.add.product.add.success", systemImage: MySymbols.success)
                case .successQSConsume:
                    Label(LocalizedStringKey("str.stock.consume.product.consume.success \(infoString ?? "")"), systemImage: MySymbols.success)
                case .successQSOpen:
                    Label(LocalizedStringKey("str.stock.consume.product.open.success \(infoString ?? "")"), systemImage: MySymbols.success)
                case .successQSPurchase:
                    Label(LocalizedStringKey("str.stock.buy.product.buy.success \(infoString ?? "")"), systemImage: MySymbols.success)
                case .invalidBarcode:
                    Label(LocalizedStringKey("str.quickScan.barcode.invalid"), systemImage: "barcode")
                }
            })
            .onAppear(perform: {
                grocyVM.requestData(objects: [.product_barcodes, .products, .locations, .shopping_locations, .quantity_units], additionalObjects: [.stock, .system_config], ignoreCached: false)
            })
            .onChange(of: activeSheet, perform: {newItem in
                checkScanPause()
            })
    }
}

struct QuickScanModeView_Previews: PreviewProvider {
    static var previews: some View {
        QuickScanModeView()
    }
}
