//
//  MyDoubleStepper.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftData
import SwiftUI

struct MyDoubleStepper: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }

    @Binding var amount: Double

    var description: LocalizedStringKey
    var descriptionInfo: LocalizedStringKey? = nil
    var minAmount: Double? = 0.0
    var maxAmount: Double? = nil
    var amountStep: Double? = 1.0
    var amountName: String? = nil

    var errorMessageMax: LocalizedStringKey? = nil

    var systemImage: String? = nil

    var currencySymbol: String?

    var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.allowsFloats = true
        if let currencySymbol = currencySymbol {
            f.numberStyle = .currency
            f.isLenient = true
            f.currencySymbol = currencySymbol
            f.maximumFractionDigits = userSettings?.stockDecimalPlacesPricesInput ?? 2
        } else {
            f.numberStyle = .decimal
            f.maximumFractionDigits = userSettings?.stockDecimalPlacesAmounts ?? 2
        }
        return f
    }

    var smallestValidAmount: Double {
        let decPlaces = Int(userSettings?.stockDecimalPlacesAmounts ?? 4)
        let increment = 1 / pow(10, decPlaces)
        return (minAmount ?? 0.0) + Double(truncating: increment as NSNumber)
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
                        in: -Double.greatestFiniteMagnitude...Double.greatestFiniteMagnitude,
                        step: 1.0,
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
                            if let descriptionInfo {
                                FieldDescription(description: descriptionInfo)
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
            if let minAmount = minAmount, amount < minAmount {
                Text(
                    "This cannot be lower than \(smallestValidAmount.formatted(.number.precision(.fractionLength(0...(userSettings?.stockDecimalPlacesAmounts ?? 4))))) and needs to be a valid number with max. \(userSettings?.stockDecimalPlacesAmounts ?? 4) decimal places"
                )
                .font(.caption)
                .foregroundStyle(Color(.GrocyColors.grocyRed))
                .fixedSize(horizontal: false, vertical: true)
            }
            if let maxAmount = maxAmount, amount > maxAmount, let errorMessageMax = errorMessageMax {
                Text(errorMessageMax)
                    .font(.caption)
                    .foregroundStyle(Color(.GrocyColors.grocyRed))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct MyDoubleStepperOptional: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }

    @Binding var amount: Double?

    var description: LocalizedStringKey
    var descriptionInfo: LocalizedStringKey? = nil
    var minAmount: Double? = 0.0
    var maxAmount: Double? = nil
    var amountStep: Double? = 1.0
    var amountName: String? = nil

    var errorMessageMax: LocalizedStringKey? = nil

    var systemImage: String? = nil

    var currencySymbol: String?

    var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.allowsFloats = true
        if let currencySymbol = currencySymbol {
            f.numberStyle = .currency
            f.isLenient = true
            f.currencySymbol = currencySymbol
            f.maximumFractionDigits = userSettings?.stockDecimalPlacesPricesInput ?? 2
        } else {
            f.numberStyle = .decimal
            f.maximumFractionDigits = userSettings?.stockDecimalPlacesAmounts ?? 2
        }
        return f
    }

    var smallestValidAmount: Double {
        let decimalPlaces: Int = Int(userSettings?.stockDecimalPlacesAmounts ?? 4)
        let increment: Double = pow(10.0, -Double(decimalPlaces))
        return (minAmount ?? 0.0) + increment
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
                            .multilineTextAlignment(.trailing)
                        #endif

                    if let amountName = amountName {
                        Text(amountName)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(.secondary)
                    }

                    Stepper(
                        description,
                        onIncrement: {
                            if let previousAmount = amount {
                                amount = previousAmount + (amountStep ?? 1.0)
                            } else {
                                amount = amountStep
                            }
                        },
                        onDecrement: {
                            if let previousAmount = amount {
                                if let minAmount = minAmount {
                                    if previousAmount == minAmount {
                                        amount = nil
                                    } else if previousAmount - (amountStep ?? 1.0) < minAmount {
                                        amount = minAmount
                                    } else {
                                        amount = previousAmount - (amountStep ?? 1.0)
                                    }
                                } else {
                                    amount = previousAmount - (amountStep ?? 1.0)
                                }
                            } else {
                                amount = 0
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
                            if let descriptionInfo {
                                FieldDescription(description: descriptionInfo)
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
            if let minAmount = minAmount, let amount = amount, amount < minAmount {
                Text(
                    "This cannot be lower than \(smallestValidAmount.formatted(.number.precision(.fractionLength(0...(userSettings?.stockDecimalPlacesAmounts ?? 4))))) and needs to be a valid number with max. \(userSettings?.stockDecimalPlacesAmounts ?? 4) decimal places"
                )
                .font(.caption)
                .foregroundStyle(Color(.GrocyColors.grocyRed))
                .fixedSize(horizontal: false, vertical: true)
            }
            if let maxAmount = maxAmount, let amount = amount, amount > maxAmount, let errorMessageMax = errorMessageMax {
                Text(errorMessageMax)
                    .font(.caption)
                    .foregroundStyle(Color(.GrocyColors.grocyRed))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview(traits: .previewData) {
    @Previewable @State var amount: Double = 1.0
    @Previewable @State var amountOptional: Double? = nil

    List {
        MyDoubleStepper(
            amount: $amount,
            description: "Description",
            descriptionInfo: "Description info Text",
            minAmount: 1.0,
            amountStep: 0.1,
            amountName: "Quantityunit",
            systemImage: "tag"
        )

        MyDoubleStepperOptional(
            amount: $amountOptional,
            description: "Description",
            minAmount: 1.0,
            amountStep: 0.1,
        )
        MyDoubleStepperOptional(
            amount: $amountOptional,
            description: "Description",
            descriptionInfo: "Description info Text",
            minAmount: 1.0,
            amountStep: 0.1,
            amountName: "Quantityunit",
            systemImage: "tag"
        )
    }
}
