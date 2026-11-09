"""Writes data/research/app/*.json (hand-checked Iowa guides), data/research/michelin.json, jbf.json and closed.json from the compact
lists below. Ported from mn-eats/pipeline/build_research.py.

Each entry cites the pages that name it, read on 2026-11-06: the Iowa Pork Producers Association's breaded pork tenderloin contest page
(2026 and 2025 results, judged), Travel Iowa's own pages and listings (the Iowa Economic Development Authority's tourism office; robots
allow them), Tasting Table's dated lists and jamesbeard.org. The Des Moines Register, KCCI, WHO 13 and Travel + Leisure disallow Claude in
robots.txt and amanacolonies.com answers with a bot check, so none is cited. The Iowa Beef Industry Council's burger contest is a public
vote, so it isn't used (no readers' polls).
The address comes from the map listing we already hold for that name in that town (site/iowa.json); a name that isn't found exactly once
in its town (or at the street number given) is left out and listed in data/research/app/LEADS.md. A place the map data doesn't show as a
place to eat is added only with the street address its listing gives (ADDR).
Usage: ../.venv/bin/python build_research.py   (then iowa.py)"""
import json, os, re
from brands import brand_of
from common import norm_name
ROOT = os.path.join(os.path.dirname(__file__), "..")
R = os.path.join(ROOT, "data", "research")
d = json.load(open(os.path.join(ROOT, "site", "iowa.json")))
C, M = d["cols"], d["meta"]
norm = lambda s: re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", " ", (s or "").lower().replace("'", "").replace("’", ""))).strip()

IPPA = "https://www.iowapork.org/community/contests/breaded-tenderloin-contest"          # 2026 and 2025 results (© 2026)
TI = "https://www.traveliowa.com/"
TI_PIZZA = TI + "the-best-pizza-in-iowa/"                                                 # Travel Iowa (© 2026)
TI_TV = TI + "as-seen-and-eaten-on-tv/"                                                   # Travel Iowa (© 2026)
TI_EURO = TI + "6-european-vacations-in-iowa/"                                            # Travel Iowa (© 2026)
TI_SC48 = TI + "how-to-spend-48-hours-in-sioux-city/"                                     # Travel Iowa (© 2026)
TI_TAYLOR = TI + "places/taylor-s-maid-rite/7204/"                                        # Travel Iowa listing
TI_MAIDRITE = TI + "places/maid-rite/5317/"                                               # Travel Iowa listing
TT_OLDREST = "https://www.tastingtable.com/1975409/oldest-restaurant-every-state-still-open/"   # 2025-09-23
TT_OLDBAR = "https://www.tastingtable.com/1786324/oldest-bar-every-state/"                      # 2025-02-17
JBF26 = "https://www.jamesbeard.org/stories/james-beard-award-semifinalists-2026"                   # 2026-01-21
JBF25 = "https://www.jamesbeard.org/stories/the-2025-james-beard-award-semifinalists"               # 2025-01-22
ARCH_IA = "https://archive.jamesbeard.org/awards/search?categories%5BRestaurant+=&+Chef%5D=1&ranks%5BWinner%5D=1&year=&keyword=Iowa"
DSM, CR = "Des Moines", "Cedar Rapids"
T26 = "The Iowa Pork Producers Association's 2026 breaded pork tenderloin contest"
T25 = "the association's 2025 contest"

