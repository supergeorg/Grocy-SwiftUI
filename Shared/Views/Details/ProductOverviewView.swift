//
//  ProductOverviewView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 30.11.20.
//

import SwiftUI
import URLImage

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
        Form{
            Text(productDetails.name)
                .font(.title)
            
            Text(LocalizedStringKey("str.details.amount")).bold()
                +
                Text("\(formatAmount(productDetails.stockEntriesAmount)) \(productDetails.stockEntriesAmount == 1 ? productDetails.quantityUnit?.name ?? "" : productDetails.quantityUnit?.namePlural ?? "")")
            
            Text(LocalizedStringKey("str.details.stockValue")).bold()
                +
                Text("\(String(format: "%.2f", productDetails.stockValue)) \(productDetails.currency)")
            
            Text(LocalizedStringKey("str.details.defaultLocation")).bold()
                +
                Text(productDetails.defaultLocationName)
            
            Text(LocalizedStringKey("str.details.lastPurchaseDate")).bold()
                +
                Text(formatDateOutput(productDetails.lastPurchaseDate) ?? "str.details.never")
            
            Text(LocalizedStringKey("str.details.lastUseDate")).bold()
                +
                Text(LocalizedStringKey(formatDateOutput(productDetails.lastUseDate) ?? "str.details.never"))
            
            Text(LocalizedStringKey("str.details.lastPrice")).bold()
                +
                Text(productDetails.lastPrice > 0 ? LocalizedStringKey("\(String(productDetails.lastPrice)) \(productDetails.currency) per \(productDetails.quantityUnit?.name ?? "QU")") : LocalizedStringKey("str.details.unknown"))
            
            Text(LocalizedStringKey("str.details.averagePrice")).bold()
                +
                Text(productDetails.averagePrice > 0 ? LocalizedStringKey("\(String(format: "%.2f", productDetails.averagePrice)) \(productDetails.currency) per \(productDetails.quantityUnit?.name ?? "QU")") : LocalizedStringKey("str.details.unknown"))
            
            Text(LocalizedStringKey("str.details.averageShelfLife")).bold()
                +
                Text(productDetails.averageShelfLife ?? 0 > 0 ? LocalizedStringKey(formatDays(daysToFormat: productDetails.averageShelfLife) ?? "str.details.unknown") : LocalizedStringKey("str.details.unknown"))
            
            if let pictureURL = productDetails.pictureURL {
                if let url = URL(string: pictureURL) {
                    URLImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(Color.white)
                    }
                    .frame(width: 50, height: 50)
                }
            }
        }
        .toolbar(content: {
//            ToolbarItem(placement: .automatic){
//                HStack{
//                    Button(action: {
//                        print("")
//                    }, label: {Text(LocalizedStringKey("str.details.stockEntries"))})
//                    Button(action: {
//                        print("")
//                    }, label: {Text(LocalizedStringKey("str.details.stockJournal"))})
//                    Button(action: {
//                        self.presentationMode.wrappedValue.dismiss()
//                    }, label: {Label(LocalizedStringKey("str.details.edit"), systemImage: "square.and.pencil")})
//                }
//            }
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
