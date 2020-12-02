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
    var descriptionInfo: String?
    var minAmount: Int = 0
    var amountName: String? = nil
    
    var errorMessage: String?
    
    var systemImage: String?
    
    @State private var showInfo: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1){
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
                if systemImage != nil {
                    Image(systemName: systemImage!)
                }
                TextField("", value: $amount, formatter: NumberFormatter())
                    .frame(width: 50)
                Stepper((amountName ?? "").localized, onIncrement: {
                    amount += 1
                }, onDecrement: {
                    if amount > minAmount {
                        amount -= 1
                    }
                })
            }
            if amount < minAmount {
                if errorMessage != nil {
                    Text(errorMessage!.localized)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(width: 200)
                }
            }
        }
    }
}

struct MyIntStepper_Previews: PreviewProvider {
    static var previews: some View {
        MyIntStepper(amount: Binding.constant(1), description: "Description", descriptionInfo: "Description info Text", minAmount: 1, amountName: "QuantityUnit")
            .padding()
    }
}
