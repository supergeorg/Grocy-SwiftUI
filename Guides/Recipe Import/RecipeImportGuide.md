# Recipe Import

Grocy Mobile can import a recipe from a website as a Grocy recipe. The ingredients get linked to products, and the preparation is saved as numbered steps. The feature is still a work in progress.

The person opens it from the recipes list ("Import recipe from website"). They enter a URL, review and correct the result, and save it.

## Overview

```
Website URL
   │  RecipeParser.fetch(from:)          URLSession, regex for <script type="application/ld+json">
   ▼
JSONParsedRecipe                          schema.org/Recipe, every field but `name` optional
   │  RecipeImportMapper.draft(from:)     IngredientLineParser + product / unit matching
   ▼
RecipeImportDraft                         edited in RecipeImportView / RecipeImportIngredientFormView
   │  RecipeImportView.saveRecipe()
   ▼
Grocy: picture upload → recipes → recipes_pos (one per ingredient)
```

There's no HTML scraping and no third-party parser. Only websites that embed **schema.org/Recipe JSON-LD** are supported. Most large recipe sites do, for example Chefkoch, BBC Good Food and AllRecipes. Sites that inject JSON-LD with JavaScript aren't supported, because the page is not rendered.

## Files

| File | Role |
|------|------|
| `Views/Recipes/Import/RecipeParse.swift` | `RecipeParser`: extracts the JSON-LD blocks, finds `Recipe` nodes (also inside `@graph`), and builds `JSONParsedRecipe` with its supporting types (`Ingredient`, `InstructionStep`, `IsoDuration`, `NutritionInfo`, `DietType`, …). Malformed fields are skipped with a warning instead of failing. `diagnose(html:)` explains why a page yields no recipe. |
| `Model/Recipes/Import/IngredientLineParser.swift` | Splits a line like `"2-3 EL Olivenöl, kaltgepresst"` into amount, amount text (for ranges), unit, name and note (`ParsedIngredientLine`). `KnownIngredientUnit` lists common units with their English and German spellings and UN/CEFACT codes. |
| `Model/Recipes/Import/RecipeImportDraft.swift` | `RecipeImportDraft` and `ImportedIngredient` (the editable state), plus `RecipeImportMapper`, which builds the draft and applies Grocy's unit rules. |
| `Model/Recipes/Import/IngredientMatcher.swift` | The matching of products (`productCandidates(for:note:)`, scored) and quantity units (`quantityUnitMatch(for:knownUnit:)`), the match quality (`IngredientMatchQuality`), and the names suggested for new quantity units. |
| `Model/Recipes/Import/RecipePreparationFormat.swift` | The HTML format for the recipe's preparation (see below), in both directions: steps → HTML and HTML → steps. |
| `Model/Recipes/RecipeAmountConversion.swift` | Converts between an ingredient's display unit and the product's stock unit. The recipe ingredient form uses it too. |
| `Views/Recipes/Import/RecipeImportView.swift` | URL field, loading, review form, and saving. |
| `Views/Recipes/Import/RecipeImportIngredientFormView.swift` / `…RowView.swift` / `RecipeImportUnitConversionFormView.swift` | Editing one imported ingredient: include it or not, product (pick one of the similar products, or create one with `MDProductFormView`), amount, unit (create one with `MDQuantityUnitFormView`, or connect it to the product with `RecipeImportUnitConversionFormView`), note, group, variable amount. The row names suggested matches and missing units in text. |
| `Grocy MobileTests/Model/RecipeImportTests.swift` | Swift Testing suites for the line parser, the preparation format, the mapping and the amount conversion. |

## Mapping to Grocy

**Products.** `productCandidates(for:note:)` scores every active product against the ingredient's name and note. Words are compared normalized (case, diacritics, `ß`/`ss`) and stemmed (`stem(_:)` removes English and German plural and adjective endings, so "getrockneter" and "getrocknet" are the same).

| Score | Rule | Example |
|-------|------|---------|
| 110+ | The name, made more specific by words of the note | "Thymian (getrockneter)" → "Thymian, getrocknet" |
| 100 | The same name | "Champignons" → "Champignon", "Eier" → "Ei" |
| 70–90 | All words of the product appear in the ingredient | "süße Sahne" → "Sahne" |
| 55 | The product is the end of a compound word | "Schweineschnitzel" → "Schnitzel" |
| 40–55 | The product is more specific than the ingredient | "Thymian" → "Thymian frisch", "Mehl" → "Weizenmehl" |
| 40 | A typo (1 letter from 5 letters on, 2 from 8 on) | "Jogurt" → "Joghurt" |

