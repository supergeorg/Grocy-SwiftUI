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
        Stepper(
            value: $amount,
            in: -Double.greatestFiniteMagnitude...Double.greatestFiniteMagnitude,
            step: 1.0,
            label: {
                HStack {
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text(description)
                            if let descriptionInfo = descriptionInfo {
                                FieldDescription(description: descriptionInfo)
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
                        if let minAmount = minAmount, amount < minAmount {
                            Text("This cannot be lower than \(smallestValidAmount, specifier: "%.2f") and needs to be a valid number with max.  \(userSettings?.stockDecimalPlacesAmounts ?? 4) decimal places")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let maxAmount = maxAmount, amount > maxAmount, let errorMessageMax = errorMessageMax {
                            Text(errorMessageMax)
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
        let decPlaces = Int(userSettings?.stockDecimalPlacesAmounts ?? 4)
        let increment = 1 / pow(10, decPlaces)
        return (minAmount ?? 0.0) + Double(truncating: increment as NSNumber)
    }

    var body: some View {
        Stepper(
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
            },
            label: {
                HStack {
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text(description)
                            if let descriptionInfo = descriptionInfo {
                                FieldDescription(description: descriptionInfo)
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
                        if let minAmount = minAmount, let amount = amount, amount < minAmount {
                            Text("This cannot be lower than \(smallestValidAmount, specifier: "%.2f") and needs to be a valid number with max.  \(userSettings?.stockDecimalPlacesAmounts ?? 4) decimal places")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let maxAmount = maxAmount, let amount = amount, amount > maxAmount, let errorMessageMax = errorMessageMax {
                            Text(errorMessageMax)
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

//#Preview {
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: GrocyUserSettings.self, configurations: config)
//
//    let userSettings = GrocyUserSettings()
//    container.mainContext.insert(userSettings)
//
//    @Previewable @State var amount: Double = 1.0
//
//    MyDoubleStepper(amount: $amount, description: "Description", descriptionInfo: "Description info Text", minAmount: 1.0, amountStep: 0.1, amountName: "QuantityUnit", systemImage: "tag")
//        .modelContainer(container)
//}
