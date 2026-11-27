//
//  RecipeImportExploration.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 27.11.26.
//

import CryptoKit
import Foundation
import Testing

@testable import Grocy_Mobile

/// An opt-in check of the import with real recipes: imports the ones listed in RECIPE_IMPORT_URLS (a file with one URL per line)
/// with the app's import code into the test server and writes a report to RECIPE_IMPORT_REPORT. With RECIPE_IMPORT_HTML_DIR,
/// the pages are read from files saved before, named by the first 16 hex digits of the URL's SHA-1.
@MainActor
@Suite(
    "Recipe import exploration",
    .tags(.integration),
    .serialized,
    .enabled(if: GrocyTestServer.isConfigured && ProcessInfo.processInfo.environment["RECIPE_IMPORT_URLS"] != nil)
)
struct RecipeImportExploration {
    @Test("Import many recipes")
    func importRecipes() async throws {
        let env = ProcessInfo.processInfo.environment
        let urls = try String(contentsOfFile: try #require(env["RECIPE_IMPORT_URLS"]), encoding: .utf8)
            .split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.compactMap(URL.init(string:))
        let reportPath = env["RECIPE_IMPORT_REPORT"] ?? NSTemporaryDirectory() + "recipe-import-report.txt"

        let (grocyVM, container, profileContainer) = try await GrocyTestServer.makeLoggedInViewModel()
        _ = (container, profileContainer)
        await grocyVM.requestData(objects: [.products, .quantity_units, .quantity_unit_conversions, .recipes, .recipes_pos])
        let products: MDProducts = try await grocyVM.grocyApi.getObject(object: .products)
        let units: MDQuantityUnits = try await grocyVM.grocyApi.getObject(object: .quantity_units)
        let conversions: MDQuantityUnitConversions = try await grocyVM.grocyApi.getObject(object: .quantity_unit_conversions)
        let mapper = RecipeImportMapper(products: products, quantityUnits: units, conversions: conversions)
        let unitName = { (id: Int?) -> String in units.first { $0.id == id }?.name ?? "–" }

        var report: [String] = []
        var totals = (
            recipes: 0, failed: 0, lines: 0, exact: 0, suggested: 0, noProduct: 0, unitExact: 0, unitSuggested: 0, unitMissing: 0, onlyCheck: 0, saved: 0
        )
        var unmatchedNames: [String: Int] = [:]
        var unmatchedUnits: [String: Int] = [:]

        for url in urls {
            report.append("\n=== \(url.absoluteString)")
            let started = Date()
            do {
                let recipes: [JSONParsedRecipe]
                if let directory = env["RECIPE_IMPORT_HTML_DIR"] {
                    // Pages saved before (the simulator's network can be unreliable), named by the URL's SHA-1
                    let hash = Insecure.SHA1.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined().prefix(16)
                    let html = try String(contentsOfFile: "\(directory)/\(hash).html", encoding: .utf8)
                    recipes = try RecipeParser.parse(html: html)
                } else {
                    recipes = try await RecipeParser.fetch(from: url)
                }
                guard let parsed = recipes.first else { throw RecipeParserError.noRecipeFound }
                var draft = mapper.draft(from: parsed)
                if draft.sourceURL == nil { draft.sourceURL = url }
                totals.recipes += 1
                report.append(
                    "name: \(draft.name) | servings: \(draft.baseServings) (yield \(parsed.recipeYield ?? "–")) | language: \(draft.language ?? "–") | steps: \(draft.steps.count) | image: \(draft.imageURL != nil) | \(String(format: "%.1f", Date().timeIntervalSince(started))) s"
                )
                for ingredient in draft.ingredients {
                    let line = ingredient.line
                    let product = products.first { $0.id == ingredient.productID }?.name ?? "–"
                    totals.lines += 1
                    switch ingredient.productMatch {
                    case .exact: totals.exact += 1
                    case .suggested: totals.suggested += 1
                    default:
                        totals.noProduct += 1
                        unmatchedNames[line.name.lowercased(), default: 0] += 1
                    }
                    if ingredient.hasUnmatchedUnit {
                        totals.unitMissing += 1
                        unmatchedUnits[line.unit ?? "", default: 0] += 1
                    } else if ingredient.unitMatch == .exact {
                        totals.unitExact += 1
                    } else if ingredient.unitMatch == .suggested {
                        totals.unitSuggested += 1
                    }
                    if ingredient.onlyCheckSingleUnitInStock { totals.onlyCheck += 1 }
                    report.append(
                        "  [\(line.originalText)] → amount \(line.amount.map { String($0) } ?? "–") unit \(line.unit ?? "–") name «\(line.name)» note «\(line.note)» | product \(product) (\(ingredient.productMatch)) | qu \(unitName(ingredient.quID)) (\(ingredient.unitMatch)) amount \(ingredient.amount) var «\(ingredient.variableAmount)» onlyCheck \(ingredient.onlyCheckSingleUnitInStock)"
                    )
                }

                // Save the recipe like RecipeImportView.saveRecipe (without the picture)
                let recipe = Recipe(
                    id: try grocyVM.findNextID(.recipes),
                    name: draft.name,
                    recipeDescription: draft.preparationHTML,
                    pictureFileName: nil,
                    baseServings: draft.baseServings,
                    desiredServings: draft.baseServings
                )
                let recipeID = try await grocyVM.postMDObject(object: .recipes, content: recipe).createdObjectID
                var usedIDs = Set(grocyVM.recipesPos.map(\.id))
                for ingredient in draft.ingredientsToSave {
                    var id = 1
                    while usedIDs.contains(id) { id += 1 }
                    guard let pos = mapper.recipePos(for: ingredient, id: id, recipeID: recipeID) else { continue }
                    usedIDs.insert(id)
                    do {
                        _ = try await grocyVM.postMDObject(object: .recipes_pos, content: pos)
                        totals.saved += 1
                    } catch {
                        report.append("  SAVE FAILED [\(ingredient.line.originalText)]: \(error)")
                    }
                }
                report.append(
                    "saved recipe \(recipeID): \(draft.ingredientsToSave.count) ingredients, \(draft.ingredientsWithoutProduct.count) without product, \(draft.ingredientsToCheck.count) to check"
                )
                grocyVM.timeStampsObjects[.recipes] = nil
                grocyVM.timeStampsObjects[.recipes_pos] = nil
                await grocyVM.requestData(objects: [.recipes, .recipes_pos])
            } catch {
                totals.failed += 1
                report.append("FAILED: \(error)")
            }
        }

        report.insert(
            """
            recipes: \(totals.recipes) imported, \(totals.failed) failed
            ingredient lines: \(totals.lines); product exact \(totals.exact), suggested \(totals.suggested), none \(totals.noProduct)
            units: exact \(totals.unitExact), suggested \(totals.unitSuggested), missing \(totals.unitMissing); only check any amount: \(totals.onlyCheck)
            ingredients saved: \(totals.saved)
            unmatched names: \(unmatchedNames.sorted { $0.value > $1.value }.map { "\($0.key) (\($0.value))" }.joined(separator: ", "))
            unmatched units: \(unmatchedUnits.sorted { $0.value > $1.value }.map { "\($0.key) (\($0.value))" }.joined(separator: ", "))
            """,
            at: 0
        )
        try report.joined(separator: "\n").write(toFile: reportPath, atomically: true, encoding: .utf8)
    }
}
