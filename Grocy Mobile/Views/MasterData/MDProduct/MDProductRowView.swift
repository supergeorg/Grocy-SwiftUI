//
//  MDProductRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 22.10.23.
//

import SwiftData
import SwiftUI

struct MDProductRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var product: MDProduct
    var location: MDLocation?
    var productGroup: MDProductGroup?

    var body: some View {
        HStack {
            if let pictureFileName = product.pictureFileName {
                PictureView(pictureFileName: pictureFileName, pictureType: .productPictures)
                    .clipShape(.rect(cornerRadius: 5.0))
                    .frame(maxWidth: 75.0, maxHeight: 75.0)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading) {
                Text(product.name)
                    .font(.headline)
                    .foregroundStyle(product.active ? .primary : .secondary)
                // Disabled is spelled out, not only shown by the dimmed color ("Disabled" matches the Grocy web app).
                if !product.active {
                    Text("Disabled")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Group {
                    if let locationName = location?.name {
                        Text("\(Text("Location")): \(Text(locationName))")
                    }
                    if let productGroupName = productGroup?.name {
                        Text("\(Text("Product group")): \(Text(productGroupName))")
                    }
                    if !product.mdProductDescription.isEmpty {
                        Text(product.mdProductDescription)
                            .italic()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .previewData) {
    List {
        MDProductRowView(
            product: MDProduct(
                id: 1,
                name: "Product",
            ),
            location: nil,
            productGroup: nil
        )
        MDProductRowView(
            product: MDProduct(
                id: 2,
                name: "Product 2",
                mdProductDescription: "Description",
                productGroupID: 1,
                locationID: 2,
            ),
            location: nil,
            productGroup: nil
        )
    }
}
