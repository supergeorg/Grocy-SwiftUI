//
//  MyNumberPicker.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MyIntStepper: View {
    @Binding var amount: Int
    
    var description: String
    var helpText: String?
    var minAmount: Int? = 0
    var amountName: String? = nil
    
    var errorMessage: String?
    
    var systemImage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1){
            HStack{
                Text(LocalizedStringKey(description))
                if let helpTextU = helpText {
                    FieldDescription(description: helpTextU)
                }
            }
            HStack{
                if systemImage != nil {
                    Image(systemName: systemImage!)
                }
                TextField("", value: $amount, formatter: NumberFormatter())
#if os(macOS)
                    .frame(width: 90)
#elseif os(iOS)
                    .keyboardType(.decimalPad)
#endif
                Stepper(LocalizedStringKey(amountName ?? ""), value: $amount, in: ((minAmount ?? 0)...(Int.max - 1)), step: 1)
                    .fixedSize()
            }
            if let minAmount = minAmount, let amount = amount, amount < minAmount, let errorMessage = errorMessage {
                Text(LocalizedStringKey(errorMessage))
                    .font(.caption)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct MyIntStepperOptional: View {
    @Binding var amount: Int?
    
    var description: String
    var helpText: String?
    var minAmount: Int? = 0
    var amountName: String? = nil
    
    var errorMessage: String?
    
    var systemImage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1){
            HStack{
                Text(LocalizedStringKey(description))
                if let helpTextU = helpText {
                    FieldDescription(description: helpTextU)
                }
            }
            HStack{
                if systemImage != nil {
                    Image(systemName: systemImage!)
                }
                TextField("", value: $amount, formatter: NumberFormatter())
#if os(macOS)
                    .frame(width: 90)
#elseif os(iOS)
                    .keyboardType(.decimalPad)
#endif
                Stepper(LocalizedStringKey(amountName ?? ""), onIncrement: {
                    if let previousAmount = amount {
                        amount = previousAmount + 1
                    } else {
                        amount = 1
                    }
                }, onDecrement: {
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
                })
                    .fixedSize()
            }
            if let minAmount = minAmount, let amount = amount, amount < minAmount, let errorMessage = errorMessage {
                Text(LocalizedStringKey(errorMessage))
                    .font(.caption)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct MyIntStepper_Previews: PreviewProvider {
    static var previews: some View {
        MyIntStepper(amount: Binding.constant(1), description: "Description", helpText: "Help Text", minAmount: 1, amountName: "QuantityUnit")
            .padding()
    }
}
