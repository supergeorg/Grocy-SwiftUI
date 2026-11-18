////
////  CodeScannerView.swift
////  Grocy Mobile
////
////  Created by Georg Meißner on 08.11.25.
////

import AVFoundation
import SwiftUI
import Vision
import VisionKit

struct CodeResult: Hashable {
    var value: String
    var type: VNBarcodeSymbology? = nil
}

#if os(iOS)
    @MainActor
    struct CodeScannerView: UIViewControllerRepresentable {
        @Binding var isPaused: Bool
        var onCodeFound: ((CodeResult) -> Void)?
        var onAuthorizationFailed: (() -> Void)?
        var symbologies: [VNBarcodeSymbology]
        var recognizeDates: Bool = false

        init(
            isPaused: Binding<Bool> = .constant(false),
            onCodeFound: ((CodeResult) -> Void)? = nil,
            onAuthorizationFailed: (() -> Void)? = nil,
            symbologies: [VNBarcodeSymbology]? = nil,
            recognizeDates: Bool = false
        ) {
            self._isPaused = isPaused
            self.onCodeFound = onCodeFound
            self.onAuthorizationFailed = onAuthorizationFailed
            if let symbologies {
                self.symbologies = symbologies
            } else {
                self.symbologies = getSavedCodeTypes()
            }
            self.recognizeDates = recognizeDates
        }

        func makeUIViewController(context: Context) -> DataScannerViewController {
            var recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType> = []
            if self.symbologies.count > 0 {
                recognizedDataTypes.insert(.barcode(symbologies: self.symbologies))
            }
            if self.recognizeDates == true {
                recognizedDataTypes.insert(.text(textContentType: .dateTimeDuration))
            }
            let scannerViewController = DataScannerViewController(
                recognizedDataTypes: recognizedDataTypes,
                qualityLevel: .balanced,
                recognizesMultipleItems: false,
                isHighFrameRateTrackingEnabled: false,
                isHighlightingEnabled: true,
            )

            scannerViewController.delegate = context.coordinator

            // Check authorization before starting
            Task {
                let authorized = await context.coordinator.checkCameraAuthorization()
                if authorized {
                    try? scannerViewController.startScanning()
                } else {
                    onAuthorizationFailed?()
                }
            }

            return scannerViewController
        }

        var scannerAvailable: Bool {
            DataScannerViewController.isSupported && DataScannerViewController.isAvailable
        }

        func updateUIViewController(
            _ uiViewController: DataScannerViewController,
            context: Context
        ) {
            if isPaused && uiViewController.isScanning {
                uiViewController.stopScanning()
            } else if !isPaused && !uiViewController.isScanning {
                try? uiViewController.startScanning()
            }
        }

        static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
            uiViewController.stopScanning()
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, DataScannerViewControllerDelegate {
            var parent: CodeScannerView
            private var lastScanTime: Date = .distantPast
            private let debounceInterval: TimeInterval = 2.0

            init(_ parent: CodeScannerView) {
                self.parent = parent
            }

            func checkCameraAuthorization() async -> Bool {
                switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .authorized:
                    return true
                case .notDetermined:
                    return await AVCaptureDevice.requestAccess(for: .video)
                case .denied, .restricted:
                    return false
                @unknown default:
                    return false
                }
            }

            func dataScanner(
                _ dataScanner: DataScannerViewController,
                didAdd addedItems: [RecognizedItem],
                allItems: [RecognizedItem]
            ) {
                let currentTime = Date()
                guard currentTime.timeIntervalSince(lastScanTime) >= debounceInterval else {
                    return  // Skip if not enough time has passed since last scan
                }

                for item in addedItems {
                    switch item {
                    case .barcode(let code):
                        if let payload = code.payloadStringValue, let callback = parent.onCodeFound {
                            lastScanTime = currentTime
                            callback(CodeResult(value: payload, type: code.observation.symbology))
                        }
                    case .text(let text):
                        if let callback = parent.onCodeFound {
                            lastScanTime = currentTime
                            callback(CodeResult(value: text.transcript))
                        }
                    default:
                        print("Not implemented")
                    }
                }
            }
        }
    }
#endif
