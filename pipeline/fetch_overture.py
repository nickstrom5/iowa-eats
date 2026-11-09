"""Download the Overture Maps extracts that iowa.py reads -> data/ia/

- overture_ia_bbox.parquet     every place in Iowa's bounding box (name, category, address, point)
- overture_ia_sources.parquet  which datasets each Iowa eating/drinking listing came from (Meta, Foursquare, ...)
- ia_shapes.json               simplified state and county outlines for the map
- ia_state_detail.geojson      the state outline at full detail, for the in-state test

Reads the public Overture bucket over S3 with DuckDB (no account needed). Ported from mn-eats/pipeline/fetch_overture.py.
Iowa: land division areas; the "counties" are its 99. The script checks the towns on its river lines (Council Bluffs and Omaha, Sioux
City and South Sioux City, the Quad Cities, Dubuque and East Dubuque, Burlington, Keokuk) so a Nebraska, South Dakota, Minnesota,
Wisconsin, Illinois or Missouri listing stays out.
"""
import os, json, time
import duckdb
from shapely import wkb
from shapely.geometry import mapping, Polygon

RELEASE = "2026-10-21.0"
OUT = os.path.join(os.path.dirname(__file__), "..", "data", "ia")
# Iowa (40.38°N–43.50°N, 90.14°W–96.64°W) plus a margin for the river towns (Council Bluffs, the Quad Cities, Dubuque, Sioux City)
BBOX = "bbox.xmin BETWEEN -96.8 AND -90.0 AND bbox.ymin BETWEEN 40.3 AND 43.6"
EAT = "('restaurant','casual_eatery','bar','fast_food_restaurant','coffee_shop','cafe','smoothie_juice_bar','brewery','food_court')"
os.makedirs(OUT, exist_ok=True)

con = duckdb.connect()
con.execute("INSTALL httpfs; LOAD httpfs; INSTALL spatial; LOAD spatial; SET s3_region='us-west-2';")
places = f"s3://overturemaps-us-west-2/release/{RELEASE}/theme=places/type=place/*.parquet"

t = time.time()
if not os.path.exists(f"{OUT}/overture_ia_bbox.parquet"):
    con.execute(f"""
COPY (
  SELECT id, names.primary AS name, basic_category AS cat, taxonomy.primary AS tax, taxonomy.hierarchy AS hier, confidence,
         operating_status AS status, brand.names.primary AS brand, addresses[1].freeform AS street, addresses[1].locality AS city,
         addresses[1].postcode AS zip, addresses[1].region AS region, ST_Y(geometry) AS lat, ST_X(geometry) AS lon, websites[1] AS web,
         phones[1] AS phone
  FROM read_parquet('{places}', hive_partitioning=1) WHERE {BBOX}
) TO '{OUT}/overture_ia_bbox.parquet' (FORMAT PARQUET)""")
    print("places in bbox", round(time.time() - t), "s", flush=True)
if not os.path.exists(f"{OUT}/overture_ia_sources.parquet"):
    con.execute(f"""
COPY (
  SELECT id, list_transform(sources, lambda x: x.dataset) AS ds, list_transform(sources, lambda x: x.update_time) AS ut,
         list_transform(sources, lambda x: x.record_id) AS rid,
         len(socials) AS n_soc, len(websites) AS n_web, len(phones) AS n_ph
  FROM read_parquet('{places}', hive_partitioning=1)
  WHERE {BBOX} AND basic_category IN {EAT}
) TO '{OUT}/overture_ia_sources.parquet' (FORMAT PARQUET)""")
    print("sources", round(time.time() - t), "s", flush=True)

areas = f"s3://overturemaps-us-west-2/release/{RELEASE}/theme=divisions/type=division_area/*.parquet"
rows = con.execute(f"""
  SELECT subtype, names.primary AS name, ST_AsWKB(geometry) AS g
  FROM read_parquet('{areas}', hive_partitioning=1)
  WHERE country = 'US' AND region = 'US-IA' AND subtype IN ('region', 'county') AND class = 'land'
    AND bbox.xmin > -96.9 AND bbox.xmax < -89.9 AND bbox.ymin > 40.2 AND bbox.ymax < 43.7""").fetchall()


