//
//  MDProductFormOFFView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 22.10.23.
//

import SwiftUI

struct MDProductFormOFFView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @StateObject var offVM: OpenFoodFactsViewModel
    
    @Binding var name: String
    @State private var barcode: String
    
    init(barcode: String, name: Binding<String>) {
        self._offVM = StateObject(wrappedValue: OpenFoodFactsViewModel(barcode: barcode))
        self.barcode = barcode
        self._name = name
    }
    
    var productNames: [String: String] {
        if let offData = offVM.offData {
            let allProductNames = [
                "generic": offData.product.productName,
                "en": offData.product.productNameEn,
                "de": offData.product.productNameDe,
                "fr": offData.product.productNameFr,
                "pl": offData.product.productNamePl
            ]
            
            return allProductNames.compactMapValues({ $0 }).filter({ !$0.value.isEmpty })
        } else {
            return [:]
        }
    }
    
    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundProduct = grocyVM.mdProducts.first(where: {$0.name == name})
        return !(name.isEmpty || foundProduct != nil)
    }
    
    var body: some View {
        Group {
            VStack {
                if let imageLink = offVM.offData?.product.imageThumbURL, let imageURL = URL(string: imageLink) {
                    AsyncImage(url: imageURL, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(Color.white)
                    }, placeholder: {
                        ProgressView()
                    })
                    .frame(maxWidth: 150.0, maxHeight: 150.0)
                }
                MyTextField(textToEdit: Binding.constant(barcode), description: "Barcode", isCorrect: Binding.constant(true), leadingIcon: MySymbols.barcode)
                    .disabled(true)
            }
            
            if productNames.isEmpty {
                MyTextField(textToEdit: $name, description: "Product name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "A name is required", errorMessage: "Name already exists")
                    .onChange(of: name) {
                        isNameCorrect = checkNameCorrect()
                    }
            } else {
                Picker(selection: $name, content: {
                    ForEach(productNames.sorted(by: >), id: \.key) { key, value in
                        Text("\(value) (\(key))").tag(value)
                    }
                }, label: {
                    HStack{
                        Image(systemName: "tag")
                        VStack(alignment: .leading){
                            Text("Product name")
                            if name.isEmpty {
                                Text("A name is required")
                                    .font(.caption)
                                    .foregroundStyle(Color.red)
                            } else if !isNameCorrect {
                                Text("Name already exists")
                                    .font(.caption)
                                    .foregroundStyle(Color.red)
                            }
                        }
                    }
                })
                .onChange(of: name) {
                    isNameCorrect = checkNameCorrect()
                }
            }
        }
    }
}

//#Preview {
//    MDProductFormOFFView()
//}
