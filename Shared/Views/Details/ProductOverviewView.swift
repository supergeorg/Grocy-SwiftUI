//
//  ProductOverviewView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 30.11.20.
//

import SwiftUI

struct ProductOverviewView: View {
    var productDetails: ProductDetailsModel
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        #if os(macOS)
//        NavigationView{
        content
            .padding()
//            .frame(width: 200, height: 300, alignment: .center)
//        }
        #elseif os(iOS)
        content
                .navigationTitle(LocalizedStringKey("str.details.title"))
        #endif
    }
    
    var content: some View {
        VStack{
            Text(productDetails.name)
                .font(.title)
            
            Text("\("str.details.amount".localized): ").bold()
                +
                Text("\(formatAmount(productDetails.stockEntriesAmount)) \(productDetails.stockEntriesAmount == 1 ? productDetails.quantityUnit.name : productDetails.quantityUnit.namePlural)")
            
            Text("\("str.details.stockValue".localized): ").bold()
                +
                Text("\(String(format: "%.2f", productDetails.stockValue)) \(productDetails.currency)")
            
            Text("\("str.details.defaultLocation".localized): ").bold()
                +
                Text("\(productDetails.defaultLocationName)")
            
            Text("\("str.details.lastPurchaseDate".localized): ").bold()
                +
                Text("\(formatDateOutput(productDetails.lastPurchaseDate) ?? "Never")")
            
            Text("\("str.details.lastUseDate".localized): ").bold()
                +
                Text("\(formatDateOutput(productDetails.lastUseDate) ?? "Never")")
            
            Text("\("str.details.lastPrice".localized): ").bold()
                +
                Text("\(productDetails.lastPrice > 0 ? String(productDetails.lastPrice) : "No last price") \(productDetails.currency) per \(productDetails.quantityUnit.name)")
            
            Text("\("str.details.averagePrice".localized): ").bold()
                +
                Text("\(String(format: "%.2f", productDetails.averagePrice)) \(productDetails.currency) per \(productDetails.quantityUnit.name)")
            
            Text("\("str.details.averageShelfLife".localized): ").bold()
                +
                Text(formatDays(daysToFormat: productDetails.averageShelfLife) ?? "Not recorded")
            
            if let pictureURL = productDetails.pictureURL {
                RemoteImageView(withURL: pictureURL)
            }
        }
        .toolbar(content: {
            ToolbarItem(placement: .automatic){
                HStack{
                    Button(action: {
                        print("")
                    }, label: {Text("str.details.stockEntries")})
                    Button(action: {
                        print("")
                    }, label: {Text("str.details.stockJournal")})
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {Label(LocalizedStringKey("str.details.edit"), systemImage: "square.and.pencil")})
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(LocalizedStringKey("str.ok")) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        })
    }
}

//struct ProductOverviewView_Previews: PreviewProvider {
//    static var previews: some View {
//            ProductOverviewView(product: MDProduct(id: "1", name: "Product name", mdProductDescription: "Product description", productGroupID: "1", active: "1", locationID: "1", shoppingLocationID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "0", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "TS", userfields: nil))
//    }
//}