def rings(geom, tol, min_area):
    geom = geom.simplify(tol, preserve_topology=True)
    polys = [p for p in getattr(geom, "geoms", [geom]) if p.geom_type == "Polygon" and p.area >= min_area]
    return [[[round(x, 3), round(y, 3)] for x, y in p.exterior.coords] for p in polys]


out = {"state": None, "counties": []}
for sub, name, g in rows:
    geom = wkb.loads(bytes(g)).buffer(0)
    if sub == "region":
        json.dump(mapping(geom.simplify(0.0005, preserve_topology=True)), open(f"{OUT}/ia_state_detail.geojson", "w"))
        out["state"] = [[r] for r in rings(geom, 0.002, 0.000005)]
    else:
        out["counties"].append({"name": name, "c": rings(geom, 0.004, 0.00002)})
# full-detail county polygons for assigning each place to a county (not shipped)
json.dump({name: mapping(wkb.loads(bytes(g)).buffer(0).simplify(0.0003, preserve_topology=True))
           for sub, name, g in rows if sub == "county"}, open(f"{OUT}/ia_counties_detail.geojson", "w"))
json.dump(out, open(f"{OUT}/ia_shapes.json", "w"), separators=(",", ":"))
print("outlines: state", len(out["state"] or []), "rings +", len(out["counties"]), "counties;", round(time.time() - t), "s total")
# border towns: each must fall on the right side of the detailed state outline
from shapely.geometry import shape, Point
st = shape(json.load(open(f"{OUT}/ia_state_detail.geojson")))
for nm, lon, lat, want in [("Council Bluffs", -95.8608, 41.2619, True), ("Davenport", -90.5776, 41.5236, True), ("Bettendorf", -90.5157, 41.5245, True),
                           ("Sioux City", -96.4003, 42.4999, True), ("Dubuque", -90.6646, 42.5006, True), ("Burlington", -91.1129, 40.8075, True),
                           ("Keokuk", -91.3849, 40.3973, True), ("Lansing", -91.2168, 43.3622, True), ("Hamburg", -95.6577, 40.6064, True),
                           ("Clinton", -90.1887, 41.8445, True), ("Fort Madison", -91.3157, 40.6298, True),
                           ("Omaha, NE", -95.9345, 41.2565, False), ("Rock Island, IL", -90.5787, 41.5095, False), ("Moline, IL", -90.5151, 41.5067, False),
                           ("South Sioux City, NE", -96.4136, 42.4739, False), ("North Sioux City, SD", -96.4831, 42.5272, False),
                           ("East Dubuque, IL", -90.6429, 42.4920, False), ("Albert Lea, MN", -93.3683, 43.6480, False), ("Kahoka, MO", -91.7196, 40.4206, False),
                           ("Fulton, IL", -90.1593, 41.8673, False), ("Nauvoo, IL", -91.3849, 40.5506, False)]:
    ok = st.contains(Point(lon, lat))
    print(f"  {nm}: {'inside' if ok else 'outside'}{'' if ok == want else '  <-- WRONG'}")
print("counties:", len(out["counties"]), sorted(c["name"] for c in out["counties"]))

# the neighbours' land (Minnesota, Wisconsin, Illinois, Missouri, Nebraska, South Dakota): listings.py widens Iowa's outline ~300 m for
# river banks, but only where no neighbour's land is, so an Omaha, Moline or East Dubuque listing on the far side of the river stays out
nb = con.execute(f"""
  SELECT region, ST_AsWKB(geometry) FROM read_parquet('{areas}', hive_partitioning=1)
  WHERE country = 'US' AND region IN ('US-MN', 'US-WI', 'US-IL', 'US-MO', 'US-NE', 'US-SD') AND subtype = 'region' AND class = 'land'""").fetchall()
from shapely.ops import unary_union
from shapely.geometry import box
near = box(-96.9, 40.2, -89.9, 43.7)
nbg = unary_union([wkb.loads(bytes(g)).buffer(0).intersection(near) for _, g in nb])
json.dump(mapping(nbg.simplify(0.0002, preserve_topology=True)), open(f"{OUT}/ia_neighbors.geojson", "w"))
print("neighbours:", sorted(r for r, _ in nb))
