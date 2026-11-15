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
| `Model/Recipes/Import/RecipeImportDraft.swift` | `RecipeImportDraft` and `ImportedIngredient` (the editable state), plus `RecipeImportMapper`, which matches products and quantity units and applies Grocy's unit rules. |
| `Model/Recipes/Import/RecipePreparationFormat.swift` | The HTML format for the recipe's preparation (see below), in both directions: steps → HTML and HTML → steps. |
| `Model/Recipes/RecipeAmountConversion.swift` | Converts between an ingredient's display unit and the product's stock unit. The recipe ingredient form uses it too. |
| `Views/Recipes/Import/RecipeImportView.swift` | URL field, loading, review form, and saving. |
| `Views/Recipes/Import/RecipeImportIngredientFormView.swift` / `…RowView.swift` | Editing one imported ingredient: include it or not, product (or create one with `MDProductFormView`), amount, unit, note, group, variable amount. |
| `Grocy MobileTests/Model/RecipeImportTests.swift` | Swift Testing suites for the line parser, the preparation format, the mapping and the amount conversion. |

## Mapping to Grocy

**Products.** `matchProduct(for:)` only considers active products. It tries, in order:
1. an exact match of the normalized name, ignoring case, diacritics, `ß`/`ss` and a simple English/German singular form;
2. the longest product whose words all appear in the ingredient ("Butter" in "kalte Butter");
3. a compound-word suffix of at least 4 characters ("Sahne" in "Schlagsahne").

Grocy requires a product for every ingredient. Ingredients without one are shown, but not saved, and the form footer counts them.

**Quantity units.** `matchQuantityUnit(for:knownUnit:)` matches a unit's name or plural name directly. Failing that, it matches any spelling of the same `KnownIngredientUnit`, so "EL" finds "Esslöffel" or "Tablespoon".

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