GUIDES = {
 "pork tenderloin": [   # the Iowa Pork Producers Association's judged contest, 2026 and 2025 (finalists picked by its committee)
  ("Wasted Grain", "Carroll", "1235", f"The 2026 champion of {T26[4:]}.", None, None, [IPPA]),
  ("Friend's Hide-A-Way", "Underwood", "200", f"Runner-up in {T26[4:]}.", None, None, [IPPA]),
  ("Landmark Grill & Grind", "Williamsburg", "128", f"A finalist in {T26[4:]}.", None, None, [IPPA]),
  ("Sasquatch Jacks", "Waverly", "118", f"A finalist in {T26[4:]} (Sasquatch Jacks Hideaway Barroom & Grill).", None, None, [IPPA]),
  ("Tin Roost", "North Liberty", "840", f"A finalist in {T26[4:]}.", None, None, [IPPA]),
  ("Hometown Heroes", "Grinnell", "908", "Winner of the Iowa Pork Producers Association's 2025 breaded pork tenderloin contest.", None, None, [IPPA]),
  ("Dexfield Diner and Pub", "Redfield", "1119", "A finalist in the Iowa Pork Producers Association's 2025 breaded pork tenderloin contest.", None, None, [IPPA]),
  ("Sugars cb", "Council Bluffs", "2725", "Sugar's Lounge & Diner, a finalist in the Iowa Pork Producers Association's 2025 tenderloin contest.", None, None, [IPPA]),
  ("Walker's", "Salix", "301", "A finalist in the Iowa Pork Producers Association's 2025 breaded pork tenderloin contest.", None, None, [IPPA])],
 "loose meat": [
  ("Muscatine Maid-Rite", "Muscatine", "3414", "Travel Iowa's listing calls it the home of the original loose meat sandwich, serving Muscatine since 1926.",
   None, None, [TI_MAIDRITE, TI_TV]),
  ("Taylor's Maid-Rite", "Marshalltown", None, "A loose meat sandwich diner since 1928, per Travel Iowa's listing.", None, None, [TI_TAYLOR]),
  ("Tastee Inn and Out", "Sioux City", "2610", "Loose meat sandwiches, a staple since it opened in 1955, plus onion chips and ice cream.", None, None, [TI_SC48])],
 "iowa pizza": [   # Travel Iowa's pizza roundup (taco pizza and Quad Cities style among them)
  ("A & A Pagliai's Pizza", "Iowa City", "302", "Known for its thin-crust Palace Special.", None, None, [TI_PIZZA]),
  ("Fong's Pizza", DSM, "317", "Asian-Italian pizza; the crab rangoon pizza is its best seller.", None, None, [TI_PIZZA, TI_TV]),
  ("The Great Plains Sauce and Dough Company", "Ames", "129", "Six crusts, three thick and three thin.", None, None, [TI_PIZZA]),
  ("Mabe's Pizza", "Decorah", "110", "Square-cut pizza; it began in 1953 as a lunchroom.", None, None, [TI_PIZZA, TI_EURO]),
  ("P's Pizza House", "Le Mars", "630", "Known for its pepperoni cream cheese pizza.", None, None, [TI_PIZZA]),
  ("Zeno's", "Marshalltown", "109", "A thin-crust pizzeria downtown for about 64 years, with a BLT pizza.", None, None, [TI_PIZZA]),
  ("Salvatore's by Papa Reno Italian Restaurant", "Muscatine", "313", "Family recipes from Sicily, a downtown fixture since 1985.", None, None, [TI_PIZZA]),
  ("Harris Pizza", "Bettendorf", "2520", "Quad Cities-style pizza: hand-tossed crust and signature sausage.", None, None, [TI_PIZZA]),
  ("Happy Joe's Pizza", "Davenport", "201", "Happy Joe's says it invented taco pizza (a claim).", None, None, [TI_PIZZA])],
 "heritage table": [   # Travel Iowa's European heritage towns
  ("Ox Yoke Inn", "Amana", None, "Family-style dining in the Amana Colonies, known for honey apple pork.", None, None, [TI_TV, TI_EURO]),
  ("Ronneburg Restaurant", "Amana", "4408", "A restaurant in the Amana Colonies, Iowa's German heritage villages.", None, None, [TI_EURO]),
  ("Jaarsma Bakery", "Pella", "727", "A Dutch bakery in Pella, Iowa's Dutch heritage town.", None, None, [TI_EURO]),
  ("Brad's Bakery Bistro", "Orange City", "101", "A bakery bistro in Orange City, a Dutch heritage town.", None, None, [TI_EURO]),
  ("Larsen's Pub", "Elk Horn", "4206", "A pub in Elk Horn, the Danish settlement in western Iowa.", None, None, [TI_EURO]),
  ("Sykora Bakery", CR, None, "A Czech bakery in Cedar Rapids's Czech Village.", None, None, [TI_EURO])],
 "oldest": [
  ("Breitbach's Country Dining", "Sherrill", "563", "Tasting Table names it Iowa's oldest restaurant and bar: on the same site since 1852, in a building that dates to 2009.",
   1852, "Tasting Table (2025): in operation since 1852 on the same site; the current building dates to 2009.", [TT_OLDREST, TT_OLDBAR, ARCH_IA])],
}
ADDR = {("Ox Yoke Inn", "Amana"): "4420 220th Trl", ("Sykora Bakery", CR): "73 16th Ave SW"}
CUISINE = {("Ox Yoke Inn", "Amana"): "European", ("Sykora Bakery", CR): "Bakery & Sweets", ("Ronneburg Restaurant", "Amana"): "European",
           ("Muscatine Maid-Rite", "Muscatine"): "Sandwiches & Deli", ("Taylor's Maid-Rite", "Marshalltown"): "Sandwiches & Deli",
           ("Tastee Inn and Out", "Sioux City"): "Sandwiches & Deli"}
