//
//  ProductPropertySuggester.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import Foundation

/// The location, product group and quantity unit Apple Intelligence suggests for a new product.
struct ProductPropertySuggestions: Equatable {
    var locationID: Int?
    var productGroupID: Int?
    var quantityUnitID: Int?
}

/// Asks Apple Intelligence for the location, product group and quantity unit of a new product, one after another,
/// so the progress can be shown. Each question includes how the household's products with similar names are set up,
/// and the model can only answer with existing names (or decline).
///
/// It can start before the product form opens, e.g. in the recipe import's ingredient form,
/// and `MDProductFormView` applies the suggestions as they arrive.
@Observable
final class ProductPropertySuggester {
    enum Step: Hashable {
        case location, productGroup, quantityUnit
    }

    /// One option the model can choose.
    struct Option {
        let id: Int
        let name: String
    }

    /// The name the suggestions are for.
    private(set) var productName = ""
    private(set) var steps: [Step] = []
    private(set) var completedSteps = 0
    private(set) var currentStep: Step?
    private(set) var suggestions = ProductPropertySuggestions()
    private(set) var isRunning = false

    @ObservationIgnored private var task: Task<Void, Never>?

    /// Answers of the model below this confidence are left out. The person checks the suggestions before saving.
    static let minimumConfidence = 0.6
    /// The answer for "nothing fits". It's in English like the model's instructions; it's never shown.
    private static let noneOption = "None of these"
    /// How many of the household's products are shown to the model as examples.
    static let exampleCount = 8

    /// `true` when Apple Intelligence can be used and is turned on in the settings.
    static var isEnabled: Bool {
        (UserDefaults.standard.object(forKey: "useAppleIntelligence") as? Bool ?? true) && AppleIntelligenceStatus.isAppleIntelligenceAvailable
    }

    /// `true` once every step was answered for `name`.
    func isFinished(for name: String) -> Bool {
        !isRunning && !steps.isEmpty && completedSteps == steps.count && productName == name
    }

    // MARK: - Starting and stopping

