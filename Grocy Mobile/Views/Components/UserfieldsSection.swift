//
//  UserfieldsSection.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.11.26.
//

import SwiftUI

/// The userfields of an object as a form section, hidden when the entity has none.
/// The form loads the userfields themselves (`.userfields` in its `dataToUpdate`): a hidden section can't.
///
/// It loads the saved values itself. `changes` only holds what the person edited (and the default values of a new object),
/// so the form saves just those after saving the object, like Grocy's web form:
/// `try await grocyVM.saveUserfields(entity: entity, objectID: id, changes: changes)`.
struct UserfieldsSection: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    /// The userfield entity, e.g. `products` or `userentity-<name>`.
    let entity: String
    /// The object's ID, `nil` for a new object.
    var objectID: Int?
    @Binding var changes: UserfieldChanges

    @State private var savedValues: [String: String] = [:]

    private var fields: MDUserFields {
        grocyVM.userfields(for: entity)
    }

    private func value(of field: MDUserField) -> Binding<String> {
        Binding(
            get: { changes.values[field.name] ?? savedValues[field.name] ?? "" },
            set: { changes.values[field.name] = $0 }
        )
    }

    private func loadValues() async {
        guard let objectID else {
            for field in fields where changes.values[field.name] == nil {
                if let defaultValue = field.defaultValue, !defaultValue.isEmpty {
                    changes.values[field.name] = defaultValue
                }
            }
            return
        }
        do {
            savedValues = try await grocyVM.getUserfieldValues(entity: entity, objectID: objectID).values
        } catch {
            GrocyLogger.error("Loading userfields of \(entity) \(objectID) failed. \(error)")
        }
    }

    var body: some View {
        if !fields.isEmpty {
            Section("Userfields") {
                ForEach(fields) { field in
                    switch field.fieldType {
                    case .file, .image:
                        UserfieldFileInput(field: field, value: value(of: field).wrappedValue, savedValue: savedValues[field.name], changes: $changes)
                    default:
                        UserfieldInput(field: field, value: value(of: field))
                    }
                }
            }
            .task(id: objectID) {
                await loadValues()
            }
        }
    }
}

extension UserFieldType {
    /// The icon of a field of this type in forms.
    var symbol: String {
        switch self {
        case .textMultiLine: MySymbols.description
        case .numberIntegral, .numberDezimal: MySymbols.userfieldNumber
        case .numberCurrency: MySymbols.price
        case .date, .dateTime: MySymbols.date
        case .checkbox: MySymbols.userfieldCheckbox
        case .presetList, .presetChecklist: MySymbols.userfieldSelection
        case .link, .linkWithTitle: MySymbols.link
        case .file: MySymbols.userfieldFile
        case .image: MySymbols.picture
        case .textSingleLine, .none: MySymbols.userfieldText
        }
    }
}

