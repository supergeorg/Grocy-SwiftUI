//
//  QuickScanModeView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 06.01.21.
//

import AVFoundation
import SwiftData
import SwiftUI

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
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts

    @AppStorage("devMode") private var devMode: Bool = false
    @AppStorage("quickScanActionAfterAdd") private var quickScanActionAfterAdd: Bool = false

    @State private var isTorchOn: Bool = false
    @AppStorage("isFrontCamera") private var isFrontCamera: Bool = false
    @State private var quickScanMode: QuickScanMode = .consume

    @State private var qsActiveSheet: QSActiveSheet?
    @State var actionFinished: Bool = false

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
                    recognizedBarcode = nil
                    recognizedGrocyCode = grocyCode
                    qsActiveSheet = .grocyCode
                } else if let foundBarcode = searchForBarcode(barcode: barcode) {
                    recognizedBarcode = foundBarcode
                    recognizedGrocyCode = nil
                    qsActiveSheet = .barcode
                } else {
                    notRecognizedBarcode = barcode.string
                    qsActiveSheet = .selectProduct
                }
            case .failure(let error):
                GrocyLogger.error("Barcode scan failed. \(error)")
            }
        }
    #endif
    
    var product: MDProduct? {
        if let grocyCode = recognizedGrocyCode {
            return mdProducts.first(where: { $0.id == grocyCode.entityID })
        } else if let productBarcode = recognizedBarcode {
            return mdProducts.first(where: { $0.id == productBarcode.productID })
        }
        return nil
    }

    var body: some View {
        if grocyVM.failedToLoadObjects.count == 0 && grocyVM.failedToLoadAdditionalObjects.count == 0 {
            bodyContent
                .ignoresSafeArea()
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
        } else {
            ServerProblemView()
                .navigationTitle("Quick-Scan")
        }
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
            .sheet(item: $qsActiveSheet) { item in
                NavigationStack {
                    sheetContent(for: item)
                }
            }
            .task {
                Task {
                    await updateData()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker(
                        selection: $quickScanMode,
                        label: Label("Quick-Scan Mode", systemImage: MySymbols.menuPick),
                        content: {
                            Label("Consume", systemImage: MySymbols.consume)
                                .labelStyle(.titleAndIcon)
                                .tag(QuickScanMode.consume)
                            Label("Open", systemImage: MySymbols.open)
                                .labelStyle(.titleAndIcon)
                                .tag(QuickScanMode.markAsOpened)
                            Label("Purchase", systemImage: MySymbols.purchase)
                                .labelStyle(.titleAndIcon)
                                .tag(QuickScanMode.purchase)
                        }
                    )
                    .pickerStyle(.menu)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(
                        action: {
                            isTorchOn.toggle()
                        },
                        label: {
                            Image(systemName: isTorchOn ? "bolt.circle" : "bolt.slash.circle")
                        }
                    )
                    .disabled(!checkForTorch() || isFrontCamera)
                    if getFrontCameraAvailable() {
                        Button(
                            action: {
                                isFrontCamera.toggle()
                            },
                            label: {
                                Image(systemName: MySymbols.changeCamera)
                            }
                        )
                        .disabled(isTorchOn)
                    }
                    if isScanPaused {
                        Button(
                            action: {
                                qsActiveSheet = nil
                            },
                            label: {
                                Image(systemName: "pause.rectangle")
                            }
                        )
                    }
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

    // Sheet content based on type
    @ViewBuilder
    private func sheetContent(for sheetType: QSActiveSheet) -> some View {
        switch sheetType {
        case .barcode, .grocyCode:
            if let product = product {
                switch quickScanMode {
                case .consume:
                    ConsumeProductView(
                        directProductToConsumeID: product.id,
                        directStockEntryID: recognizedGrocyCode?.stockID,
                        barcode: recognizedBarcode,
                        consumeType: .consume,
                        quickScan: true,
                        actionFinished: $actionFinished
                    )
                case .markAsOpened:
                    ConsumeProductView(
                        directProductToConsumeID: product.id,
                        directStockEntryID: recognizedGrocyCode?.stockID,
                        barcode: recognizedBarcode,
                        consumeType: .open,
                        quickScan: true,
                        actionFinished: $actionFinished
                    )
                case .purchase:
                    PurchaseProductView(
                        directProductToPurchaseID: product.id,
                        barcode: recognizedBarcode,
                        quickScan: true,
                        actionFinished: $actionFinished
                    )
                }
            } else {
                EmptyView()
            }
        case .selectProduct:
            QuickScanModeSelectProductView(
                barcode: notRecognizedBarcode,
                qsActiveSheet: $qsActiveSheet,
                newRecognizedBarcode: $newRecognizedBarcode
            )

        }
    }
}

#Preview {
    QuickScanModeView()
}
