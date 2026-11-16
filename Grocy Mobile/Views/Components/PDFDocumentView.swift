//
//  PDFDocumentView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import PDFKit
import SwiftUI

/// Shows a PDF (e.g. an equipment's instruction manual) with PDFKit, scaled to the available width.
struct PDFDocumentView: View {
    let data: Data

    var body: some View {
        if let document = PDFDocument(data: data) {
            PDFKitRepresentedView(document: document)
                .accessibilityLabel(Text("Instruction manual"))
        } else {
            ContentUnavailableView {
                Label("Can't show this file", systemImage: MySymbols.instructionManual)
            } description: {
                Text("The file isn't a PDF document.")
            }
        }
    }
}

#if os(iOS)
    private struct PDFKitRepresentedView: UIViewRepresentable {
        let document: PDFDocument

        func makeUIView(context: Context) -> PDFView {
            let view = PDFView()
            view.autoScales = true
            view.displayMode = .singlePageContinuous
            view.document = document
            return view
        }

        func updateUIView(_ view: PDFView, context: Context) {
            if view.document !== document {
                view.document = document
            }
        }
    }
#elseif os(macOS)
    private struct PDFKitRepresentedView: NSViewRepresentable {
        let document: PDFDocument

        func makeNSView(context: Context) -> PDFView {
            let view = PDFView()
            view.autoScales = true
            view.displayMode = .singlePageContinuous
            view.document = document
            return view
        }

        func updateNSView(_ view: PDFView, context: Context) {
            if view.document !== document {
                view.document = document
            }
        }
    }
#endif

#Preview {
    PDFDocumentView(data: Data())
}