/// The control for one userfield, built from the app's form components and chosen by the field's type.
/// All values are text in Grocy's formats (see `UserFieldType`). Files and pictures are `UserfieldFileInput`.
struct UserfieldInput: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    let field: MDUserField
    @Binding var value: String

    /// The caption is the household's own text, not a key of the string catalog.
    private var caption: LocalizedStringKey { LocalizedStringKey(field.caption) }
    private var symbol: String { (field.fieldType ?? .textSingleLine).symbol }

    var body: some View {
        switch field.fieldType {
        case .textMultiLine:
            MyTextEditor(textToEdit: $value, description: caption, leadingIcon: symbol)
        case .numberIntegral:
            MyIntStepperOptional(amount: integer, description: caption, minAmount: nil, systemImage: symbol)
        case .numberDezimal:
            MyDoubleStepperOptional(amount: decimal, description: caption, minAmount: nil, systemImage: symbol)
        case .numberCurrency:
            MyDoubleStepperOptional(amount: decimal, description: caption, minAmount: nil, systemImage: symbol, currencySymbol: grocyVM.getCurrencySymbol())
        case .date, .dateTime:
            dateInput
        case .checkbox:
            MyToggle(isOn: Binding(get: { value == "1" }, set: { value = $0 ? "1" : "0" }), description: caption, icon: symbol)
        case .presetList:
            Picker(selection: $value) {
                Text("None").tag("")
                ForEach(field.options, id: \.self) { Text(verbatim: $0).tag($0) }
            } label: {
                label
            }
        case .presetChecklist:
            checklist
        case .link:
            textField(isLink: true)
            linkButton(url: value, title: nil)
        case .linkWithTitle:
            linkWithTitle
        case .textSingleLine, .file, .image, .some(.none), nil:
            textField(isLink: false)
        }
    }

    /// The field's caption with its icon, like the labels of the other form components.
    private var label: some View {
        Label {
            Text(caption)
        } icon: {
            Image(systemName: symbol)
        }
        .foregroundStyle(.primary)
    }

    private func textField(isLink: Bool) -> some View {
        MyTextField(
            textToEdit: $value,
            description: caption,
            prompt: field.inputRequired ? "Required" : "",
            isCorrect: .constant(!field.inputRequired || !value.isEmpty),
            leadingIcon: symbol,
            emptyMessage: field.inputRequired ? "A value is required" : nil
        )
        #if os(iOS)
            .keyboardType(isLink ? .URL : .default)
            .textInputAutocapitalization(isLink ? .never : .sentences)
        #endif
        .autocorrectionDisabled(isLink)
    }

    // MARK: - Numbers

    private var decimal: Binding<Double?> {
        Binding(
            get: { Double(value) },
            // Whole numbers without a trailing ".0", as Grocy's web form saves them.
            set: { value = $0.map { $0.rounded() == $0 ? String(Int($0)) : String($0) } ?? "" }
        )
    }

    private var integer: Binding<Int?> {
        Binding(get: { Int(value) }, set: { value = $0.map(String.init) ?? "" })
    }

    // MARK: - Date

    private var hasTime: Bool { field.fieldType == .dateTime }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = hasTime ? "yyyy-MM-dd HH:mm:ss" : "yyyy-MM-dd"
        return formatter
    }

    /// Like the due date of a task: a switch sets the date, which is then picked below it. Unset dates stay empty.
    @ViewBuilder
    private var dateInput: some View {
        let date = dateFormatter.date(from: value)
        MyToggle(
            isOn: Binding(get: { date != nil }, set: { value = $0 ? dateFormatter.string(from: Date()) : "" }),
            description: caption,
            icon: symbol
        )
        if let date {
            DatePicker(
                selection: Binding(get: { date }, set: { value = dateFormatter.string(from: $0) }),
                displayedComponents: hasTime ? [.date, .hourAndMinute] : .date
            ) {
                Text(caption)
            }
        }
    }

    // MARK: - Select list (multiple items)

    private var selectedOptions: Set<String> {
        Set(value.split(separator: ",").map(String.init))
    }

    private var checklist: some View {
        LabeledContent {
            Menu {
                ForEach(field.options, id: \.self) { option in
                    Toggle(
                        option,
                        isOn: Binding(
                            get: { selectedOptions.contains(option) },
                            set: { isOn in
                                // Keep the order of the options.
                                value = field.options.filter { $0 == option ? isOn : selectedOptions.contains($0) }.joined(separator: ",")
                            }
                        )
                    )
                    #if os(iOS)
                        // Stays open, so several options can be picked at once.
                        .menuActionDismissBehavior(.disabled)
                    #endif
                }
            } label: {
                if selectedOptions.isEmpty {
                    Text("None")
                } else {
                    Text(verbatim: field.options.filter(selectedOptions.contains).formatted(.list(type: .and)))
                }
            }
            // The value in grey, like the one of a picker.
            .tint(.secondary)
        } label: {
            label
        }
    }

    // MARK: - Links

    @ViewBuilder
    private func linkButton(url: String, title: String?) -> some View {
        if let url = URL(string: url), url.scheme != nil {
            Link(destination: url) {
                if let title, !title.isEmpty {
                    Label(title, systemImage: MySymbols.openLink)
                } else {
                    Label("Open link", systemImage: MySymbols.openLink)
                }
            }
        }
    }

    private struct LinkWithTitle: Codable {
        var title: String = ""
        var link: String = ""
    }

    private var link: LinkWithTitle {
        (try? JSONDecoder().decode(LinkWithTitle.self, from: Data(value.utf8))) ?? LinkWithTitle()
    }

    private func linkPart(_ keyPath: WritableKeyPath<LinkWithTitle, String>) -> Binding<String> {
        Binding(
            get: { link[keyPath: keyPath] },
            set: { newValue in
                var link = link
                link[keyPath: keyPath] = newValue
                value = (try? JSONEncoder().encode(link)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
            }
        )
    }

    @ViewBuilder
    private var linkWithTitle: some View {
        MyTextField(textToEdit: linkPart(\.title), description: caption, prompt: "Title", isCorrect: .constant(true), leadingIcon: symbol)
        MyTextField(textToEdit: linkPart(\.link), description: "Link", prompt: "https://", isCorrect: .constant(true), leadingIcon: MySymbols.website)
            #if os(iOS)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
            #endif
            .autocorrectionDisabled()
        linkButton(url: link.link, title: link.title)
    }
}

#Preview(traits: .previewData) {
    @Previewable @State var changes = UserfieldChanges()
    NavigationStack {
        Form {
            UserfieldsSection(entity: "userentity-exampleuserentity", changes: $changes)
        }
        .formStyle(.grouped)
    }
}