KINDS = {k: [k] for k in ("pork tenderloin", "loose meat", "iowa pizza", "heritage table", "oldest")}

# MICHELIN: no guide covers Iowa (guide.michelin.com/us/en/iowa/restaurants answered 404 in September 2026)
MICHELIN = []
MI_MATCH = {}
MI_UT = None
MID = "Best Chef: Midwest"
JBF = [{"name": "Breitbach's Country Dining", "city": "Sherrill", "honors": ["America's Classics 2009"], "sources": [ARCH_IA]},
       {"name": "Archie's Waeside", "city": "Le Mars", "honors": ["America's Classics 2015"], "sources": [ARCH_IA]},
       {"name": "Masao", "city": DSM, "honors": [f"{MID} semifinalist 2026 (Nick Hanke and Phil Shires)"], "sources": [JBF26]},
       {"name": "Oak Park", "city": DSM, "address": "3901 Ingersoll Ave", "honors": [f"{MID} semifinalist 2026 (Ian Robertson)"], "sources": [JBF26]},
       {"name": "The Contrary", "city": DSM, "honors": ["Best New Bar semifinalist 2026"], "sources": [JBF26]},
       {"name": "Deluxe Cakes and Pastries", "city": "Iowa City", "honors": ["Outstanding Bakery semifinalist 2026"], "sources": [JBF26]},
       {"name": "Simon's", "city": DSM, "honors": ["Outstanding Hospitality semifinalist 2025"], "sources": [JBF25]},
       {"name": "Cobble Hill", "city": CR, "honors": [f"{MID} semifinalist 2025 (Andy Schumacher)"], "sources": [JBF25]}]
CLOSED = []


def key(s):
    """The name key without a leading "the": "Varsity" is our "The Varsity"."""
    return re.sub(r"^the ", "", norm(s))


def find(name, town, num):
    k = key(name)
    hits = [i for i, n in enumerate(C["name"]) if C["city"][i] is not None and M["cities"][C["city"][i]] == town
            and (key(n) == k or key(n).startswith(k + " ") or k.startswith(key(n) + " ") or key(n).replace(" ", "") == k.replace(" ", "")
                 or (key(n).split()[:2] == k.split()[:2] and len(k.split()) >= 2))]
    if num:
        hits = [i for i in hits if (C["addr"][i] or "").split(" ")[0] == num]
    return hits


