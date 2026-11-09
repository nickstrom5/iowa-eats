# Iowa Plates: name, icon and palette

**Final: Nick's decision of 2026-11-07 ("Yes, as proposed" on the 17-state review page).**
The name and palette as below; the icon is B, the sweet corn, because a tenderloin was Indiana's.

## Name
- **Iowa Plates** (App Store name "Iowa Plates: Restaurants", 24 characters; subtitle "Tenderloins & Loose Meats"; Home Screen "Iowa
  Plates"). The prompt's directions: "Iowa Eats" has the best search fit, but the "Iowa Eatz" delivery app has been in Food & Drink since
  2020 and iowaeats.com is taken, so a near-identical name risks confusion; "Iowa Plates" (domain unregistered in September 2026) and
  "Iowa Table" (domain parked) are the alternatives. The repo and site path stay `iowa-eats`, like the family's other renamed states.
- Avoided: "This Is Iowa" (the state's brand), the Iowa Pork Producers' "Tenderloin Trail", Hawkeye or Cy-Hawk wording.

## Icon (state-prompts/ICON-STYLE.md; all three pass state-prompts/icon-style/check.swift)
- A: a breaded pork tenderloin twice the width of its bun, side elevation (dropped 2026-11-07: Indiana's icon is a tenderloin).
- **B, chosen (final): an ear of sweet corn with the husk peeled back, upright** (the clearest at 60 px).
- C: a loose-meat sandwich (reads as a generic burger at 60 px).
Skipped, per the prompt: the Dutch letter (its "S" reads as a letter). Drawn by `scripts/icon-concepts.swift`; `scripts/make-brand.swift`
makes the app icon, favicons, touch icons and og.png from B; make-site.py's LOGO is the same drawing.

## Palette (landscape and flag; no black-and-gold or cardinal-and-gold blocks)
| Role | Hex | Contrast |
|---|---|---|
| Titles, tint, honors and oldest cards | field green #2F5D34 | 7.7:1 on white |
| Hand-checked guide cards, chips | flag blue #1D3F8C | white on it 9.8:1 |
| Pins, the title shadow (fill only) | corn gold #F2B705 | #1A1A1A on it 10.3:1; never text on white (1.8:1) |
| Pages | cream #F7F1E3 | |

## Header
Contour-plowed crop rows seen from above (`Theme.swift` Stripes; the site's RAYS band; og.png).
