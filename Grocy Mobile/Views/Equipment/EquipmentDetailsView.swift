//
//  EquipmentDetailsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftUI

/// An equipment's instruction manual and notes, the two tabs of the Grocy web app.
struct EquipmentDetailsView: View {
    var equipment: MDEquipment

    @Environment(GrocyViewModel.self) private var grocyVM

    enum Section: Hashable {
        case instructionManual, notes
    }

    @State private var section: Section = .instructionManual
    @State private var manualData: Data?
    @State private var manualFileURL: URL?
    @State private var isLoadingManual: Bool = false
    @State private var manualErrorMessage: String?
    @State private var showEditForm: Bool = false
    @State private var notes: String = ""

    private func loadManual() async {
        guard let fileName = equipment.instructionManualFileName else {
            manualData = nil
            manualFileURL = nil
            return
        }
        isLoadingManual = true
        do {
            let data = try await grocyVM.getInstructionManual(fileName: fileName)
            manualData = data
            manualErrorMessage = nil
            // A copy on disk, so the manual can be shared or opened in another app.
            let url = URL.temporaryDirectory.appending(path: fileName)
            try data.write(to: url, options: .atomic)
            manualFileURL = url
        } catch {
            GrocyLogger.error("Loading the instruction manual failed. \(error)")
            if let apiError = error as? APIError {
                manualErrorMessage = apiError.displayMessage
            } else {
                manualErrorMessage = error.localizedDescription
            }
        }
        isLoadingManual = false
    }

    var body: some View {
        Group {
            switch section {
            case .instructionManual:
                manualContent
            case .notes:
                notesContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaBar(edge: .top) {
            Picker("Section", selection: $section) {
                Text("Instruction manual").tag(Section.instructionManual)
                Text("Notes").tag(Section.notes)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal)
            .padding(.vertical, Spacing.small)
        }
        .navigationTitle(equipment.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if section == .instructionManual, let manualFileURL {
                ToolbarItem(placement: .automatic) {
                    ShareLink(item: manualFileURL) {
                        Label("Share", systemImage: MySymbols.share)
                            .macHelp("Share")
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditForm = true
                } label: {
                    Label("Edit equipment", systemImage: MySymbols.edit)
                        .macHelp("Edit equipment")
                }
            }
        }
        .sheet(isPresented: $showEditForm) {
            NavigationStack {
                EquipmentFormView(existingEquipment: equipment, isPopup: true)
            }
        }
        .task(id: equipment.instructionManualFileName) {
            await loadManual()
        }
        .onAppear {
            notes = equipment.mdEquipmentDescription
        }
        .onChange(of: equipment.mdEquipmentDescription) { _, newValue in
            notes = newValue
        }
    }

    @ViewBuilder
    private var manualContent: some View {
        if equipment.instructionManualFileName == nil {
            ContentUnavailableView {
                Label("No instruction manual", systemImage: MySymbols.instructionManual)
            } description: {
                Text("The selected equipment has no instruction manual.")
            } actions: {
                Button("Edit equipment") {
                    showEditForm = true
                }
            }
        } else if let manualData {
            PDFDocumentView(data: manualData)
        } else if let manualErrorMessage {
            ContentUnavailableView {
                Label("Couldn't load the instruction manual", systemImage: MySymbols.error)
            } description: {
                Text(manualErrorMessage)
            } actions: {
                Button("Try again") {
                    Task { await loadManual() }
                }
            }
        } else if isLoadingManual {
            ProgressView()
        }
    }

    @ViewBuilder
    private var notesContent: some View {
        if notes.isEmpty {
            ContentUnavailableView {
                Label("No notes", systemImage: MySymbols.description)
            } description: {
                Text("This equipment has no notes.")
            }
        } else {
            ScrollView {
                HTMLPreviewView(htmlContent: $notes)
                    .padding(.horizontal)
            }
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        EquipmentDetailsView(equipment: MDEquipment(name: "Coffee machine", mdEquipmentDescription: "<h1>Descaling</h1><p>Every <b>3 months</b>.</p>"))
    }
}
