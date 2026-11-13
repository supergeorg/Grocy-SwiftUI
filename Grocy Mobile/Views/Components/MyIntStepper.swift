//
//  MyNumberPicker.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MyIntStepper: View {
    @Binding var amount: Int

    var description: LocalizedStringKey
    var helpText: LocalizedStringKey?
    var minAmount: Int? = 0
    var amountName: LocalizedStringKey? = nil

    var errorMessage: LocalizedStringKey?

    var systemImage: String?

    var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.allowsFloats = false
        return f
    }

    var body: some View {
        VStack(alignment: .leading) {
            LabeledContent {
                HStack {
                    TextField(description, value: $amount, formatter: formatter)
                        // The description names the field (hidden here, the row shows it), so VoiceOver says which amount this is.
                        .labelsHidden()
                        #if os(macOS)
                            .frame(width: 90)
                        #elseif os(iOS)
                            .keyboardType(.numbersAndPunctuation)
                            .submitLabel(.done)
                            .accessibilityLabel(Text(description))
                        #endif
                    if let amountName = amountName {
                        Text(amountName)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Stepper(
                        description,
                        value: $amount,
                        in: ((minAmount ?? 0)...(Int.max - 1)),
                        step: 1
                    )
                    // The title stays the stepper\'s accessibility label on both platforms.
                    .labelsHidden()
                }
            } label: {
                if let systemImage {
                    Label {
                        HStack {
                            Text(description)
                                .fixedSize(horizontal: false, vertical: true)
                            if let helpText {
                                FieldDescription(description: helpText)
                            }
                        }
                    } icon: {
                        Image(systemName: systemImage)
                    }
                    .foregroundStyle(.primary)
                } else {
                    Text(description)
                }
            }
            if let minAmount = minAmount, amount < minAmount, let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color(.GrocyColors.grocyRed))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

    }
}

struct MyIntStepperOptional: View {
    @Binding var amount: Int?

    var description: LocalizedStringKey
    var helpText: LocalizedStringKey?
    var minAmount: Int? = 0
    var amountName: LocalizedStringKey? = nil

    var errorMessage: LocalizedStringKey?

    var systemImage: String?

    var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.allowsFloats = false
        return f
    }

    var body: some View {
        VStack(alignment: .leading) {
            LabeledContent {
                HStack {
                    TextField(description, value: $amount, formatter: formatter)
                        // The description names the field (hidden here, the row shows it), so VoiceOver says which amount this is.
                        .labelsHidden()
                        #if os(macOS)
                            .frame(width: 90)
                        #elseif os(iOS)
                            .keyboardType(.numbersAndPunctuation)
                            .submitLabel(.done)
                            .accessibilityLabel(Text(description))
                        #endif
                    if let amountName = amountName {
                        Text(amountName)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Stepper(
                        description,
                        onIncrement: {
                            if let previousAmount = amount {
                                amount = previousAmount + 1
                            } else {
                                amount = 1
                            }
                        },
                        onDecrement: {
                            if let previousAmount = amount {
                                if let minAmount = minAmount {
                                    if previousAmount > minAmount {
                                        amount = previousAmount - 1
                                    } else {
                                        amount = nil
                                    }
                                } else {
                                    amount = previousAmount - 1
                                }
                            } else {
                                amount = minAmount
                            }
                        }
                    )
                    // The title stays the stepper\'s accessibility label on both platforms.
                    .labelsHidden()
                }
            } label: {
                if let systemImage {
                    Label {
                        HStack {
                            Text(description)
                                .fixedSize(horizontal: false, vertical: true)
                            if let helpText {
                                FieldDescription(description: helpText)
                            }
                        }
                    } icon: {
                        Image(systemName: systemImage)
                    }
                    .foregroundStyle(.primary)
                } else {
                    Text(description)
                }
            }
            if let minAmount = minAmount, let amount = amount, amount < minAmount, let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color(.GrocyColors.grocyRed))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview(traits: .previewData) {
    @Previewable @State var amount: Int = 1
    @Previewable @State var amountOptional: Int? = nil

    Form {
        Section {
            MyIntStepper(amount: $amount, description: "Description", helpText: "Help Text", minAmount: 1, amountName: "QuantityUnit", systemImage: "tag")
        }
        Section("Optional") {
            MyIntStepperOptional(amount: $amountOptional, description: "Description", helpText: "Help Text", minAmount: 1, amountName: "QuantityUnit", systemImage: "tag")
        }
        Section("Error") {
            MyIntStepper(amount: .constant(-1), description: "Description", helpText: "Help Text", minAmount: 1, amountName: "QuantityUnit", errorMessage: "Error Message", systemImage: "tag")
        }
    }
}
