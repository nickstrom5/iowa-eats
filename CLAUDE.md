# Iowa Plates (ia-eats) — notes for Claude Code sessions

Built 2026-11-06 by a side session for Nick's "build the 17 states left" (group: MN, IA, NE, ND, SD), ported from `../mn-eats/` with
every fix through 11-05 (the exact-outline county lookup, the out-of-county truck rule, Utah's street-word merge fix, Vermont's narrowed
"dejavu" rule, Virginia's near-adult-venue fix, the per-state ZIP check, the delivery-only brands, the website blocklist and
`link_blocklist.py`, the Share link `Links.site + explore/#p=<id>`, OTA data, the adult-venue rules) and wy-eats' far-listing rule.
Local only: git-ignored data, no repo, no remote, nothing published. Sources: `playbook/12-sources.md`.

Brand: `playbook/05-naming.md` — **final**, Nick's decision of 2026-11-07: the name "Iowa Plates", the palette, and icon B (the sweet corn; a tenderloin was
Indiana's).
- Name: "Iowa Plates: Restaurants", Home Screen "Iowa Plates". The "Iowa Eatz" delivery app has been in Food & Drink since 2020, so
  "Iowa Eats" risks confusion.
- Icon: a breaded pork tenderloin.
- Palette: field green #2F5D34, flag blue #1D3F8C, corn gold #F2B705 (fill only) and cream #F7F1E3.
- Header band: crop rows.
- The repo and site path stay `iowa-eats`.

## Iowa is different
- **No Google data at all** (rule of 2026-11-06). The UCSD snapshot is never downloaded, `listings.py` builds an empty Google table, and
  `iowa.py` writes NaN fits as null. The keep rule is the family's: Meta 0.95, or 0.90 with a website.
- **No official list:**
  - DIAL (the Iowa Department of Inspections, Appeals, and Licensing) and ten local agencies post inspection reports only on DIAL's
    search portal. Place pages show no result and link to the portal (`Links.inspections`). The site's inspections page says the same.
  - The Department of Revenue's liquor-license data is on data.iowa.gov, whose robots.txt disallows ClaudeBot, so it's unused.
    "Serves alcohol" is "—" everywhere, and `calibrate.py` has no official list to measure against.
  - Using either source, or a records request to DIAL, is Nick's call.
- **Counties and regions:** 99 counties and six detail files (Central Iowa, Eastern Iowa, Mississippi River, Northeast Iowa, Southern
  Iowa, Western Iowa).
  - `fetch_overture.py` checks the border towns:
    - In: Council Bluffs, Davenport, Bettendorf, Sioux City, Dubuque, Burlington, Keokuk, Lansing, Hamburg, Clinton and Fort Madison.
    - Out: Omaha, Rock Island, Moline, South Sioux City, North Sioux City, East Dubuque, Albert Lea, Kahoka, Fulton and Nauvoo.
  - The app's outline (`LocationService.swift`) cuts the neighbours' land back out.
- **Venues:** the Des Moines (5800 Fleur Dr) and Eastern Iowa (2515 Arthur Collins Pkwy) airports, arenas, ballparks and the State
  Fairgrounds. Stores with food counters (Casey's, Hy-Vee, Fareway, Kwik Star) are hidden as stores. Showing Casey's pizza is Nick's
  call.
- **Names and places:**
  - `data/research/name_fixes.json` renames "Sugars cb" (Council Bluffs) to Sugar's Lounge & Diner.
  - "Boji" and "Okoboji" are place words, not adult-club words.
  - `data/research/adult_venues.json` lists 12 clubs by address.
- **Guides** (tags in `iowa.py` TAGS, bits 1..16; sources in `pipeline/build_research.py`, each note checked against its page on
  2026-11-06):
  - Pork Tenderloins (9): the Iowa Pork Producers Association's 2025 and 2026 winners and finalists.
  - Loose-Meat Sandwiches (3): Muscatine Maid-Rite, Taylor's Maid-Rite and Tastee Inn and Out.
  - Iowa Pizza (9): taco pizza, Quad Cities style and thin crust. Happy Joe's taco-pizza invention stays its own claim.
  - Heritage Tables (6): Amana, Pella, Orange City, Elk Horn and Cedar Rapids's Czech Village.
  - Oldest (1): Breitbach's Country Dining, 1852 per Tasting Table. Home hides the Oldest guide below 3 places, and the site makes an
    oldest page only at 4, so for now it shows only as "Since 1852" on the place itself.
- **Honors:** no MICHELIN Guide covers Iowa. James Beard: 8 honored places, 2 of them America's Classics (one is Breitbach's, 2009).
- **Links:** `pipeline/check_websites.py` treats the five states' papers, TV stations and tourism sites as news (`PLAINS_NEWS`).
  `clean_url` keeps only the first of two links in one field.

