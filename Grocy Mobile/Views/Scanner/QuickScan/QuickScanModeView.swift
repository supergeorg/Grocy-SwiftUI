//
//  QuickScanModeView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 06.01.21.
//

import SwiftUI
import SwiftData
import AVFoundation

enum QuickScanMode {
    case consume, markAsOpened, purchase
}

enum QSActiveSheet: Identifiable {
    case barcode, grocyCode, selectProduct
    
    var id: Int {
        hashValue
    }
}

struct QuickScanModeView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDProductBarcode.id, order: .forward) var mdProductBarcodes: MDProductBarcodes
    
    @AppStorage("devMode") private var devMode: Bool = false
    @AppStorage("quickScanActionAfterAdd") private var quickScanActionAfterAdd: Bool = false
    
    @State private var isTorchOn: Bool = false
    @AppStorage("isFrontCamera") private var isFrontCamera: Bool = false
    @State private var quickScanMode: QuickScanMode = .consume
    
    @State private var qsActiveSheet: QSActiveSheet?
    
    @State private var firstInSession: Bool = true
    
    @State private var showDemoGrocyCode: Bool = false
    
    @State var recognizedBarcode: MDProductBarcode? = nil
    @State var newRecognizedBarcode: MDProductBarcode? = nil
    @State var recognizedGrocyCode: GrocyCode? = nil
    @State var notRecognizedBarcode: String? = nil
    
    @State private var lastConsumeLocationID: Int?
    @State private var lastPurchaseDueDate: Date = .init()
    @State private var lastPurchaseStoreID: Int?
    @State private var lastPurchaseLocationID: Int?
    
    @State private var isScanPaused: Bool = false
    func checkScanPause() {
        isScanPaused = (qsActiveSheet != nil)
    }
    
    private let dataToUpdate: [ObjectEntities] = [
        .product_barcodes,
        .products,
        .locations,
        .shopping_locations,
        .quantity_units,
        .quantity_unit_conversions,
    ]
    private let additionalDataToUpdate: [AdditionalEntities] = [
        .stock,
        .system_config,
    ]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    func searchForGrocyCode(barcodeString: String) -> GrocyCode? {
        let codeComponents = barcodeString.components(separatedBy: ":")
        if codeComponents.count >= 3,
           codeComponents[0] == "grcy",
           codeComponents[1] == "p",
           let productID = Int(codeComponents[2])
        {
            let stockID: String? = codeComponents.count == 4 ? codeComponents[3] : nil
            return GrocyCode(entityType: .product, entityID: productID, stockID: stockID)
        } else {
            return nil
        }
    }
    #if os(iOS)
    func searchForBarcode(barcode: CodeScannerView.ScanResult) -> MDProductBarcode? {
        if barcode.type == .ean13 {
            return mdProductBarcodes.first(where: { $0.barcode.hasSuffix(barcode.string) })
        } else {
            return mdProductBarcodes.first(where: { $0.barcode == barcode.string })
        }
    }
    
    func handleScan(result: Result<CodeScannerView.ScanResult, CodeScannerView.ScanError>) {
        switch result {
        case .success(let barcode):
            if let grocyCode = searchForGrocyCode(barcodeString: barcode.string) {
                recognizedGrocyCode = grocyCode
                qsActiveSheet = .grocyCode
            } else if let foundBarcode = searchForBarcode(barcode: barcode) {
                recognizedBarcode = foundBarcode
                qsActiveSheet = .barcode
            } else {
                notRecognizedBarcode = barcode.string
                qsActiveSheet = .selectProduct
            }
        case .failure(let error):
            //            grocyVM.postLog("Barcode scan failed. \(error)", type: .error)
            print("Barcode scan failed. \(error)")
        }
    }
    #endif
    
    var body: some View {
        if grocyVM.failedToLoadObjects.count == 0 && grocyVM.failedToLoadAdditionalObjects.count == 0 {
            bodyContent
        } else {
            ServerProblemView()
                .navigationTitle("Quick-Scan")
        }
    }
    
    var modePicker: some View {
        HStack {
            Picker(selection: $quickScanMode, label: Label("Quick-Scan Mode", systemImage: MySymbols.menuPick), content: {
                Label("Consume", systemImage: MySymbols.consume)
                    .labelStyle(.titleAndIcon)
                    .tag(QuickScanMode.consume)
                Label("Open", systemImage: MySymbols.open)
                    .labelStyle(.titleAndIcon)
                    .tag(QuickScanMode.markAsOpened)
                Label("Purchase", systemImage: MySymbols.purchase)
                    .labelStyle(.titleAndIcon)
                    .tag(QuickScanMode.purchase)
            })
            .pickerStyle(.segmented)
            Spacer()
            Button(action: {
                isTorchOn.toggle()
            }, label: {
                Image(systemName: isTorchOn ? "bolt.circle" : "bolt.slash.circle")
                    .font(.title)
            })
            .disabled(!checkForTorch() || isFrontCamera)
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
            if isScanPaused {
                Button(action: {
                    qsActiveSheet = nil
                }, label: {
                    Image(systemName: "pause.rectangle")
                        .font(.title)
                })
            }
        }
        .padding(.vertical)
        .animation(.default, value: isScanPaused)
    }
    
    var bodyContent: some View {
#if os(iOS)
        CodeScannerView(
            codeTypes: getSavedCodeTypes().map { $0.type },
            scanMode: .continuous,
            simulatedData: showDemoGrocyCode ? "grcy:p:1:62596f7263051" : "5901234123457",
            isTorchOn: $isTorchOn,
            isPaused: $isScanPaused,
            isFrontCamera: $isFrontCamera,
            completion: self.handleScan
        )
        .overlay(modePicker, alignment: .top)
        .sheet(item: $qsActiveSheet) { item in
            switch item {
            case .grocyCode:
                NavigationStack {
                    QuickScanModeInputView(
                        quickScanMode: $quickScanMode,
                        grocyCode: recognizedGrocyCode,
                        lastConsumeLocationID: $lastConsumeLocationID,
                        lastPurchaseDueDate: $lastPurchaseDueDate,
                        lastPurchaseStoreID: $lastPurchaseStoreID,
                        lastPurchaseLocationID: $lastPurchaseLocationID
                    )
                }
            case .barcode:
                NavigationStack {
                    QuickScanModeInputView(
                        quickScanMode: $quickScanMode,
                        productBarcode: recognizedBarcode,
                        lastConsumeLocationID: $lastConsumeLocationID,
                        lastPurchaseDueDate: $lastPurchaseDueDate,
                        lastPurchaseStoreID: $lastPurchaseStoreID,
                        lastPurchaseLocationID: $lastPurchaseLocationID
                    )
                }
            case .selectProduct:
                NavigationStack {
                    QuickScanModeSelectProductView(
                        barcode: notRecognizedBarcode,
                        qsActiveSheet: $qsActiveSheet,
                        newRecognizedBarcode: $newRecognizedBarcode
                    )
                }
            }
        }
        .task {
            Task {
                await updateData()
            }
        }
        .onChange(of: newRecognizedBarcode?.id) {
            DispatchQueue.main.async {
                if quickScanActionAfterAdd {
                    recognizedBarcode = newRecognizedBarcode
                    qsActiveSheet = .barcode
                    checkScanPause()
                }
            }
        }
        .onChange(of: qsActiveSheet) {
            DispatchQueue.main.async {
                checkScanPause()
            }
        }
#else
        Text("Not available on this platform.")
#endif
    }
}

struct QuickScanModeView_Previews: PreviewProvider {
    static var previews: some View {
        QuickScanModeView()
    }
}
