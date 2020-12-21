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
    
    @State private var showInfo: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1){
            HStack{
                Text(description.localized)
                if helpText != nil {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.caption)
                        .onTapGesture {
                            showInfo.toggle()
                        }
                        .popover(isPresented: $showInfo, content: {
                            Text(helpText!.localized).padding()
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
                        Text(errorMessage!.localized)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(width: 200)
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
