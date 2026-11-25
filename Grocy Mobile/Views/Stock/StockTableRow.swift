//
//  StockTableRow.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 28.12.20.
//

import SwiftData
import SwiftUI

struct StockTableRow: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.grocyFeatures) private var features
    @AppStorage("localizationKey") var localizationKey: String = "en"

    #if os(iOS)
        @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
        @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    #endif

    var stockElement: StockElement

    // Pass data from parent to avoid duplicate queries
    let mdQuantityUnits: MDQuantityUnits
    let shoppingList: [ShoppingListItem]
    let mdProductGroups: MDProductGroups
    let volatileStock: VolatileStock?
    let parentProduct: MDProduct?
    let userSettings: GrocyUserSettings?

    @State private var showDetailView: Bool = false

    var quantityUnit: MDQuantityUnit? {
        mdQuantityUnits.first(where: { $0.id == stockElement.product?.quIDStock })
    }

    /// The status the row is highlighted for. Same order as before: due soon wins over expired, overdue and below min. stock.
    var productStatus: ProductStatus? {
        let productID = stockElement.productID

        // Without due date tracking, only "below min. stock" applies.
        if features.dueDateTracking, (volatileStock?.dueProducts ?? []).contains(where: { $0.productID == productID }) {
            return .expiringSoon
        }
        if features.dueDateTracking, (volatileStock?.expiredProducts ?? []).contains(where: { $0.productID == productID }) {
            return .expired
        }
        if features.dueDateTracking, (volatileStock?.overdueProducts ?? []).contains(where: { $0.productID == productID }) {
            return .overdue
        }
        if (volatileStock?.missingProducts ?? []).contains(where: { $0.productID == productID }) {
            return .belowMinStock
        }
        return nil
    }

    var backgroundColor: Color? {
        switch productStatus {
        case .expiringSoon:
            return Color(.GrocyColors.grocyYellowBackground)
        case .expired:
            return Color(.GrocyColors.grocyRedBackground)
        case .overdue:
            return Color(.GrocyColors.grocyGrayBackground)
        case .belowMinStock:
            return Color(.GrocyColors.grocyBlueBackground)
        default:
            return nil
        }
    }

    var body: some View {
        NavigationLink(
            value: StockEntriesDestination(productID: stockElement.productID),
            label: {
                content
            }
        )
        .contextMenu {
            StockTableMenuEntriesView(stockElement: stockElement, quantityUnit: mdQuantityUnits.first(where: { $0.id == stockElement.product?.quIDStock }))
        }
        .swipeActions(
            edge: .leading,
            allowsFullSwipe: true
        ) {
            if stockElement.amount > 0 {
                StockTableRowActionsView(stockElement: stockElement, shownActions: [.consumeQA], mdQuantityUnits: mdQuantityUnits)
            }
            if features.openedTracking, (stockElement.amount - stockElement.amountOpened) > 0 {
                StockTableRowActionsView(stockElement: stockElement, shownActions: [.openQA], mdQuantityUnits: mdQuantityUnits)
            }
        }
        // No full swipe here: it consumed the whole stock by accident, so "All" needs a deliberate tap (#225).
        .swipeActions(
            edge: .trailing,
            allowsFullSwipe: false
        ) {
            if stockElement.amount > 0 {
                StockTableRowActionsView(stockElement: stockElement, shownActions: [.consumeAll], mdQuantityUnits: mdQuantityUnits)
            }
        }
        .listRowBackground(backgroundColor)
    }

    var content: some View {
        #if os(iOS)
            Group {
                if horizontalSizeClass == .compact && verticalSizeClass == .regular {
                    HStack {
                        VStack(alignment: .leading) {
                            stockElementNameAndActions
                            stockElementDetails
                        }
                        Spacer()
                    }
                } else {
                    HStack {
                        stockElementNameAndActions
                        stockElementDetails
                        Spacer()
                    }
                }
            }
        #elseif os(macOS)
            HStack {
                stockElementNameAndActions
                stockElementDetails
                Spacer()
            }
        #endif
    }

    var stockElementNameAndActions: some View {
        Text(stockElement.product?.name ?? "")
            .font(.headline)
    }

    var stockElementDetails: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            // The status is also spelled out, not only shown by the row's background color (HIG),
            // with the same wording and symbols as the stock filter.
            if let productStatus {
                // An HStack instead of a Label: in a list row, a Label's icon gets its own wide, tinted column.
                HStack(spacing: Spacing.xxSmall) {
                    Image(systemName: productStatus.getIconName())
                        .accessibilityHidden(true)
                    Text(productStatus.rawValue)
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            }
            // Product group
            if let productGroup = mdProductGroups.first(where: { $0.id == stockElement.product?.productGroupID }) {
                HStack {
                    Image(systemName: MySymbols.productGroup)
                    Text(productGroup.name)
                }
                .font(.caption)
                .foregroundStyle(.primary)
            }

            // Parent product
            if let parentProduct {
                HStack {
                    Image(systemName: MySymbols.parentProduct)
                    Text(parentProduct.name)
                }
                .font(.caption)
                .foregroundStyle(.primary)
            }

            // A flow layout, not an HStack: in a narrow row (the outer display of iPhone Duo, beside its vertical bar)
            // an HStack squeezes the texts until words break ("Pack / s"); this moves whole items to the next line.
            FlowLayout(spacing: Spacing.small) {
                Text("\(stockElement.amount.formattedAmount) \(quantityUnit?.getName(amount: stockElement.amount) ?? "")")
                if features.openedTracking, stockElement.amountOpened > 0 {
                    Text("\(stockElement.amountOpened.formattedAmount) opened")
                        .font(.caption)
                        .italic()
                }
                if stockElement.amount != stockElement.amountAggregated {
                    Text("Σ \(stockElement.amountAggregated.formattedAmount) \(quantityUnit?.getName(amount: stockElement.amountAggregated) ?? "")")
                        .foregroundStyle(Color(.GrocyColors.grocyGray))
                    if features.openedTracking, stockElement.amountOpenedAggregated > 0 {
                        Text("\(stockElement.amountOpenedAggregated.formattedAmount) opened")
                            .foregroundStyle(Color(.GrocyColors.grocyGray))
                            .font(.caption)
                            .italic()
                    }
                }
                if userSettings?.showIconOnStockOverviewPageWhenProductIsOnShoppingList ?? true,
                    shoppingList.first(where: { $0.productID == stockElement.productID }) != nil
                {
                    Image(systemName: MySymbols.shoppingList)
                        .foregroundStyle(Color(.GrocyColors.grocyGray))
                        .help("This product is currently on a shopping list.")
                        .accessibilityLabel(Text("This product is currently on a shopping list."))
                }
                if !features.dueDateTracking {
                    EmptyView()
                } else if stockElement.bestBeforeDate == Date.neverOverdue {
                    Text("Never overdue")
                } else {
                    Text(formatDateAsString(stockElement.bestBeforeDate, showTime: false, localizationKey: localizationKey) ?? "")
                    Text(getRelativeDateAsText(stockElement.bestBeforeDate, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }
            }
        }
    }
}

#Preview(traits: .previewData) {
    List {
        StockTableRow(
            stockElement: StockElement(
                amount: 2,
                amountAggregated: 2,
                value: 3.5,
                bestBeforeDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                amountOpened: 1,
                amountOpenedAggregated: 1,
                productID: 1,
                product: MDProduct(id: 1, name: "Cookies")
            ),
            mdQuantityUnits: [],
            shoppingList: [],
            mdProductGroups: [],
            volatileStock: nil,
            parentProduct: nil,
            userSettings: nil
        )
    }
    .environment(StockInteractionNavigationRouter())
}
