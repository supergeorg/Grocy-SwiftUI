//
//  AmountSelectionView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 14.10.21.
//

import SwiftData
import SwiftUI

struct AmountSelectionView: View {
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions

    @Binding var productID: Int?
    @Binding var amount: Double
    @Binding var quantityUnitID: Int?

    private var product: MDProduct? {
        mdProducts.first(where: { $0.id == productID })
    }

    private var conversionResolver: QuantityUnitConversionResolver? {
        product.map { QuantityUnitConversionResolver(product: $0, conversions: mdQuantityUnitConversions) }
    }

    /// Only the units this product can be converted to and from, each once (#192).
    private var convertibleQuantityUnits: [MDQuantityUnit] {
        (conversionResolver?.convertibleQuIDs ?? []).compactMap { quID in mdQuantityUnits.first(where: { $0.id == quID }) }
    }

    private var currentQuantityUnit: MDQuantityUnit? {
        if let quantityUnitID = quantityUnitID {
            return mdQuantityUnits.first(where: { $0.id == quantityUnitID })
        } else {
            return nil
        }
    }
    private var factoredAmount: Double {
        conversionResolver?.stockAmount(amount, in: quantityUnitID) ?? amount
    }
    private var stockQuantityUnit: MDQuantityUnit? {
        mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }

    var body: some View {
        Section(header: Text("Amount").font(.headline)) {
            MyDoubleStepper(
                amount: $amount,
                description: "Amount",
                amountStep: 1.0,
                amountName: currentQuantityUnit?.getName(amount: amount),
                systemImage: MySymbols.amount
            )

            if productID != nil {
                VStack(alignment: .leading) {
                    Picker(
                        selection: $quantityUnitID,
                        label: Label("Quantity unit", systemImage: MySymbols.quantityUnit).foregroundStyle(.primary),
                        content: {
                            Text("")
                                .tag(nil as Int?)
                            ForEach(convertibleQuantityUnits, id: \.id) { quantityUnit in
                                Text(quantityUnit.name)
                                    .tag(quantityUnit.id)
                            }
                        }
                    )
                    .disabled(convertibleQuantityUnits.count <= 1)
                    if quantityUnitID == nil {
                        Text("A quantity unit is required")
                            .font(.caption)
                            .foregroundStyle(Color(.GrocyColors.grocyRed))
                    } else if quantityUnitID != stockQuantityUnit?.id {
                        Text(
                            "This equals \(factoredAmount.formatted(.number.precision(.fractionLength(0...8)))) \(factoredAmount == 1 ? stockQuantityUnit?.name ?? "?" : stockQuantityUnit?.namePlural ?? "?")"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview(traits: .previewData) {
    @Previewable @State var quantityUnitID: Int? = nil
    @Previewable @State var amount: Double = 250.0

    Form {
        AmountSelectionView(
            productID: .constant(1),
            amount: $amount,
            quantityUnitID: $quantityUnitID
        )
    }
}