    /// Starts asking for the properties of a product named `productName`. A running request is stopped first.
    /// - Parameters:
    ///   - usage: How the product is used, e.g. the line of a recipe ("1 Paprikaschote, rote"), which helps choosing the unit.
    ///   - skipping: Properties that are already set.
    func start(
        productName: String,
        locations: MDLocations,
        productGroups: MDProductGroups,
        quantityUnits: MDQuantityUnits,
        products: MDProducts,
        usage: String? = nil,
        skipping: Set<Step> = []
    ) {
        stop()
        let name = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        let locationOptions = locations.filter(\.active).map { Option(id: $0.id, name: $0.name) }
        let groupOptions = productGroups.filter(\.active).map { Option(id: $0.id, name: $0.name) }
        let unitOptions = quantityUnits.filter(\.active).map { Option(id: $0.id, name: $0.name) }

        self.productName = name
        suggestions = ProductPropertySuggestions()
        completedSteps = 0
        steps = [
            (Step.location, locationOptions), (Step.productGroup, groupOptions), (Step.quantityUnit, unitOptions),
        ]
        .filter { !skipping.contains($0.0) && !$0.1.isEmpty }
        .map(\.0)
        guard !name.isEmpty, !steps.isEmpty else { return }

        let examples = Self.similarProducts(to: name, in: products)
        let contexts: [Step: String] = [
            .location: Self.context(
                task: "Choose the location where this product is usually stored at home.",
                examplesTitle: "Products of this household and their location",
                examples: examples.compactMap { product in locationOptions.first { $0.id == product.locationID }.map { "\(product.name): \($0.name)" } },
                usage: nil
            ),
            .productGroup: Self.context(
                task: "Choose the product group (category) this product belongs to.",
                examplesTitle: "Products of this household and their product group",
                examples: examples.compactMap { product in groupOptions.first { $0.id == product.productGroupID }.map { "\(product.name): \($0.name)" } },
                usage: nil
            ),
            .quantityUnit: Self.context(
                task:
                    "Choose the quantity unit this product is usually counted or measured in at home. Count things that are used whole (an onion, an egg) in pieces.",
                examplesTitle: "Products of this household and their unit",
                examples: examples.compactMap { product in unitOptions.first { $0.id == product.quIDStock }.map { "\(product.name): \($0.name)" } },
                usage: usage
            ),
        ]
        let options: [Step: [Option]] = [.location: locationOptions, .productGroup: groupOptions, .quantityUnit: unitOptions]

        isRunning = true
        task = Task {
            let matcher = AICategoryMatcher()
            for step in steps {
                guard !Task.isCancelled else { return }
                currentStep = step
                do {
                    let id = try await suggest(
                        word: name,
                        options: options[step] ?? [],
                        context: contexts[step] ?? "",
                        // A product group is a category, so the model is asked again whether the product really belongs in it
                        confirmsMembership: step == .productGroup,
                        matcher: matcher
                    )
                    try Task.checkCancellation()
                    switch step {
                    case .location: suggestions.locationID = id
                    case .productGroup: suggestions.productGroupID = id
                    case .quantityUnit: suggestions.quantityUnitID = id
                    }
                } catch is CancellationError {
                    return
                } catch {
                    GrocyLogger.warning("Suggesting the \(step) of \(name) with Apple Intelligence failed. \(error)")
                }
                completedSteps += 1
            }
            currentStep = nil
            isRunning = false
            GrocyLogger.info(
                "Apple Intelligence suggested for \(name): location \(String(describing: suggestions.locationID)), product group \(String(describing: suggestions.productGroupID)), quantity unit \(String(describing: suggestions.quantityUnitID))."
            )
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isRunning = false
        currentStep = nil
    }

    // MARK: - Asking the model

    private func suggest(word: String, options: [Option], context: String, confirmsMembership: Bool, matcher: AICategoryMatcher) async throws -> Int? {
        // With one option there's nothing to choose
        if options.count == 1 {
            return options[0].id
        }
        let result = try await matcher.matchByNames(word: word, categoryNames: options.map(\.name) + [Self.noneOption], context: context)
        GrocyLogger.info("Apple Intelligence chose \(result.categoryName) for \(word) with confidence \(result.confidence).")
        guard result.confidence >= Self.minimumConfidence,
            let option = options.first(where: { $0.name.localizedCaseInsensitiveCompare(result.categoryName) == .orderedSame })
        else { return nil }
        if confirmsMembership {
            let isConfirmed = try await matcher.confirmMembership(word: word, categoryName: option.name)
            GrocyLogger.info("Apple Intelligence \(isConfirmed ? "confirmed" : "rejected") \(option.name) for \(word).")
            guard isConfirmed else { return nil }
        }
        return option.id
    }

    /// The household's products with the most similar names, as examples of how products are set up there.
    static func similarProducts(to name: String, in products: MDProducts, limit: Int = exampleCount) -> MDProducts {
        let nameTrigrams = RecipeImportMapper.trigrams(of: name)
        let normalizedName = RecipeImportMapper.normalizedName(name)
        return
            products
            .filter { $0.active && RecipeImportMapper.normalizedName($0.name) != normalizedName }
            .map { (product: $0, shared: RecipeImportMapper.trigrams(of: $0.name).intersection(nameTrigrams).count) }
            .filter { $0.shared > 0 }
            .sorted { $0.shared > $1.shared }
            .prefix(limit)
            .map(\.product)
    }

    static func context(task: String, examplesTitle: String, examples: [String], usage: String?) -> String {
        var lines = [task]
        if !examples.isEmpty {
            lines.append("\(examplesTitle):")
            lines += examples.map { "- \($0)" }
        }
        if let usage, !usage.isEmpty {
            lines.append("In a recipe, it's used as: \(usage)")
        }
        lines.append("If none fits, choose \"\(noneOption)\".")
        return lines.joined(separator: "\n")
    }
}
