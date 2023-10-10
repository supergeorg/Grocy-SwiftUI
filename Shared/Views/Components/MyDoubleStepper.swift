//
//  MyDoubleStepper.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MyDoubleStepper: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Binding var amount: Double
    
    var description: String
    var descriptionInfo: String? = nil
    var minAmount: Double? = 0.0
    var maxAmount: Double? = nil
    var amountStep: Double? = 1.0
    var amountName: String? = nil

    var errorMessageMax: String? = nil
    
    var systemImage: String? = nil
    
    var currencySymbol: String?
    
    var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.allowsFloats = true
        if let currencySymbol = currencySymbol {
            f.numberStyle = .currency
            f.isLenient = true
            f.currencySymbol = currencySymbol
            f.maximumFractionDigits = grocyVM.userSettings?.stockDecimalPlacesPricesInput ?? 2
        } else {
            f.numberStyle = .decimal
            f.maximumFractionDigits = grocyVM.userSettings?.stockDecimalPlacesAmounts ?? 2
        }
        return f
    }
    
    var smallestValidAmount: Double {
        let decPlaces = Int(grocyVM.userSettings?.stockDecimalPlacesAmounts ?? 4)
        let increment = 1 / pow(10, decPlaces)
        return (minAmount ?? 0.0) + Double(truncating: increment as NSNumber)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1){
            HStack{
                Text(LocalizedStringKey(description))
                if let descriptionU = descriptionInfo {
                    FieldDescription(description: descriptionU)
                }
            }
            HStack{
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                }
                TextField("", value: $amount, formatter: formatter)
#if os(macOS)
                    .frame(width: 90)
#elseif os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                    .submitLabel(.done)
#endif
                Stepper(
                    LocalizedStringKey(amountName ?? ""),
                    value: $amount,
                    in: -Double.greatestFiniteMagnitude...Double.greatestFiniteMagnitude,
                    step: 1.0
                )
                    .fixedSize()
            }
            if let minAmount = minAmount, amount < minAmount {
                Text("This cannot be lower than \(smallestValidAmount, specifier: "%.0f") and needs to be a valid number with max.  \(grocyVM.userSettings?.stockDecimalPlacesAmounts ?? 4) decimal places")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let maxAmount = maxAmount, amount > maxAmount, let errorMessageMax = errorMessageMax {
                Text(LocalizedStringKey(errorMessageMax))
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}


struct MyDoubleStepperOptional: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Binding var amount: Double?
    
    var description: String
    var descriptionInfo: String? = nil
    var minAmount: Double? = 0.0
    var maxAmount: Double? = nil
    var amountStep: Double? = 1.0
    var amountName: String? = nil

    var errorMessageMax: String? = nil
    
    var systemImage: String? = nil
    
    var currencySymbol: String?
    
    var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.allowsFloats = true
        if let currencySymbol = currencySymbol {
            f.numberStyle = .currency
            f.isLenient = true
            f.currencySymbol = currencySymbol
            f.maximumFractionDigits = grocyVM.userSettings?.stockDecimalPlacesPricesInput ?? 2
        } else {
            f.numberStyle = .decimal
            f.maximumFractionDigits = grocyVM.userSettings?.stockDecimalPlacesAmounts ?? 2
        }
        return f
    }
    
    var smallestValidAmount: Double {
        let decPlaces = Int(grocyVM.userSettings?.stockDecimalPlacesAmounts ?? 4)
        let increment = 1 / pow(10, decPlaces)
        return (minAmount ?? 0.0) + Double(truncating: increment as NSNumber)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1){
            HStack{
                Text(LocalizedStringKey(description))
                if let descriptionU = descriptionInfo {
                    FieldDescription(description: descriptionU)
                }
            }
            HStack{
                if systemImage != nil {
                    Image(systemName: systemImage!)
                }
                // Decimal keypad doesn't have a confirm button to confirm the entry yet
                TextField("", value: $amount, formatter: formatter)
#if os(macOS)
                    .frame(width: 90)
#elseif os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                    .submitLabel(.done )
#endif
                Stepper(LocalizedStringKey(amountName ?? ""), onIncrement: {
                    if let previousAmount = amount {
                        amount = previousAmount + (amountStep ?? 1.0)
                    } else {
                        amount = amountStep
                    }
                }, onDecrement: {
                    if let previousAmount = amount {
                        if let minAmount = minAmount {
                            if previousAmount == minAmount {
                                amount = nil
                            } else if (previousAmount - (amountStep ?? 1.0) < minAmount) {
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
                })
                    .fixedSize()
            }
            if let minAmount = minAmount, let amount = amount, amount < minAmount {
                Text("This cannot be lower than \(smallestValidAmount.formattedAmount) and needs to be a valid number with max.  \(grocyVM.userSettings?.stockDecimalPlacesAmounts ?? 4) decimal places")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let maxAmount = maxAmount, let amount = amount, amount > maxAmount, let errorMessageMax = errorMessageMax {
                Text(LocalizedStringKey(errorMessageMax))
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct MyDoubleStepper_Previews: PreviewProvider {
    static var previews: some View {
        MyDoubleStepper(amount: Binding.constant(0), description: "Description", descriptionInfo: "Description info Text", minAmount: 1.0, amountStep: 0.1, amountName: "QuantityUnit", systemImage: "tag")
            .padding()
    }
}
