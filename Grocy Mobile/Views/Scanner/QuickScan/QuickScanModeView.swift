//
//  QuickScanModeView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 06.01.21.
//

import AVFoundation
import SwiftData
import SwiftUI
import Vision

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
    @Environment(\.openURL) private var openURL

    @Query var mdProductBarcodes: MDProductBarcodes
    @Query var mdProducts: MDProducts
    @Query var mdChores: MDChores

    @AppStorage("quickScanActionAfterAdd") private var quickScanActionAfterAdd: Bool = false
    #if os(iOS)
        @AppStorage("useLegacyScanner") private var useLegacyScanner: Bool = false
    #endif

    @State private var isTorchOn: Bool = false
    @AppStorage("isFrontCamera") private var isFrontCamera: Bool = false
    @State private var quickScanMode: QuickScanMode = .consume

    @State private var qsActiveSheet: QSActiveSheet?

    //    @State private var firstInSession: Bool = true

    @State private var showDemoGrocyCode: Bool = false

    @State var recognizedBarcode: MDProductBarcode? = nil
    @State var newRecognizedBarcode: MDProductBarcode? = nil
    @State var recognizedGrocyCode: GrocyCode? = nil
    @State var notRecognizedBarcode: String? = nil

    @State private var cameraUnauthorized: Bool = false

    //    @State private var lastConsumeLocationID: Int?
    //    @State private var lastPurchaseDueDate: Date = .init()
    //    @State private var lastPurchaseStoreID: Int?
    //    @State private var lastPurchaseLocationID: Int?

    @State private var isScanPaused: Bool = false
    func checkScanPause() {
        isScanPaused = (qsActiveSheet != nil)
    }

    // For realizing keyboard entry (e.g. external Barcode Scanner)
    @State private var scannedCode = ""
    @FocusState private var isFocused: Bool

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
        } else if codeComponents.count == 3, codeComponents[0] == "grcy", codeComponents[1] == "c", let choreID = Int(codeComponents[2]) {
            return GrocyCode(entityType: .chore, entityID: choreID, stockID: nil)
        } else {
            return nil
        }
    }
    #if os(iOS)
        func searchForBarcodeLegacy(barcode: CodeScannerViewLegacy.ScanResult) -> MDProductBarcode? {
            if barcode.type == .ean13 {
                return mdProductBarcodes.first(where: { $0.barcode.hasSuffix(barcode.string) })
            } else {
                return mdProductBarcodes.first(where: { $0.barcode == barcode.string })
            }
        }

        func handleScanLegacy(result: Result<CodeScannerViewLegacy.ScanResult, CodeScannerViewLegacy.ScanError>) {
            switch result {
            case .success(let barcode):
                if let grocyCode = searchForGrocyCode(barcodeString: barcode.string) {
                    recognizedBarcode = nil
                    recognizedGrocyCode = grocyCode
                    notRecognizedBarcode = nil
                    qsActiveSheet = .grocyCode
                } else if let foundBarcode = searchForBarcodeLegacy(barcode: barcode) {
                    recognizedBarcode = foundBarcode
                    recognizedGrocyCode = nil
                    notRecognizedBarcode = nil
                    qsActiveSheet = .barcode
                } else {
                    recognizedBarcode = nil
                    recognizedGrocyCode = nil
                    notRecognizedBarcode = barcode.string
                    qsActiveSheet = .selectProduct
                }
            case .failure(let error):
                GrocyLogger.error("Barcode scan failed. \(error)")
            }
        }

        func searchForBarcode(barcode: CodeResult) -> MDProductBarcode? {
            if barcode.type == .ean13 {
                return mdProductBarcodes.first(where: { $0.barcode.hasSuffix(barcode.value) })
            } else {
                return mdProductBarcodes.first(where: { $0.barcode == barcode.value })
            }
        }

        func handleScan(result: CodeResult) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            if let grocyCode = searchForGrocyCode(barcodeString: result.value) {
                recognizedBarcode = nil
                recognizedGrocyCode = grocyCode
                qsActiveSheet = .grocyCode
            } else if let foundBarcode = searchForBarcode(barcode: result) {
                recognizedBarcode = foundBarcode
                recognizedGrocyCode = nil
                qsActiveSheet = .barcode
            } else {
                notRecognizedBarcode = result.value
                qsActiveSheet = .selectProduct
            }
        }

        func handleKeyPress(characters: String) {
            if characters == "\n" || characters == "\r" {
                // Barcode scanners typically send Enter/Return after the code
                handleScan(result: CodeResult(value: scannedCode, type: .qr))
                scannedCode = ""
            } else {
                scannedCode += characters
            }
        }
    #endif

    var product: MDProduct? {
        if let grocyCode = recognizedGrocyCode, grocyCode.entityType == .product {
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
                .padding()
                .navigationTitle("Quick Scan")
        }
    }

    #if os(iOS)
        @ViewBuilder
        private func barcodeScanner() -> some View {
            if useLegacyScanner {
                CodeScannerViewLegacy(
                    codeTypes: getSavedCodeTypesLegacy().map { $0.type },
                    scanMode: .continuous,
                    simulatedData: showDemoGrocyCode ? "grcy:p:1:62596f7263051" : "5901234123457",
                    isTorchOn: $isTorchOn,
                    isPaused: $isScanPaused,
                    isFrontCamera: $isFrontCamera,
                    completion: self.handleScanLegacy
                )
                .onAppear { isScanPaused = false }
                .onDisappear { isScanPaused = true }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    isScanPaused = true
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    isScanPaused = false
                }
            } else {
                CodeScannerView(isPaused: $isScanPaused, onCodeFound: handleScan, onAuthorizationFailed: { cameraUnauthorized = true })
                    .onAppear { isScanPaused = false }
                    .onDisappear { isScanPaused = true }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                        isScanPaused = true
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        isScanPaused = false
                    }
            }
        }
    #endif

    var bodyContent: some View {
        #if os(iOS)
            barcodeScanner()
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
                .alert("Camera Access Required", isPresented: $cameraUnauthorized) {
                    Button("Open Settings") {
                        openURL(URL(string: UIApplication.openSettingsURLString)!)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Please enable camera access in Settings to scan barcodes.")
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Picker(
                            selection: $quickScanMode,
                            label: Label("Quick Scan", systemImage: MySymbols.menuPick),
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
                        if getFrontCameraAvailable() && useLegacyScanner {
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
                                    Image(systemName: MySymbols.quickScanPause)
                                }
                            )
                        }
                    }
                }
                .onChange(of: newRecognizedBarcode?.id) {
                    print("New recognized barcode: \(String(describing: newRecognizedBarcode?.id))")
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
                .onChange(
                    of: isTorchOn,
                    {
                        if !useLegacyScanner {
                            toggleTorch(state: isTorchOn)
                        }
                    }
                )
                .focusable()
                .focused($isFocused)
                .onKeyPress { press in
                    handleKeyPress(characters: press.characters)
                    return .handled
                }
                .onAppear {
                    isFocused = true
                }
                .onDisappear {
                    isFocused = false
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
                        isPopup: true
                    )
                case .markAsOpened:
                    ConsumeProductView(
                        directProductToConsumeID: product.id,
                        directStockEntryID: recognizedGrocyCode?.stockID,
                        barcode: recognizedBarcode,
                        consumeType: .open,
                        quickScan: true,
                        isPopup: true
                    )
                case .purchase:
                    PurchaseProductView(
                        directProductToPurchaseID: product.id,
                        barcode: recognizedBarcode,
                        quickScan: true,
                        isPopup: true
                    )
                }
            } else if let grocyCode = recognizedGrocyCode, grocyCode.entityType == .chore {
                ChoreTrackingView(mdChoreID: grocyCode.entityID)
            }  else {
                EmptyView()
            }
        case .selectProduct:
            QuickScanModeSelectProductView(
                barcode: notRecognizedBarcode,
                newRecognizedBarcode: $newRecognizedBarcode
            )

        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        QuickScanModeView()
    }
}
