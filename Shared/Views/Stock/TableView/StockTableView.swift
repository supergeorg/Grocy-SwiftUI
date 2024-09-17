//
//  StockTable.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI
import SwiftData

struct StockTableView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @State private var searchString: String = ""
    @State private var sortOrder = [KeyPathComparator(\StockTableElement.product.name)]
    
    var filteredStock: Stock
    var tableStock: [StockTableElement] {
        var element_list: [StockTableElement] = []
        for stockElement in filteredStock{
            // TODO: last purchased Date, last Price, average Price
//            let table_element = StockTableElement(
//                product: stockElement.product ?? StockProduct(
//                    id: 0,
//                    name: "",
//                    mdProductDescription: "",
//                    productGroupID: nil,
//                    active: true,
//                    locationID: 0,
//                    storeID: nil,
//                    quIDPurchase: 0,
//                    quIDStock: 0,
//                    quIDConsume: 0,
//                    quIDPrice: 0,
//                    minStockAmount: 1.0,
//                    defaultDueDays: 0,
//                    defaultDueDaysAfterOpen: 0,
//                    defaultDueDaysAfterFreezing: 0,
//                    defaultDueDaysAfterThawing: 0,
//                    pictureFileName: nil,
//                    enableTareWeightHandling: false,
//                    tareWeight: nil,
//                    notCheckStockFulfillmentForRecipes: false,
//                    parentProductID: nil,
//                    calories: nil,
//                    cumulateMinStockAmountOfSubProducts: false,
//                    dueType: 0,
//                    quickConsumeAmount: nil,
//                    quickOpenAmount: nil,
//                    hideOnStockOverview: false,
//                    defaultStockLabelType: nil,
//                    shouldNotBeFrozen: false,
//                    treatOpenedAsOutOfStock: false,
//                    noOwnStock: false,
//                    defaultConsumeLocationID: nil,
//                    moveOnOpen: false,
//                    autoReprintStockLabel: false,
//                    rowCreatedTimestamp: Date().iso8601withFractionalSeconds
//                ),
//                productGroup: mdProductGroups.first(where:{ $0.id == stockElement.product?.productGroupID }),
//                amount: stockElement.amount,
//                quantityUnit: mdQuantityUnits.first(where: { $0.id == stockElement.product?.quIDStock }),
//                value: stockElement.value,
//                nextDueDate: stockElement.bestBeforeDate,
//                caloriesPerStockQU: stockElement.product?.calories,
//                calories: (stockElement.product?.calories ?? 0 * stockElement.amount),
//                lastPurchasedDate: nil,
//                lastPrice: nil,
//                minStockAmount: stockElement.product?.minStockAmount ?? 0.0,
//                productDescription: stockElement.product?.mdProductDescription ?? "",
//                parentProduct: mdProducts.first(where: { $0.id == stockElement.product?.parentProductID }),
//                defaultLocation: mdLocations.first(where: { $0.id == stockElement.product?.locationID }),
//                averagePrice: nil
//            )
//            element_list.append(table_element)
        }
        return element_list
    }
    
    var sortedStock: [StockTableElement] {
        tableStock.sorted(using: sortOrder)
    }
    
    @State var selectedStockElement: StockTableElement? = nil