## Rebuild
```bash
cd pipeline
../.venv/bin/python check_sources.py URL...   # a new host first
../.venv/bin/python fetch_overture.py && ../.venv/bin/python fetch_extras.py && ../.venv/bin/python fetch_official.py
../.venv/bin/python geocode_official.py && ../.venv/bin/python geocode_census.py && ../.venv/bin/python listings.py
../.venv/bin/python calibrate.py && ../.venv/bin/python iowa.py && ../.venv/bin/python build_research.py && ../.venv/bin/python iowa.py
IA_APP=1 ../.venv/bin/python iowa.py && cd .. && cp data/app/places.json data/app/detail-*.json IowaEats/Resources/
.venv/bin/python pipeline/check_websites.py && .venv/bin/python pipeline/check_websites.py --retry-transient   # then re-export
.venv/bin/python scripts/make-site.py && .venv/bin/python scripts/publish_app_data.py && .venv/bin/python scripts/publish_app_data.py --check
.venv/bin/python scripts/qa-site.py --static
```
`data/chain_auv.json` is a copy of wy-eats'. The `.venv` is on the python.org framework Python 3.12 with the family's versions.

## App, site, screenshots
- **App:** `IowaEats/`.
  - XcodeGen `project.yml`, bundle `com.iowaeats.ios`, display name "Iowa Plates".
  - Tests are in `IowaEatsTests/` and `IowaEatsUITests/`. The unit tests use a 12-place Iowa fixture, plus data guards: adult venues,
    blocklisted and multi-URL websites, bad and legal names, non-restaurants, listed twice, and no Google data.
  - Build and test only with Xcode 1.app (27.2, 27B52); Xcode.app is a beta.
  - Run `xcodegen generate` whenever `Resources/*.json` changes.
- **Site:** `scripts/make-site.py` writes `docs/` and `playbook/site-numbers.json`. `scripts/explore.js` is the web app, and
  `scripts/qa-site.py` the QA.
  - Site URL for now: nickstrom5.github.io/iowa-eats, with no CNAME.
  - City pages: Des Moines.
- **Screenshots:**
  1. `scripts/capture-screenshots.sh <sim>`. ScreenshotMode pins the places:
     - downtown Des Moines by default
     - Grinnell for tenderloins and the Hometown Heroes detail
     - Marshalltown for loose meat
     - the Quad Cities for pizza
     - the Amana Colonies for heritage
  2. `scripts/site-images.sh`, then make-site and qa-site.
  3. App Store frames: `scripts/appstore-screenshots.py`.
- **Listing:** `playbook/app-store/listing.json`.
- **Icons:** `scripts/icon-concepts.swift` and `scripts/make-brand.swift`.

## Status
See the end of this file (written when the build finished).

### Status (2026-11-08 10:20): final
- **Ready to publish; nothing public.** No repo, commit, push, Pages, App Store Connect record
  or build upload; all of those wait for Nick's yes.
- Data: 6,739 restaurants (7,448 places) in 626 towns, 99 counties; 28 hand-checked guide places (9 pork tenderloins, 3 loose meats,
  9 Iowa pizza, 6 heritage tables), 8 James Beard honorees (2 America's Classics). No official list is used: DIAL's inspections are
  search-only (linked from every place, no result shown, no grade), and Iowa ABC's licensee export isn't used, so "Serves alcohol" is
  "—" everywhere.
- Tests (Xcode 1.app 27.2, iOS 27.0), final run 2026-11-08 with the sweet-corn icon: iPhone 17 Pro Max and iPad 13" (M5) each
  passed all 49 unit + 6 UI tests, the launch-time test included (4.68 s to Home on iPhone, 4.87 s on iPad; the limit is 6 s).
  Earlier (11-07) two expectations in the test code were fixed: "Tastee" sorts before "Taylor's", and a town with one place shows
  "1 place ·".
- Site: `docs/` generated with the corn icons and LOGO; `qa-site.py --static` and the full headless-Chrome run both OK (2026-11-07
  08:56; nothing in `docs/` has changed since); `publish_app_data.py --check` OK.
- App Store: 8 iPhone and 6 iPad frames in `playbook/app-store/` (2026-11-06; the app icon appears in none of them and the palette
  didn't change, so the icon change needed no new frames); `listing.json` (Iowa Plates: Restaurants; Tenderloins & Loose Meats;
  support and privacy on nickstrom5.github.io/iowa-eats/).
- Brand final (Nick, 2026-11-07): "Iowa Plates", the palette, and icon B, the sweet corn (app icon, site icons, LOGO and og.png
  regenerated). A DIAL records request is being drafted by the parent session.
