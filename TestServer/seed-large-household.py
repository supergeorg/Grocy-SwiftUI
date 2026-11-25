#!/usr/bin/env python3
"""Fills a Grocy test server with a large household, for profiling Grocy Mobile.

Usage:
    TestServer/grocy-test-server.sh start
    TestServer/seed-large-household.py [--products 1000] [--url http://localhost:9290] [--api-key ...]

Creates locations, product groups, quantity units, stores, products with stock (some due soon, some
overdue, some below their minimum), shopping lists with items, recipes with ingredients, chores,
tasks and batteries. The amounts of everything but products scale with --products.

Run it on a fresh test server (every `grocy-test-server.sh start` makes one): it doesn't check for
existing data. Only uses the Python standard library.
"""

import argparse
import concurrent.futures
import datetime
import json
import os
import random
import sys
import time
import urllib.error
import urllib.request

WORDS = (
    "apple banana carrot tomato potato onion garlic pepper lemon lime orange pear peach plum cherry grape melon "
    "rice pasta flour sugar salt oats beans lentils peas corn milk butter cheese yogurt cream egg bread toast "
    "coffee tea juice water soda beer wine vinegar oil honey jam mustard ketchup mayo pesto curry paprika basil "
    "oregano thyme rosemary cinnamon vanilla cocoa chocolate cookie cracker chips nuts almond walnut peanut "
    "tuna salmon chicken beef pork tofu sausage ham bacon soup sauce noodles cereal muesli spinach lettuce "
    "cucumber zucchini pumpkin mushroom broccoli cauliflower cabbage celery leek ginger soap shampoo detergent"
).split()
ADJECTIVES = "organic fresh frozen smoked dried whole light spicy sweet sour red green large small classic".split()


class Grocy:
    def __init__(self, url, api_key):
        self.base = url.rstrip("/") + "/api"
        self.headers = {"GROCY-API-KEY": api_key, "Content-Type": "application/json", "Accept": "application/json"}

    def call(self, method, path, body=None):
        data = None if body is None else json.dumps(body).encode()
        for attempt in range(5):
            request = urllib.request.Request(self.base + path, data=data, method=method, headers=self.headers)
            try:
                with urllib.request.urlopen(request, timeout=60) as response:
                    text = response.read().decode()
                    return json.loads(text) if text else None
            except urllib.error.HTTPError as error:
                message = error.read().decode(errors="replace")
                if error.code >= 500 and attempt < 4:
                    time.sleep(0.5 * (attempt + 1))
                    continue
                sys.exit(f"error: {method} {path} failed with {error.code}: {message}")
            except urllib.error.URLError as error:
                if attempt < 4:
                    time.sleep(0.5 * (attempt + 1))
                    continue
                sys.exit(f"error: {method} {path} failed: {error.reason}")

    def create(self, entity, fields):
        return int(self.call("POST", f"/objects/{entity}", fields)["created_object_id"])


