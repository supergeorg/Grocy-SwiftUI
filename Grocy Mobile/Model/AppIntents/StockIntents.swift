//
//  StockIntents.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 21.11.26.
//

import AppIntents
import Foundation

// The type names, parameter names and the meaning of the returned values are part of the people's saved shortcuts.
// Don't rename them; add new parameters as optionals.

// MARK: - Get Stock Amount

/// Answers "How much milk do I have?". Returns the amount in stock, in the product's stock quantity unit.
struct GetProductStockIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Stock Amount"
    static let description = IntentDescription(
        "Tells how much of a product is in stock, and how much of it is opened.",
        categoryName: "Stock",
        searchKeywords: ["stock", "amount", "left", "inventory", "how much"]
    )
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Product")
    var product: ProductEntity

    @Dependency private var grocyVM: GrocyViewModel

    static var parameterSummary: some ParameterSummary {
        Summary("Get stock amount of \(\.$product)")
    }

    init() {}

    init(product: ProductEntity) {
        self.product = product
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        try await grocyVM.ensureLoggedInForIntent()
        let state = try await grocyVM.productStockStateForIntent(productID: product.id)
        let name = state.productName.isEmpty ? product.name : state.productName
        let dialog: IntentDialog
        if state.amount <= 0 {
            dialog = IntentDialog("\(name) isn't in stock.")
        } else if state.amountOpened > 0 {
            dialog = IntentDialog(
                "You have \(state.amountDescription(state.amount)) of \(name) in stock, \(state.amountOpened.formattedAmount) of them opened."
            )
        } else {
            dialog = IntentDialog("You have \(state.amountDescription(state.amount)) of \(name) in stock.")
        }
        return .result(value: state.amount, dialog: dialog)
    }
}

// MARK: - Open Product

/// Marks a product as opened, for example when a new milk carton is opened. Returns the amount left in stock.
struct OpenProductIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Product"
    static let description = IntentDescription(
        "Marks an amount of a product in stock as opened. Without an amount, the product's quick open amount is used.",
        categoryName: "Stock",
        searchKeywords: ["open", "opened", "start"]
    )
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Product")
    var product: ProductEntity

    @Parameter(title: "Amount", description: "The amount to open, in the product's stock quantity unit. Leave it empty for the quick open amount.")
    var amount: Double?

    @Dependency private var grocyVM: GrocyViewModel

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$amount) of \(\.$product)")
    }

    init() {}

    init(product: ProductEntity, amount: Double? = nil) {
        self.product = product
        self.amount = amount
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        try await grocyVM.ensureLoggedInForIntent()
        guard grocyVM.isOpenedTrackingEnabled else {
            throw GrocyIntentError.openedTrackingDisabled
        }
        let before = try await grocyVM.productStockStateForIntent(productID: product.id)
        let openAmount = amount ?? before.quickOpenAmount
        guard openAmount > 0 else {
            throw GrocyIntentError.invalidAmount
        }
        let name = before.productName.isEmpty ? product.name : before.productName

        try await grocyVM.postStockActionForIntent(
            productID: product.id,
            stockModePost: .open,
            content: ProductOpen(amount: openAmount)
        )
        GrocyLogger.info("Opening \(openAmount) of product \(product.id) from an intent was successful.")

        let after = try await grocyVM.productStockStateForIntent(productID: product.id)
        return .result(
            value: after.amount,
            dialog:
                "Opened \(before.amountDescription(openAmount)) of \(name). \(after.amountOpened.formattedAmount) of \(after.amountDescription(after.amount)) are opened now."
        )
    }
}

// MARK: - Consume Product

/// Consumes a product from stock. Returns the amount left in stock.
struct ConsumeProductIntent: AppIntent {
    static let title: LocalizedStringResource = "Consume Product"
    static let description = IntentDescription(
        "Removes an amount of a product from stock. Without an amount, the product's quick consume amount is used.",
        categoryName: "Stock",
        searchKeywords: ["consume", "use", "eat", "drink", "used up", "remove"]
    )
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Product")
    var product: ProductEntity

    @Parameter(
        title: "Amount",
        description: "The amount to consume, in the product's stock quantity unit. Leave it empty for the quick consume amount."
    )
    var amount: Double?

    @Parameter(title: "Spoiled", description: "Whether the product was thrown away instead of used.", default: false)
    var spoiled: Bool

    @Dependency private var grocyVM: GrocyViewModel

    static var parameterSummary: some ParameterSummary {
        Summary("Consume \(\.$amount) of \(\.$product)") {
            \.$spoiled
        }
    }

    init() {}

    init(product: ProductEntity, amount: Double? = nil, spoiled: Bool = false) {
        self.product = product
        self.amount = amount
        self.spoiled = spoiled
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        try await grocyVM.ensureLoggedInForIntent()
        let before = try await grocyVM.productStockStateForIntent(productID: product.id)
        let consumeAmount = amount ?? before.quickConsumeAmount
        guard consumeAmount > 0 else {
            throw GrocyIntentError.invalidAmount
        }
        let name = before.productName.isEmpty ? product.name : before.productName

        try await grocyVM.postStockActionForIntent(
            productID: product.id,
            stockModePost: .consume,
            content: ProductConsume(amount: consumeAmount, transactionType: .consume, spoiled: spoiled)
        )
        GrocyLogger.info("Consuming \(consumeAmount) of product \(product.id) from an intent was successful.")

        let after = try await grocyVM.productStockStateForIntent(productID: product.id)
        return .result(
            value: after.amount,
            dialog: "Consumed \(before.amountDescription(consumeAmount)) of \(name). \(after.amountDescription(after.amount)) left."
        )
    }
}

// MARK: - Add to Shopping List

/// Adds a product to a shopping list, or raises the amount of the item already on it.
struct AddProductToShoppingListIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Product to Shopping List"
    static let description = IntentDescription(
        "Puts a product on a Grocy shopping list. If it's already on the list, its amount is raised.",
        categoryName: "Shopping list",
        searchKeywords: ["shopping", "buy", "groceries", "list"]
    )
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Product")
    var product: ProductEntity

    @Parameter(title: "Amount", description: "The amount to add, in the product's purchase quantity unit.", default: 1)
    var amount: Double

    @Parameter(title: "Shopping list", description: "The list to add the product to. Leave it empty for the default shopping list.")
    var shoppingList: ShoppingListEntity?

    @Dependency private var grocyVM: GrocyViewModel

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$amount) of \(\.$product) to \(\.$shoppingList)")
    }

    init() {}

    init(product: ProductEntity, amount: Double = 1, shoppingList: ShoppingListEntity? = nil) {
        self.product = product
        self.amount = amount
        self.shoppingList = shoppingList
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await grocyVM.ensureLoggedInForIntent()
        guard amount > 0 else {
            throw GrocyIntentError.invalidAmount
        }
        let listID = shoppingList?.id ?? ShoppingListEntity.defaultListID
        do {
            try await grocyVM.addProductToShoppingList(
                content: ShoppingListAddProductModel(productID: product.id, listID: listID, productAmount: amount, note: nil)
            )
        } catch let error as APIError {
            GrocyLogger.error("Adding product \(product.id) to shopping list \(listID) from an intent failed. \(error)")
            throw GrocyIntentError.server(message: error.displayMessage)
        }
        GrocyLogger.info("Adding product \(product.id) to shopping list \(listID) from an intent was successful.")
        await grocyVM.requestData(objects: [.shopping_list])
        return .result(dialog: "Added \(amount.formattedAmount) \(product.name) to the shopping list.")
    }
}
