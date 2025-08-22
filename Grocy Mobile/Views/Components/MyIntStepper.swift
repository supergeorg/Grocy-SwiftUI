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

    var body: some View {
        Stepper(
            value: $amount,
            in: ((minAmount ?? 0)...(Int.max - 1)),
            step: 1,
            label: {
                HStack {
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text(description)
                            if let helpText = helpText {
                                FieldDescription(description: helpText)
                            }
                        }
                        HStack {
                            TextField("", value: $amount, formatter: NumberFormatter())
                                #if os(macOS)
                                    .frame(width: 90)
                                #elseif os(iOS)
                                    .keyboardType(.numbersAndPunctuation)
                                    .submitLabel(.done)
                                #endif
                            if let amountName = amountName {
                                Text(amountName)
                            }
                        }
                        if let minAmount = minAmount, amount < minAmount, let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        )
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

    var body: some View {
        Stepper(
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
            },
            label: {
                HStack {
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text(description)
                            if let helpText = helpText {
                                FieldDescription(description: helpText)
                            }
                        }
                        HStack {
                            TextField("", value: $amount, formatter: NumberFormatter())
                                #if os(macOS)
                                    .frame(width: 90)
                                #elseif os(iOS)
                                    .keyboardType(.numbersAndPunctuation)
                                    .submitLabel(.done)
                                #endif
                            if let amountName = amountName {
                                Text(amountName)
                            }
                        }
                        if let minAmount = minAmount, let amount = amount, amount < minAmount, let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        )
    }
}

#Preview("Default") {
    @Previewable @State var amount: Int = 1

    MyIntStepper(amount: $amount, description: "Description", helpText: "Help Text", minAmount: 1, amountName: "QuantityUnit", systemImage: "tag")
}
#Preview("Optional") {
    @Previewable @State var amount: Int? = nil

    MyIntStepperOptional(amount: $amount, description: "Description", helpText: "Help Text", minAmount: 1, amountName: "QuantityUnit", systemImage: "tag")
}

#Preview("Default Error") {
    MyIntStepper(amount: .constant(-1), description: "Description", helpText: "Help Text", minAmount: 1, amountName: "QuantityUnit", errorMessage: "Error Message", systemImage: "tag")
}
