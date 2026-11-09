"""Iowa's open official records -> data/raw/official/ (nothing to fetch today; see official.py).

Checked 2026-11-06: DIAL's inspection portal is search-only (linked, never scraped); the Department of Revenue's NAICS sales-tax permit
list on data.iowa.gov is CC BY 4.0 but data.iowa.gov's robots.txt disallows ClaudeBot, so it isn't downloaded without Nick's yes; the
alcohol license lookup has no bulk list. This script only writes an empty meta.json so the pipeline's steps run in order.
"""
import json, os
OUT = os.path.join(os.path.dirname(__file__), "..", "data", "raw", "official")
os.makedirs(OUT, exist_ok=True)
json.dump({}, open(os.path.join(OUT, "meta.json"), "w"))
print("Iowa: no official list read (see official.py)")
