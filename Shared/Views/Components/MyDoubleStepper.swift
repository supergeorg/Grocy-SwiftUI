//
//  MyDoublePicker.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MyDoubleStepper: View {
    @Binding var amount: Double
    
    var description: String
    var descriptionInfo: String?
    var minAmount: Double
    var amountStep: Double
    var amountName: String? = nil
    
    var errorMessage: String?
    
    var systemImage: String?
    
    var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.allowsFloats = true
        f.numberStyle = .decimal
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
                TextField("", value: $amount, formatter: formatter)
                    .frame(width: 50)
                Stepper(LocalizedStringKey(amountName ?? ""), onIncrement: {
                    amount += amountStep
                }, onDecrement: {
                    if amount > minAmount {
                        amount -= amountStep
                    }
                })
            }
            if amount < minAmount {
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

struct MyDoubleStepper_Previews: PreviewProvider {
    static var previews: some View {
        MyDoubleStepper(amount: Binding.constant(0), description: "Description", descriptionInfo: "Description info Text", minAmount: 1.0, amountStep: 0.1, amountName: "QuantityUnit", errorMessage: "Error in inputsadksaklwkfleksfklmelsfmlklkmlmgkelsmkgmlemkl", systemImage: "tag")
            .padding()
    }
}