//    @Binding var activeSheet: StockInteractionSheet?
    
    @SceneStorage("StockTableConfig")
    private var columnCustomization: TableColumnCustomization<StockTableElement>
    
    var body: some View {
//        Table(sortedStock, sortOrder: $sortOrder, columnCustomization: $columnCustomization, columns: {
//            Group {
//                TableColumn("Product", value: \StockTableElement.product.name)
//                    .customizationID("product")
//                
//                TableColumn("Product group", content: { (stockElement: StockTableElement) in
//                    Text(stockElement.productGroup?.name ?? "")
//                })
//                    .customizationID("productGroup")
//                
//                TableColumn("Amount", content: { (stockElement: StockTableElement) in
//                    HStack{
//                        if let quantityUnit = stockElement.quantityUnit {
//                            Text("\(stockElement.amount.formattedAmount) \(stockElement.amount == 1 ? quantityUnit.name : (quantityUnit.namePlural.isEmpty ? quantityUnit.name : quantityUnit.namePlural))")
//                        } else {
//                            Text("\(stockElement.amount.formattedAmount)")
//                        }
//                        if grocyVM.userSettings?.showIconOnStockOverviewPageWhenProductIsOnShoppingList ?? true,
//                           grocyVM.shoppingList.first(where: {$0.productID == stockElement.product?.id}) != nil {
//                            Image(systemName: MySymbols.shoppingList)
//                                .help("This product is currently on a shopping list.")
//                        }
//                    }
//                })
//                .customizationID("amount")
//                
//                TableColumn("Value", content: { (stockElement: StockTableElement) in
//                    Text(stockElement.value == 0 ? "" : grocyVM.getFormattedCurrency(amount: stockElement.amount))
//                })
//                .customizationID("value")
//                
//                TableColumn("Next due date", content: { (stockElement: StockTableElement) in
//                    HStack {
//                        if stockElement.nextDueDate == getNeverOverdueDate() {
//                            Text("Never overdue")
//                        } else {
//                            Text(formatDateAsString(stockElement.nextDueDate, showTime: false, localizationKey: localizationKey) ?? "")
//                            Text(getRelativeDateAsText(stockElement.nextDueDate, localizationKey: localizationKey) ?? "")
//                                .font(.caption)
//                                .italic()
//                        }
//                    }
//                })
//                .customizationID("nextDueDate")
//            }
//            
//            Group {
//                TableColumn("Calories (Per stock quantity unit)", content: { (stockElement: StockTableElement) in
//                    Text(stockElement.caloriesPerStockQU?.formattedAmount ?? "")
//                })
//                .customizationID("caloriesPerStockQU")
//                
//                TableColumn("Calories", content: { (stockElement: StockTableElement) in
//                    Text(stockElement.calories.formattedAmount)
//                })
//                .customizationID("calories")
//                
//                TableColumn("Last purchased", content: { (stockElement: StockTableElement) in
//                    Text(stockElement.lastPurchasedDate?.formatted() ?? "")
//                })
//                .customizationID("lastPurchasedDate")
//                
//                TableColumn("Last price", content: { (stockElement: StockTableElement) in
//                    Text(stockElement.lastPrice?.formattedAmount ?? "")
//                })
//                .customizationID("lastPrice")
//                
//                TableColumn("Min. stock amount", content: { (stockElement: StockTableElement) in
//                    if let quantityUnit = stockElement.quantityUnit {
//                        Text("\(stockElement.product?.minStockAmount.formattedAmount) \((stockElement.product?.minStockAmount == 1 ? quantityUnit.name : quantityUnit.namePlural) ?? "")")
//                    } else {
//                        Text(stockElement.product?.minStockAmount.formattedAmount )
//                    }
//                })
//                .customizationID("minStockAmount")
//            }
//            
//            Group {
//                TableColumn("Product description", content: { (stockElement: StockTableElement) in
//                    Text(stockElement.productDescription)
//                        .font(.caption)
//                })
//                .customizationID("productDescription")
//                
//                TableColumn("Parent product", content: { (stockElement: StockTableElement) in
//                    Text(stockElement.parentProduct?.name ?? "")
//                })
//                .customizationID("parentProduct")
//                
//                TableColumn("Default location", content: { (stockElement: StockTableElement) in
//                    Text(stockElement.defaultLocation?.name ?? "")
//                        .backgroundStyle(.red)
//                })
//                .customizationID("defaultLocation")
//                
//                TableColumn("Average price", content: { (stockElement: StockTableElement) in
//                    Text(stockElement.averagePrice?.formattedAmount ?? "")
//                        .backgroundStyle(.red)
//                })
//                .customizationID("averagePrice")
//            }
//        })
//              , rows: {
//            ForEach(sortedStock, id:\.id) { stockElement in
//                TableRow(stockElement)
//                    .background(Color(.GrocyColors.grocyRed))
//            }
//        })
        Text("")
        .task {
            await grocyVM.requestData(objects: [.product_groups, .shopping_list, .quantity_units, .products, .locations], additionalObjects: [.stock, .system_config])
        }
        .animation(.default, value: sortedStock.count)
    }
}