leads, n_out = [], {}
for kind, rows in GUIDES.items():
    out = []
    for name, town, num, note, founded, fnote, srcs in rows:
        hits = find(name, town, num)
        if not hits and (name, town) in ADDR:
            out.append({"name": name, "address": ADDR[(name, town)], "city": town, "zip": None, "kinds": KINDS[kind], "dishes": [], "note": note,
                        "founded": founded, "founded_note": fnote, "website": None, "open": True, "evidence_date": "2026-10",
                        "sources": srcs, "match_names": []} | ({"cuisine": CUISINE[(name, town)]} if (name, town) in CUISINE else {}))
            continue
        if len(hits) != 1:
            leads.append(f"- {kind}: {name} ({town}{', ' + num if num else ''}) — {len(hits)} matches in our data; not added"); continue
        i = hits[0]
        out.append({"name": C["name"][i], "address": C["addr"][i], "city": town, "zip": str(C["zip"][i]) if C["zip"][i] else None,
                    "kinds": KINDS[kind], "dishes": [], "note": note, "founded": founded, "founded_note": fnote, "website": None, "open": True,
                    "evidence_date": "2026-10", "sources": srcs, "match_names": [name.upper()] if norm(name) != norm(C["name"][i]) else []})
        if brand_of(norm_name(name)):   # a chain shows under its own spelling at every branch, whatever the listing says
            out[-1]["display"] = name
        if (name, town) in CUISINE:
            out[-1]["cuisine"] = CUISINE[(name, town)]
    fn = re.sub(r"[^a-z]+", "_", kind).strip("_")
    json.dump(out, open(f"{R}/app/{fn}.json", "w"), indent=1, ensure_ascii=False)
    n_out[kind] = len(out)

MI_ADDR = {}
json.dump({"restaurants": [{"name": n, "address": MI_ADDR.get(n), "city": t, "zip": None, "distinction": dist, "cuisine": cu, "green_star": False,
                             "michelin_url": MI_UT, "sources": [MI_UT], "match_names": [x.upper() for x in MI_MATCH.get(n, [])], "open": True}
                            for n, t, dist, cu in MICHELIN]}, open(f"{R}/michelin.json", "w"), indent=1, ensure_ascii=False)
json.dump([dict({"address": None}, **j, zip=None, open=True) for j in JBF], open(f"{R}/jbf.json", "w"), indent=1, ensure_ascii=False)
json.dump(CLOSED, open(f"{R}/closed.json", "w"), indent=1, ensure_ascii=False)
open(f"{R}/app/LEADS.md", "w").write("# Iowa research leads (not yet verified)\n\nWritten by pipeline/build_research.py.\n\n" + "\n".join(leads) + """

## Waiting for a source we may use, or for the map data
- Loose meats: Ross' Restaurant in Bettendorf (its Magic Mountain, Travel Iowa) isn't in our map data; Miles Inn's Charlie Boy isn't
  described as a loose meat on any page we read.
- Tenderloins: The 1854 (Gilbertville, the 2025 runner-up) has a name that is only a number, which the matcher can't use yet.
- Pizza: Zipp's Pizzaria (Adair) isn't in our map data; Park Farm Winery (Durango) is a winery.
- Burgers: the Iowa Beef Industry Council's Iowa's Best Burger list is a public vote, so it isn't used.
- Steakhouses and supper clubs: Archie's Waeside carries its America's Classic; no 2025-26 page we read lists others (steak de Burgo
  wasn't found on Travel Iowa).
- Oldest: Taylor's Maid-Rite (1928), Tastee Inn and Out (1955) and Mabe's Pizza (1953) have years without the address tied to them.
- Official data: data.iowa.gov's robots.txt disallows ClaudeBot, so the Department of Revenue's NAICS sales-tax permit list (CC BY 4.0)
  isn't downloaded (Nick's call); DIAL's inspection portal is search-only.
- Blocked or unusable hosts: desmoinesregister.com, kcci.com, who13.com and travelandleisure.com disallow Claude; amanacolonies.com
  answers with a bot check.
""")
print(n_out, "| leads:", len(leads))
for l in leads: print(l)
