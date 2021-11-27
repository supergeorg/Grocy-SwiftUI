//
//  MyDoubleStepper.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MyDoubleStepper: View {
    @Binding var amount: Double
    
    var description: String
    var descriptionInfo: String? = nil
    var minAmount: Double? = 0.0
    var maxAmount: Double? = nil
    var amountStep: Double? = 1.0
    var amountName: String? = nil
    
    var errorMessage: String? = nil
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
        } else {
            f.numberStyle = .decimal
        }
        f.maximumFractionDigits = 4
        return f
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
                    .frame(width: 70)
#if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                    .submitLabel(.done )
#endif
                Stepper(LocalizedStringKey(amountName ?? ""), onIncrement: {
                    amount += amountStep ?? 1.0
                }, onDecrement: {
                    if let minAmount = minAmount {
                        if amount > minAmount {
                            amount -= amountStep ?? 1.0
                        }
                    } else { amount -= amountStep ?? 1.0 }
                })
            }
            if let minAmount = minAmount {
                if let amount = amount {
                    if amount < minAmount {
                        if let errorMessage = errorMessage {
                            Text(LocalizedStringKey(errorMessage))
                                .font(.caption)
                                .foregroundColor(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            if let maxAmount = maxAmount {
                if let amount = amount {
                    if amount > maxAmount {
                        if let errorMessageMax = errorMessageMax {
                            Text(LocalizedStringKey(errorMessageMax))
                                .font(.caption)
                                .foregroundColor(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }
}


struct MyDoubleStepperOptional: View {
    @Binding var amount: Double?
    
    var description: String
    var descriptionInfo: String? = nil
    var minAmount: Double? = 0.0
    var maxAmount: Double? = nil
    var amountStep: Double? = 1.0
    var amountName: String? = nil
    
    var errorMessage: String? = nil
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
        } else {
            f.numberStyle = .decimal
        }
        f.maximumFractionDigits = 4
        return f
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
                    .frame(width: 70)
#if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                    .submitLabel(.done )
#endif
                Stepper(LocalizedStringKey(amountName ?? ""), onIncrement: {
                    if amount != nil {
                        amount! += amountStep ?? 1.0
                    } else { amount = amountStep }
                }, onDecrement: {
                    if amount != nil {
                        if minAmount != nil {
                            if amount! > minAmount! {
                                amount! -= amountStep ?? 1.0
                            } else if ((currencySymbol != nil) && (amount! == 0.0)) { amount = nil}
                        } else { amount! -= amountStep ?? 1.0 }
                    } else { amount = 0 }
                })
            }
            if let minAmount = minAmount {
                if let amount = amount {
                    if amount < minAmount {
                        if let errorMessage = errorMessage {
                            Text(LocalizedStringKey(errorMessage))
                                .font(.caption)
                                .foregroundColor(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            if let maxAmount = maxAmount {
                if let amount = amount {
                    if amount > maxAmount {
                        if let errorMessageMax = errorMessageMax {
                            Text(LocalizedStringKey(errorMessageMax))
                                .font(.caption)
                                .foregroundColor(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }
}

struct MyDoubleStepper_Previews: PreviewProvider {
    static var previews: some View {
        MyDoubleStepper(amount: Binding.constant(0), description: "Description", descriptionInfo: "Description info Text", minAmount: 1.0, amountStep: 0.1, amountName: "QuantityUnit", errorMessage: "Error in inputsadksaklwkfleksfklmelsfmlklkmlmgkelsmkgmlemkl", systemImage: "tag")
            .padding()
    }
}