def parallel(function, items, workers):
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        return list(pool.map(function, items))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--url", default=os.environ.get("GROCY_TEST_SERVER_URL", "http://localhost:9290"))
    parser.add_argument("--api-key", default=os.environ.get("GROCY_TEST_API_KEY", "grocy-mobile-integration-tests"))
    parser.add_argument("--products", type=int, default=1000, help="number of products (default: 1000)")
    parser.add_argument("--workers", type=int, default=4, help="parallel requests (default: 4, like the test server)")
    parser.add_argument("--seed", type=int, default=4, help="random seed (default: 4)")
    args = parser.parse_args()

    random.seed(args.seed)
    grocy = Grocy(args.url, args.api_key)
    info = grocy.call("GET", "/system/info")
    print(f"Seeding Grocy {info['grocy_version']['Version']} at {args.url}")
    started = time.monotonic()
    scale = max(args.products / 1000, 0.01)
    today = datetime.date.today()

    def count(n):
        return max(int(n * scale), 1)

    def step(name, function, items):
        t = time.monotonic()
        result = parallel(function, items, args.workers)
        print(f"  {len(result):5d} {name} ({time.monotonic() - t:.1f} s)")
        return result

    locations = step("locations", lambda i: grocy.create("locations", {"name": f"Location {i + 1}"}), range(count(20)))
    groups = step("product groups", lambda i: grocy.create("product_groups", {"name": f"Group {i + 1}"}), range(count(30)))
    units = step(
        "quantity units",
        lambda i: grocy.create("quantity_units", {"name": f"Unit {i + 1}", "name_plural": f"Units {i + 1}"}),
        range(count(25)),
    )
    stores = step("stores", lambda i: grocy.create("shopping_locations", {"name": f"Store {i + 1}"}), range(count(10)))

    def product(i):
        unit = random.choice(units)
        name = f"{random.choice(ADJECTIVES).title()} {random.choice(WORDS)} {i + 1}"
        return grocy.create(
            "products",
            {
                "name": name,
                "location_id": random.choice(locations),
                "product_group_id": random.choice(groups),
                "shopping_location_id": random.choice(stores),
                "qu_id_purchase": unit,
                "qu_id_stock": unit,
                "min_stock_amount": random.choice([0, 0, 0, 1, 2, 5]),
                "default_best_before_days": random.choice([0, 3, 7, 30, 365]),
            },
        )

    products = step("products", product, range(args.products))

    # About two thirds are in stock, with one to three entries each. Some are due soon or overdue.
    stocked = random.sample(products, int(len(products) * 2 / 3))
    entries = [p for p in stocked for _ in range(random.randint(1, 3))]

    def purchase(product_id):
        days = random.choice([-10, -2, 1, 3, 5, 14, 60, 200, 400])
        grocy.call(
            "POST",
            f"/stock/products/{product_id}/add",
            {
                "amount": random.randint(1, 6),
                "best_before_date": (today + datetime.timedelta(days=days)).isoformat(),
                "price": round(random.uniform(0.3, 15), 2),
                "transaction_type": "purchase",
            },
        )

    step("stock entries", purchase, entries)

    lists = [1] + step("more shopping lists", lambda i: grocy.create("shopping_lists", {"name": f"List {i + 2}"}), range(2))

    def shopping_item(i):
        if i % 5 == 0:
            return grocy.create("shopping_list", {"shopping_list_id": random.choice(lists), "note": f"Free text item {i + 1}", "amount": 1})
        return grocy.create(
            "shopping_list",
            {"shopping_list_id": random.choice(lists), "product_id": random.choice(products), "amount": random.randint(1, 4)},
        )

    step("shopping list items", shopping_item, range(count(150)))

    recipes = step(
        "recipes",
        lambda i: grocy.create("recipes", {"name": f"Recipe {i + 1}", "base_servings": 4, "desired_servings": 4, "description": "Mix and cook."}),
        range(count(100)),
    )
    ingredients = [(r, p) for r in recipes for p in random.sample(products, min(len(products), random.randint(3, 12)))]
    step(
        "recipe ingredients",
        lambda pair: grocy.create("recipes_pos", {"recipe_id": pair[0], "product_id": pair[1], "amount": random.randint(1, 3)}),
        ingredients,
    )

    def chore(i):
        return grocy.create(
            "chores",
            {
                "name": f"Chore {i + 1}",
                "period_type": random.choice(["manually", "dynamic-regular", "daily"]),
                "period_days": random.choice([1, 3, 7, 14]),
                "period_interval": 1,
                "start_date": (today - datetime.timedelta(days=random.randint(0, 30))).isoformat() + " 08:00:00",
            },
        )

    step("chores", chore, range(count(60)))

    categories = step("task categories", lambda i: grocy.create("task_categories", {"name": f"Category {i + 1}"}), range(count(8)))
    step(
        "tasks",
        lambda i: grocy.create(
            "tasks",
            {
                "name": f"Task {i + 1}",
                "category_id": random.choice(categories),
                "due_date": (today + datetime.timedelta(days=random.randint(-14, 60))).isoformat(),
            },
        ),
        range(count(150)),
    )
    step(
        "batteries",
        lambda i: grocy.create("batteries", {"name": f"Battery {i + 1}", "charge_interval_days": random.choice([0, 30, 90, 180])}),
        range(count(30)),
    )

    print(f"Done in {time.monotonic() - started:.0f} s.")


if __name__ == "__main__":
    main()
