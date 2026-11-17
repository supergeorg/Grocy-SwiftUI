//
//  CodeScannerSheetView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI
import Vision

#if os(iOS)
    /// Scans one code in a sheet, then dismisses itself. Closed with the close button or by swiping down.
    struct CodeScannerSheetView: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.openURL) private var openURL

        var title: LocalizedStringKey = "Scan barcode"
        /// The enabled barcode types (barcode settings) when nil.
        var symbologies: [VNBarcodeSymbology]? = nil
        var onCodeFound: (CodeResult) -> Void

        @State private var isTorchOn: Bool = false
        @State private var cameraUnauthorized: Bool = false

        var body: some View {
            NavigationStack {
                CodeScannerView(
                    onCodeFound: { result in
                        onCodeFound(result)
                        dismiss()
                    },
                    onAuthorizationFailed: { cameraUnauthorized = true },
                    symbologies: symbologies
                )
                .ignoresSafeArea()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        TorchButton(isTorchOn: $isTorchOn)
                    }
                }
                .alert("Camera Access Required", isPresented: $cameraUnauthorized) {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Please enable camera access in Settings to scan barcodes.")
                }
            }
            .onDisappear {
                if isTorchOn {
                    toggleTorch(state: false)
                }
            }
        }
    }

    /// Switches the torch of the camera on and off.
    struct TorchButton: View {
        @Binding var isTorchOn: Bool

        var body: some View {
            Button {
                isTorchOn.toggle()
                toggleTorch(state: isTorchOn)
            } label: {
                Label("Torch", systemImage: isTorchOn ? MySymbols.torchOn : MySymbols.torchOff)
            }
            .disabled(!checkForTorch())
        }
    }

    #Preview {
        CodeScannerSheetView(onCodeFound: { _ in })
    }
#endif
