//
//  MyNumberPicker.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MyNumberStepper: View {
    @Binding var amount: Int
    
    var description: String
    var descriptionInfo: String?
    var minAmount: Int = 0
    var amountName: String? = nil
    
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
                    amount += 1
                }, onDecrement: {
                    if amount > minAmount {
                        amount -= 1
                    }
                })
            }
        }
    }
}

struct MyNumberStepper_Previews: PreviewProvider {
    static var previews: some View {
        MyNumberStepper(amount: Binding.constant(1), description: "Description", descriptionInfo: "Description info Text", minAmount: 1, amountName: "QuantityUnit")
            .padding()
    }
}
