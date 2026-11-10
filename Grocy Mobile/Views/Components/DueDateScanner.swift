//
//  DueDateScanner.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.02.26.
//

import SwiftUI

struct DueDateScanner: View {
    @Binding var dueDate: Date

    @State private var isScanPaused: Bool = true
    @State private var showDateScanner: Bool = false
    func handleDateScan(result: CodeResult) {
        self.showDateScanner = false

        if let foundDate = result.value.asDate {
            self.dueDate = foundDate
        }
    }

    var body: some View {
        Button(
            action: {
                showDateScanner.toggle()
            },
            label: {
                Image(systemName: MySymbols.scanDate)
            }
        )
        .sheet(
            isPresented: $showDateScanner,
            content: {
                #if os(iOS)
                    CodeScannerView(isPaused: $isScanPaused, onCodeFound: self.handleDateScan, symbologies: [], recognizeDates: true)
                        .onAppear { isScanPaused = false }
                        .onDisappear { isScanPaused = true }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                            isScanPaused = true
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                            isScanPaused = false
                        }
                #endif
            }
        )
    }
}
