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
    
    //    @Binding var isCorrect: Bool
    var errorMessage: String?
    
    @State private var showInfo: Bool = false
    
    var body: some View {
        VStack(alignment: .leading){
            HStack{
                Text(description.localized)
                if descriptionInfo != nil {
                    Button(action: {
                        showInfo.toggle()
                    }, label: {
                        Image(systemName: "questionmark.circle.fill")
                    })
                    .popover(isPresented: $showInfo, content: {
                        Text(descriptionInfo!.localized)
                    })
                }
            }
            HStack{
                TextField("", value: $amount, formatter: NumberFormatter())
                Stepper((amountName ?? "").localized, onIncrement: {
                    amount += amountStep
                }, onDecrement: {
                    if amount > minAmount {
                        amount -= amountStep
                    }
                })
            }
            if amount < minAmount {
                if errorMessage != nil {
                    Text(errorMessage!.localized)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct MyDoubleStepper_Previews: PreviewProvider {
    static var previews: some View {
        MyDoubleStepper(amount: Binding.constant(1), description: "Description", descriptionInfo: "Description info Text", minAmount: 1.0, amountStep: 0.1, amountName: "QuantityUnit", errorMessage: "Error in input")
            .padding()
    }
}
