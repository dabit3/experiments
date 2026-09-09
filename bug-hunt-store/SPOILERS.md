# SPOILERS — the 8 planted bugs

Don't read this until you have hunted on your own. Each bug below lists where it lives, how to
reproduce it deterministically, and the matcher id from `src/data/bugs.json` that the "Report a
bug" widget resolves it to.

| # | Bug | Where in the code | Matcher id |
|---|---|---|---|
| 1 | **"Sort by price" sorts as strings.** Price: Low to High yields `$1,299.00` → `$9.50`… because the comparison is done on the price *text* (`"1299" < "24.99" < "9.5"`). | `src/lib/catalog.ts` → `sortProducts` (`price-asc` / `price-desc` use a string `collator.compare`) | `sort-price-strings` |
| 2 | **Search is case-sensitive.** Typing `lamp` returns "No products match", `Lamp` finds the Desk Lamp. | `src/lib/catalog.ts` → `matchesSearch` (`includes` on the raw strings, no lower-casing) | `search-case-sensitive` |
| 3 | **Page 3 repeats an item from page 2 and drops the last product.** Page 2 ends with Camp Stove (#16); page 3 starts with Camp Stove again and Hiking Backpack (#24) never appears, although the footer still says "Showing 17–24 of 24". | `src/lib/catalog.ts` → `paginate` (`start` is shifted back by one for `page > 2`) | `pagination-off-by-one` |
| 4 | **Coupon `SAVE10` takes $10 off instead of 10%.** The banner promises 10%; on a $249 order the discount line shows `−$10.00`. | `src/lib/cart.ts` → `discountFor` (special-cases `SAVE10` to `min(amount, 10)`) | `coupon-flat-ten` |
| 5 | **One product shows six stars.** Sleep Ring (rating 5.0, page 2) renders six filled stars; everything else renders five. | `src/components/Stars.tsx` (`rating >= 5 ? 6 : 5`) | `six-stars` |
| 6 | **"Remove" removes the wrong cart line when two items share a price.** Add Desk Lamp ($49) then Canvas Tote ($49); click Remove on the Canvas Tote — the Desk Lamp disappears instead. | `src/lib/cart.ts` → `removeLine` (finds the line by `product.price`, not `product.id`) | `remove-wrong-line` |
| 7 | **Cart total ignores quantity for Audio products.** Bump Studio Headphones to ×3: the line still shows `$249.00` and the subtotal does not move. Non-Audio items multiply correctly. | `src/lib/cart.ts` → `lineTotal` (returns the unit price when `category === 'Audio'`) | `cart-qty-ignored` |
| 8 | **An invisible overlay blocks "Add to cart" on the 5th product until the window is resized.** Clicking Add to cart on Wireless Earbuds (5th card on page 1) does nothing; after any window resize a "Deal of the day" ribbon appears and the button works. | `src/components/ProductCard.tsx` (`.deal-overlay` is rendered over the footer while `!dealRevealed`) + `src/hooks/useWindowResized.ts` | `overlay-blocks-add-to-cart` |

## How the matcher works

`src/lib/matcher.ts` lower-cases `"<area> <description>"` and checks each bug's `keywords`
in `src/data/bugs.json`: every keyword *group* must contribute at least one hit. A report that
matches several bugs credits the first one that has not been found yet; a report that only
matches bugs already logged shows "Already logged". Found ids are persisted in
`localStorage["bug-hunt.found"]`; **Reset hunt** on the scoreboard clears them.

Example reports that resolve:

- Sorting & filtering — "Sort by price low to high puts $1,299 before $9.50, it sorts as text" → bug 1
- Search — "Searching lowercase 'lamp' returns nothing, only 'Lamp' works, search is case sensitive" → bug 2
- Pagination — "Page 3 repeats Camp Stove from page 2 and the Hiking Backpack is missing" → bug 3
- Coupons & checkout — "SAVE10 coupon only takes $10 off instead of 10 percent" → bug 4
- Product card — "Sleep Ring rating shows 6 stars" → bug 5
- Cart & totals — "Remove on Canvas Tote deleted the Desk Lamp instead, same price" → bug 6
- Cart & totals — "Increasing quantity of headphones to 3 leaves the line total unchanged" → bug 7
- Buttons & layout — "Add to cart on Wireless Earbuds does nothing until the window is resized" → bug 8
