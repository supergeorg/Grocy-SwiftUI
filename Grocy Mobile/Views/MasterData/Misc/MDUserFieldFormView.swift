//
//  MDUserFieldFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 16.12.20.
//

import SwiftUI

struct MDUserFieldFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Environment(\.dismiss) var dismiss

    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    /// The entity the field belongs to, e.g. `products` or `userentity-<name>`.
    @State private var entity: String = ""
    @State private var name: String = ""
    @State private var caption: String = ""
    @State private var sortNumber: Int? = nil
    @State private var type: UserFieldType = UserFieldType.none
    @State private var showAsColumnInTables: Bool = false
    @State private var inputRequired: Bool = false
    @State private var defaultValue: String = ""
    /// The options of a select list, one per line.
    @State private var config: String = ""

    private var hasOptions: Bool {
        type == .presetList || type == .presetChecklist
    }

    /// The entities Grocy accepts userfields for: its objects, the user entities and the users.
    private var entities: [(entity: String, caption: String)] {
        var entities = ObjectEntities.allCases.map { ($0.rawValue, $0.rawValue) }
        entities += grocyVM.mdUserEntities.map { ($0.userfieldEntity, $0.caption) }
        entities.append(("users", "users"))
        if !entity.isEmpty && !entities.contains(where: { $0.0 == entity }) {
            entities.append((entity, entity))
        }
        return entities
    }

    var isNewUserField: Bool
    var userField: MDUserField?

    @Binding var showAddUserField: Bool

    @State private var isNameCorrect: Bool = true
    /// Grocy only accepts letters and numbers, and a name once per entity.
    private func checkNameCorrect() -> Bool {
        guard name.wholeMatch(of: /[A-Za-z0-9]+/) != nil else { return false }
        let foundUserField = grocyVM.mdUserFields.first { $0.name == name && $0.entity == entity }
        return foundUserField == nil || foundUserField?.id == userField?.id
    }

    @State private var isCaptionCorrect: Bool = true
    private func checkCaptionCorrect() -> Bool {
        return !caption.isEmpty
    }

    private func resetForm() {
        entity = userField?.entity ?? ""
        name = userField?.name ?? ""
        caption = userField?.caption ?? ""
        sortNumber = userField?.sortNumber
        type = UserFieldType(rawValue: userField?.type ?? "") ?? UserFieldType.none
        showAsColumnInTables = userField?.showAsColumnInTables == true
        inputRequired = userField?.inputRequired == true
        defaultValue = userField?.defaultValue ?? ""
        config = userField?.config ?? ""
        isNameCorrect = checkNameCorrect()
        isCaptionCorrect = checkCaptionCorrect()
    }

    private let dataToUpdate: [ObjectEntities] = [.userfields, .userentities]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func finishForm() {
        #if os(iOS)
            self.dismiss()
        #elseif os(macOS)
            if isNewUserField {
                showAddUserField = false
            }
        #endif
    }

    private func showError(_ error: Error) {
        errorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
        isSuccessful = false
    }

    private func saveUserField() async {
        if !entity.isEmpty {
            let id: Int
            if isNewUserField {
                do {
                    id = try grocyVM.findNextID(.userfields)
                } catch {
                    GrocyLogger.error("Failed to get next ID: \(error)")
                    return
                }
            } else {
                id = userField!.id
            }
            let timeStamp = isNewUserField ? Date() : userField!.rowCreatedTimestamp
            let userFieldPOST = MDUserField(
                id: id,
                name: name,
                entity: entity,
                caption: caption,
                type: type.rawValue,
                showAsColumnInTables: showAsColumnInTables,
                config: hasOptions ? config : nil,
                sortNumber: sortNumber,
                inputRequired: inputRequired,
                defaultValue: defaultValue,
                rowCreatedTimestamp: timeStamp
            )
            isSuccessful = nil
            isProcessing = true
            if isNewUserField {
                do {
                    _ = try await grocyVM.postMDObject(object: .userfields, content: userFieldPOST)
                    GrocyLogger.info("Userfield add successful.")
                    isSuccessful = true
                    resetForm()
                    await updateData()
                    finishForm()
                } catch {
                    GrocyLogger.error("Userfield add failed. \(error)")
                    showError(error)
                }
            } else {
                do {
                    _ = try await grocyVM.putMDObjectWithID(object: .userfields, id: id, content: userFieldPOST)
                    GrocyLogger.info("Userfield edit successful.")
                    isSuccessful = true
                    await updateData()
                    finishForm()
                } catch {
                    GrocyLogger.error("Userfield edit failed. \(error)")
                    showError(error)
                }
            }
            isProcessing = false
        }
    }

    var body: some View {
        content
            .navigationTitle(isNewUserField ? "Create userfield" : "Edit userfield")
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        role: .confirm,
                        action: {
                            Task {
                                await saveUserField()
                            }
                        },
                        label: {
                            // Label style is left to the system, so the confirm button gets the standard Liquid Glass look.
                            // While it runs, the icon becomes an animated progress symbol. It stays an image: with a ProgressView as its icon,
                            // the item loses its icon and leaves iPhone Duo's vertical bar for a text-only button at the bottom.
                            Label("Save", systemImage: isProcessing ? MySymbols.progress : MySymbols.save)
                                .symbolEffect(.variableColor.iterative, isActive: isProcessing)
                        }
                    )
                    .disabled(!isNameCorrect || !isCaptionCorrect || entity.isEmpty || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
                ToolbarItem(placement: .cancellationAction) {
                    if isNewUserField {
                        Button(role: .cancel) {
                            finishForm()
                        }
                    }
                }
            })
            .sensoryFeedback(.success, trigger: isSuccessful == true)
            .sensoryFeedback(.error, trigger: isSuccessful == false)
    }

    var content: some View {
        Form {
            #if os(macOS)
                Text(isNewUserField ? "Create userfield" : "Edit userfield")
                    .font(.title)
                    .bold()
                    .padding(.bottom, Spacing.xLarge)
            #endif
            if isSuccessful == false, let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            VStack(alignment: .leading) {
                Picker(
                    selection: $entity,
                    label: Text("Entity"),
                    content: {
                        Text(verbatim: "").tag("")
                        ForEach(entities, id: \.entity) { entity in
                            Text(verbatim: entity.caption).tag(entity.entity)
                        }
                    }
                )
                .onChange(of: entity) {
                    isNameCorrect = checkNameCorrect()
                }
                if entity.isEmpty {
                    Text("An entity is required")
                        .foregroundStyle(.red)
                }
            }

            Section(header: Text("Name")) {
                MyTextField(
                    textToEdit: $name,
                    description: "Name",
                    isCorrect: $isNameCorrect,
                    leadingIcon: MySymbols.name,
                    emptyMessage: "This is required and can only contain letters and numbers",
                    errorMessage: "This is required and can only contain letters and numbers",
                    helpText: "This is the internal field name, e. g. for the API"
                )
                // The internal name only allows letters and numbers, so the keyboard doesn't change what's typed.
                #if os(iOS)
                    .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .onChange(of: name) {
                    isNameCorrect = checkNameCorrect()
                }
                MyTextField(
                    textToEdit: $caption,
                    description: "Caption",
                    isCorrect: $isCaptionCorrect,
                    leadingIcon: MySymbols.name,
                    emptyMessage: "A caption is required",
                    helpText: "This is used to display the field on the frontend"
                )
                .onChange(of: caption) {
                    isCaptionCorrect = checkCaptionCorrect()
                }
            }
            MyIntStepperOptional(
                amount: $sortNumber,
                description: "Sort number",
                helpText: "Multiple Userfields will be ordered by that number on the input form",
                minAmount: 0,
                errorMessage: "",
                systemImage: MySymbols.sortNumber
            )

            Picker(
                selection: $type,
                label: Text("Type"),
                content: {
                    ForEach(UserFieldType.allCases, id: \.self) { userFieldType in
                        Text(LocalizedStringKey(userFieldType.getDescription())).tag(userFieldType)
                    }
                }
            )

            if hasOptions {
                Section {
                    MyTextEditor(textToEdit: $config, description: "Options", leadingIcon: MySymbols.inventory)
                } footer: {
                    Text("One option per line")
                }
            }

            MyTextField(textToEdit: $defaultValue, description: "Default value", isCorrect: .constant(true), leadingIcon: MySymbols.description)
            MyToggle(isOn: $inputRequired, description: "Mandatory", icon: MySymbols.inputRequired)
            MyToggle(isOn: $showAsColumnInTables, description: "Show as column in tables", icon: MySymbols.tableColumn)
        }
        .formStyle(.grouped)
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        MDUserFieldFormView(isNewUserField: true, showAddUserField: .constant(true))
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        MDUserFieldFormView(
            isNewUserField: false,
            userField: MDUserField(
                id: 1,
                name: "brand",
                entity: "products",
                caption: "Brand",
                type: UserFieldType.textSingleLine.rawValue,
                showAsColumnInTables: true
            ),
            showAddUserField: .constant(false)
        )
    }
}
