//
//  EquipmentFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct EquipmentFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) var dismiss

    @Query(sort: \MDEquipment.id, order: .forward) var mdEquipment: MDEquipments

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingEquipment: MDEquipment?
    var isPopup: Bool = false
    @State private var equipment: MDEquipment

    /// A newly picked manual, uploaded on save.
    @State private var pickedManual: (fileName: String, data: Data)? = nil
    /// The current manual is deleted on save (as in Grocy, it stays until then).
    @State private var deleteManualOnSave: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var showNotesEditor: Bool = false

    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundEquipment = mdEquipment.first(where: { $0.name == equipment.name })
        return !(equipment.name.isEmpty || (foundEquipment != nil && foundEquipment!.id != equipment.id))
    }

    init(existingEquipment: MDEquipment? = nil, isPopup: Bool = false) {
        self.existingEquipment = existingEquipment
        self.isPopup = isPopup
        // Edited on a copy, so cancelling doesn't change the cached equipment.
        self.equipment = existingEquipment.map {
            MDEquipment(
                id: $0.id,
                name: $0.name,
                mdEquipmentDescription: $0.mdEquipmentDescription,
                instructionManualFileName: $0.instructionManualFileName,
                rowCreatedTimestamp: $0.rowCreatedTimestamp
            )
        } ?? MDEquipment()
    }

    private let dataToUpdate: [ObjectEntities] = [.equipment]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func finishForm() {
        dismiss()
    }

    /// The manual's name shown in the form: the picked file, or the current one unless it's removed.
    private var shownManualFileName: String? {
        if let pickedManual {
            return pickedManual.fileName
        }
        return deleteManualOnSave ? nil : existingEquipment?.instructionManualFileName
    }

    /// Like Grocy's `RandomString() + CleanFileName(...)`, so names stay unique and safe on the server.
    private func serverFileName(for originalName: String) -> String {
        var name = originalName.lowercased()
            .replacingOccurrences(of: "ä", with: "ae")
            .replacingOccurrences(of: "ö", with: "oe")
            .replacingOccurrences(of: "ü", with: "ue")
            .replacingOccurrences(of: "ß", with: "ss")
        name = name.filter { !$0.isWhitespace }
        let prefix = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(16)
        return "\(prefix)\(name)"
    }

    private func pickManual(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                pickedManual = (fileName: serverFileName(for: url.lastPathComponent), data: data)
                deleteManualOnSave = false
            } catch {
                GrocyLogger.error("Reading the instruction manual failed. \(error)")
                isSuccessful = false
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            GrocyLogger.error("Picking the instruction manual failed. \(error)")
        }
    }

    private func saveEquipment() async {
        if equipment.id == -1 {
            do {
                equipment.id = try grocyVM.findNextID(.equipment)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        let previousManual = existingEquipment?.instructionManualFileName
        if let pickedManual {
            equipment.instructionManualFileName = pickedManual.fileName
        } else if deleteManualOnSave {
            equipment.instructionManualFileName = nil
        }

        isProcessing = true
        isSuccessful = nil
        do {
            if existingEquipment == nil {
                _ = try await grocyVM.postMDObject(object: .equipment, content: equipment)
            } else {
                try await grocyVM.putMDObjectWithID(object: .equipment, id: equipment.id, content: equipment)
            }
            GrocyLogger.info("Equipment \(equipment.name) successful.")
            if let pickedManual {
                try await grocyVM.uploadInstructionManual(fileData: pickedManual.data, fileName: pickedManual.fileName)
                GrocyLogger.info("Uploading the instruction manual was successful.")
            }
            // The old file isn't referenced anymore once it's replaced or removed.
            if let previousManual, previousManual != equipment.instructionManualFileName {
                do {
                    try await grocyVM.deleteInstructionManual(fileName: previousManual)
                } catch {
                    GrocyLogger.warning("Deleting the previous instruction manual failed. \(error)")
                }
            }
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Equipment \(equipment.name) failed. \(error)")
            isSuccessful = false
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            MyTextField(
                textToEdit: $equipment.name,
                description: "Name",
                prompt: "Required",
                isCorrect: $isNameCorrect,
                leadingIcon: MySymbols.name,
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: equipment.name) {
                isNameCorrect = checkNameCorrect()
            }

            Section {
                if let shownManualFileName {
                    Label(shownManualFileName, systemImage: MySymbols.instructionManual)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("No file selected")
                        .foregroundStyle(.secondary)
                }
                Button {
                    showFileImporter = true
                } label: {
                    Label(shownManualFileName == nil ? "Select file" : "Replace file", systemImage: MySymbols.importRecipe)
                }
                if shownManualFileName != nil {
                    Button(role: .destructive) {
                        if pickedManual != nil {
                            pickedManual = nil
                        } else {
                            deleteManualOnSave = true
                        }
                    } label: {
                        Label("Remove file", systemImage: MySymbols.delete)
                    }
                }
            } header: {
                Text("Instruction manual")
            } footer: {
                if deleteManualOnSave {
                    Text("The current file will be deleted on save")
                } else if pickedManual != nil, existingEquipment?.instructionManualFileName != nil {
                    Text("The current file will be replaced on save")
                }
            }

            Section("Notes") {
                if !equipment.mdEquipmentDescription.isEmpty {
                    HTMLPreviewView(htmlContent: $equipment.mdEquipmentDescription, minHeight: 150, showControlBar: false)
                }
                Button {
                    showNotesEditor = true
                } label: {
                    Label("Edit", systemImage: MySymbols.editPreparation)
                }
            }
        }
        .formStyle(.grouped)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf]) { result in
            pickManual(result)
        }
        .sheet(isPresented: $showNotesEditor) {
            RecipePreparationEditorView(htmlContent: $equipment.mdEquipmentDescription, title: "Notes")
        }
        .task {
            await updateData()
            self.isNameCorrect = checkNameCorrect()
        }
        .navigationTitle(existingEquipment == nil ? "Create equipment" : "Edit equipment")
        .toolbar {
            if existingEquipment == nil || isPopup {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        finishForm()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) {
                    Task {
                        await saveEquipment()
                    }
                } label: {
                    // While it runs, the icon becomes an animated progress symbol. It stays an image: with a ProgressView as its icon,
                    // the item loses its icon and leaves iPhone Duo's vertical bar for a text-only button at the bottom.
                    Label("Save", systemImage: isProcessing ? MySymbols.progress : MySymbols.save)
                        .symbolEffect(.variableColor.iterative, isActive: isProcessing)
                }
                .disabled(!isNameCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        }
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                finishForm()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        EquipmentFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        EquipmentFormView(existingEquipment: MDEquipment(name: "Coffee machine", mdEquipmentDescription: "<p>Descale every 3 months.</p>", instructionManualFileName: "manual.pdf"))
    }
}
