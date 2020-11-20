//
//  PurchaseProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import SwiftUI

struct PurchaseProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var product: MDProduct? = nil
    @State private var amount: Int = 0
    @State private var quantityUnit: MDQuantityUnit? = nil
    @State private var dueDate: Date = Date()
    @State private var productDoesntSpoil: Bool = false
    @State private var price: Double? = nil
    @State private var isTotalPrice: Bool = false
    @State private var shoppingLocation: MDShoppingLocation? = nil
    @State private var location: MDLocation? = nil
    
    @State private var searchProductTerm: String = ""
    private var filteredProducts: [MDProduct] {
        grocyVM.mdProducts.filter {
            searchProductTerm.isEmpty ? true : $0.name.lowercased().contains(searchProductTerm.lowercased())
        }
    }
    
    func getQuantityUnit() -> MDQuantityUnit? {
        let quIDP = grocyVM.mdProducts.first(where: {$0.id == product?.id})?.quIDPurchase
        let qu = grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
        return qu
    }
    private var currentQuantityUnit: MDQuantityUnit {
        getQuantityUnit() ?? MDQuantityUnit(id: "0", name: "Stück", mdQuantityUnitDescription: "", rowCreatedTimestamp: "", namePlural: "Stücke", pluralForms: nil, userfields: nil)
    }
    
    private let priceFormatter = NumberFormatter()
    
    private func updateData() {
        grocyVM.getMDProducts()
        grocyVM.getMDLocations()
        grocyVM.getMDShoppingLocations()
    }
    
    var body: some View {
        Form {
            Picker(selection: $product, label: Text("")) {
                SearchBar(text: $searchProductTerm, placeholder: "str.search")
                ForEach(filteredProducts, id: \.id) { productElement in
                    Text(productElement.name).tag(productElement.id)
                }
            }
            .onChange(of: product) { newProduct in
                if (location == nil || shoppingLocation == nil) {
                    if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == product?.id}) {
                        if location == nil { location = grocyVM.mdLocations.first(where: {$0.id == selectedProduct.locationID})  }
                        if shoppingLocation == nil { shoppingLocation = grocyVM.mdShoppingLocations.first(where: {$0.id == selectedProduct.shoppingLocationID}) }
                    }
                }
            }
            
            HStack {
                MyNumberStepper(amount: $amount, description: "Amount", minAmount: 0, amountName: amount > 1 ? currentQuantityUnit.namePlural : currentQuantityUnit.name)
//                Picker(selection: $quantityUnit, label: "QuantityUnit", content: {
//                    Text("").tag(nil)
//                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
//                        Text(pickerQU.name).tag(pickerQU.id)
//                    }
//                })
            }
        }
    }
}

struct PurchaseProductView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseProductView()
    }
}