The best candidate is selected. From 100 on it's an exact match; below, it's *suggested*: the row says "Suggested", and the form shows the reason and the other candidates (*Similar products*). Selecting a product, also the suggested one, makes it the person's choice. Grocy requires a product for every ingredient. Ingredients without one are shown, but not saved, and the form footer counts them.

**Quantity units.** `quantityUnitMatch(for:knownUnit:)` matches, as exact: a unit's name or plural name; any spelling of the same `KnownIngredientUnit` ("g" finds "Gramm" or "Grams", "EL" finds "Esslöffel" or "Tablespoon"); a word of the unit's name ("g" finds "Gramm (g)"). As suggested: the same stem ("Dosen" finds "Dose") or, for unknown units, an abbreviation of the name.

When no unit matches (`hasUnmatchedUnit`), the row says so and the form offers *Create quantity unit*. Its name is the full name of a known unit in the recipe's language (`IngredientUnitLanguage.detect(in:)`, from units like "EL" or "tbsp"; the app language for "g" or "ml"), e.g. "TL" → "Teelöffel", or the unit as written. After a product or unit was created, `fillMissingMatches(in:)` fills in the other ingredients that were missing it, so one new "Bund" serves parsley and chives. Choices of the person stay as they are.

When the unit exists but can't be converted to the product's stock unit (`needsUnitConnection(_:product:)`, e.g. "Bund" for parsley stocked in pieces), only "any amount in stock" can be checked. The form then offers *Connect “Bund” to “Petersilie”*, which adds a product-specific conversion (`productID` set, from the unit to the stock unit) and applies the unit rules again (`unitChanged`), so the amount is checked against the stock. Creating a unit leads straight to this step, as a new unit has no conversions yet.

**Amounts.** Grocy stores an ingredient's amount in the product's *stock* unit. `qu_id` is only the unit the amount is shown in. So:
- Without a unit ("3 eggs"), the product's consume unit is used.
- With a convertible unit, the amount is converted to the stock unit when saving.
- Without a conversion, a missing amount, or an unknown unit ("1 pinch of salt"), *Only check if any amount is in stock* is turned on. The amount is then kept as entered, and the original text goes into *Variable amount*.
- Ranges ("2-3") use the upper bound as the amount and keep the text as *Variable amount*.

**Servings.** These are read from the first number in `recipeYield` ("4 Portionen", "Serves 2-3"). The fallback is 1.

## Preparation format

The preparation is saved in the recipe's `description` as plain HTML. It renders in Grocy's web UI and stays editable in the rich text editor, and it can be split into steps again later, for example for a step-by-step cooking mode:

```html
<p>An optional introduction.</p>
<h3>Section name</h3>
<ol>
  <li><p><strong>Optional step title</strong></p><p>Step text.</p></li>
  <li><p>Next step.</p></li>
</ol>
<p><a href="https://example.com/recipe">Source</a></p>
```

Each `<li>` of an `<ol>` is one step, numbered across sections. An `<h3>` names the section that follows it. If a website puts all its instructions into one text, that text is split at line breaks. `steps(fromHTML:)` falls back to paragraphs for HTML without an `<ol>`, such as recipes written in the web UI.

## Saving

`saveRecipe()` works in this order:
1. If *Import picture* is on, it downloads the image, converts it to a JPEG of at most 2000 px (ImageIO, so WebP works too), and uploads it to the `recipepictures` file group. If this fails, the recipe is imported without a picture.
2. It posts the recipe (`findNextID(.recipes)`) and remembers `createdRecipeID`.
3. It posts one `recipes_pos` per ingredient to save. Each saved ingredient is marked as saved, so if some fail, the person can fix them and save again without creating a duplicate recipe or ingredient.
4. It resyncs `.recipes` and `.recipes_pos`.

## Extending

- **New unit spellings:** add them to `KnownIngredientUnit` (aliases or UN/CEFACT codes), then add a test case in `RecipeImportTests`.
- **Vague quantities** ("nach Belieben", "to taste") are listed in `IngredientLineParser.vagueQuantities`. They become the note.
- **More schema.org fields:** `JSONParsedRecipe` already parses times, nutrition, diets, keywords, rating and video. The draft doesn't use them yet.
- When a page has no recipe, call `RecipeParser.diagnose(html:)` to find the reason.
