//
//  StockTableRow.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 28.12.20.
//

import SwiftData
import SwiftUI

/// The objects the stock rows look up by ID, as dictionaries built once per list: searching the master data arrays
/// in every row made the stock overview slow with a large household. The rows keep only what they looked up in it.
struct StockRowLookups {
    var quantityUnitsByID: [Int: MDQuantityUnit] = [:]
    var productGroupsByID: [Int: MDProductGroup] = [:]
    var productsByID: [Int: MDProduct] = [:]
    var productIDsOnShoppingList: Set<Int> = []
    /// The status a row is highlighted for: due soon wins over expired, overdue and below min. stock.
    var statusByProductID: [Int: ProductStatus] = [:]

    init() {}

    init(
        quantityUnits: MDQuantityUnits,
        productGroups: MDProductGroups,
        products: MDProducts,
        shoppingList: [ShoppingListItem],
        volatileStock: VolatileStock?,
        dueDateTracking: Bool
    ) {
        quantityUnitsByID = Dictionary(quantityUnits.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        productGroupsByID = Dictionary(productGroups.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        productsByID = Dictionary(products.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        productIDsOnShoppingList = Set(shoppingList.compactMap(\.productID))

        // From the lowest priority to the highest, so a higher one overwrites a lower one.
        // Without due date tracking, only "below min. stock" applies.
        for product in volatileStock?.missingProducts ?? [] {
            statusByProductID[product.productID] = .belowMinStock
        }
        if dueDateTracking, let volatileStock {
            for product in volatileStock.overdueProducts {
                statusByProductID[product.productID] = .overdue
            }
            for product in volatileStock.expiredProducts {
                statusByProductID[product.productID] = .expired
            }
            for product in volatileStock.dueProducts {
                statusByProductID[product.productID] = .expiringSoon
            }
        }
    }
}

struct StockTableRow: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.grocyFeatures) private var features
    @AppStorage("localizationKey") var localizationKey: String = "en"

    #if os(iOS)
        @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
        @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    #endif

    var stockElement: StockElement

    // Only the values this row needs, looked up once in the init: SwiftUI compares a view's stored properties on every
    // update, and storing the whole lookups compared all products for each row.
    let quantityUnit: MDQuantityUnit?
    let productGroup: MDProductGroup?
    let parentProduct: MDProduct?
    /// The status the row is highlighted for.
    let productStatus: ProductStatus?
    let isOnShoppingList: Bool
    let userSettings: GrocyUserSettings?

    @State private var showDetailView: Bool = false

    init(stockElement: StockElement, lookups: StockRowLookups, userSettings: GrocyUserSettings?) {
        self.stockElement = stockElement
        let product = stockElement.product
        quantityUnit = product.flatMap { lookups.quantityUnitsByID[$0.quIDStock] }
        productGroup = product?.productGroupID.flatMap { lookups.productGroupsByID[$0] }
        parentProduct = product?.parentProductID.flatMap { lookups.productsByID[$0] }
        productStatus = lookups.statusByProductID[stockElement.productID]
        isOnShoppingList = lookups.productIDsOnShoppingList.contains(stockElement.productID)
        self.userSettings = userSettings
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
            StockTableMenuEntriesView(stockElement: stockElement, quantityUnit: quantityUnit)
        }
        .swipeActions(
            edge: .leading,
            allowsFullSwipe: true
        ) {
            if stockElement.amount > 0 {
                StockTableRowActionsView(stockElement: stockElement, shownActions: [.consumeQA], quantityUnit: quantityUnit)
            }
            if features.openedTracking, (stockElement.amount - stockElement.amountOpened) > 0 {
                StockTableRowActionsView(stockElement: stockElement, shownActions: [.openQA], quantityUnit: quantityUnit)
            }
        }
        // No full swipe here: it consumed the whole stock by accident, so "All" needs a deliberate tap (#225).
        .swipeActions(
            edge: .trailing,
            allowsFullSwipe: false
        ) {
            if stockElement.amount > 0 {
                StockTableRowActionsView(stockElement: stockElement, shownActions: [.consumeAll], quantityUnit: quantityUnit)
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
            if let productGroup {
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
                    isOnShoppingList
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
            lookups: StockRowLookups(),
            userSettings: nil
        )
    }
    .environment(StockInteractionNavigationRouter())
}
