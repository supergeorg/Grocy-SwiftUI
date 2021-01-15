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
                    .frame(width: 50)
                Stepper(LocalizedStringKey(amountName ?? ""), onIncrement: {
                    amount += 1
                }, onDecrement: {
                    if minAmount != nil {
                        if amount > minAmount! {
                            amount -= 1
                        }
                    } else {amount -= 1}
                })
            }
            if minAmount != nil {
                if amount < minAmount! {
                    if errorMessage != nil {
                        Text(LocalizedStringKey(errorMessage!))
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(width: 250)
                    }
                }
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