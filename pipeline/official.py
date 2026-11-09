"""Official records for Iowa -> one table of licensed food businesses (playbook/12-sources.md). Iowa has none a script may read today:
- DIAL (and ten contracted local agencies) inspect restaurants; every report is on DIAL's portal, iowa.safefoodinspection.com, which is
  search-only (ASP.NET postbacks; its Export works per query) and is being replaced by SAFHER. No score, grade or placard. It is linked
  from each place, never scraped; a bulk extract via iowaopenrecords.nextrequest.com is Nick's call.
- The Department of Revenue's "Retail Sales and Retail Use Business Registrations" (data.iowa.gov dataset 723, CC BY 4.0, NAICS codes)
  would be the statewide existence list, but data.iowa.gov's robots.txt disallows ClaudeBot, so this build doesn't download it: Nick's
  call (he could fetch it himself, or approve it).
- Alcohol: the Department of Revenue's license lookup (govconnect.iowa.gov) needs cookies and scripts and has no bulk list, so "Serves
  alcohol" is unknown everywhere, never "no".

load() returns an empty table of the right shape: jur, lic (our id), name, keys (name keys), addr, city, zip, num, street, lat, lon,
kind, active, ltype, insp, biz.
"""
import os, re, json, datetime
from zoneinfo import ZoneInfo
import numpy as np, pandas as pd
from common import norm_name, RAW, name_sim, _stems, GENERIC, canon_city

OFF = os.path.join(RAW, "official")
DIRS = {"N": "N", "S": "S", "E": "E", "W": "W", "NORTH": "N", "SOUTH": "S", "EAST": "E", "WEST": "W"}
TYPES = set("ST STREET AVE AV AVENUE BLVD BOULEVARD RD ROAD DR DRIVE LN LANE CT COURT PL PLACE PKWY PARKWAY TER TRL TRAIL WAY HWY CIR "
            "CIRCLE PLZ SQ MALL BND PASS XING RUN ROW WALK RDG LOOP FWY FREEWAY EXPY EXPRESSWAY PIKE PK PKE".split())


def road(a):
    """One spelling for numbered roads. Iowa writes one road as 'Route 100', 'US 7', 'Rt 2', 'IA 100' or 'IA Route 100', so every
    numbered US or state route is 'SH n' (as in ri-eats); 'N INTERSTATE 95' = 'I-95'; 'COUNTY ROAD 5' = 'CR 5'."""
    a = re.sub(r"(\d)\s*&\s*(\d)", r"\1-\2", a.upper())
    a = re.sub(r"\b(US|IA|SR|SH|CR|I|IH|RT|RTE)-(\w)", r"\1 \2", a)
    a = re.sub(r"\b(?:INTERSTATE(?: HIGHWAY| HWY)?|IH|I H)\s*(?=\d)", "I ", a)
    a = re.sub(r"\b(?:US|U S)\s+(?:HIGHWAY|HWY)\b", "US", a)
    a = re.sub(r"\b(?:FARM[- ]TO[- ]MARKET(?: ROAD| RD)?|FARM (?:ROAD|RD)|F M)\b", "FM", a)
    a = re.sub(r"\b(?:RANCH[- ]TO[- ]MARKET(?: ROAD| RD)?|RANCH (?:ROAD|RD)|RR|RM)\b(?=\s*\d)", "RM", a)
    a = re.sub(r"\b(?:STATE (?:HIGHWAY|HWY|ROAD|RD|ROUTE|RTE)|SR|SH|VERMONT (?:ROUTE|RTE|HIGHWAY|HWY)|IA (?:ROUTE|RTE|RT|HIGHWAY|HWY)|IA|"
               r"US (?:ROUTE|RTE|RT)|US|ROUTE|RTE|RT|HWY)\b\.?(?=\s*\d)", "SH", a)
    a = re.sub(r"\b(?:COUNTY (?:HIGHWAY|HWY|ROAD|RD)|CO RD|CTY (?:HWY|RD)|CR)\b", "CR", a)
    a = re.sub(r"\bHIGHWAY\b", "HWY", a)
    return re.sub(r"\b(US|SH|CR|HWY|FM|RM|I) (\w+)\s*-\s*\w+", r"\1 \2", a)


ORD = {"FIRST": "1ST", "SECOND": "2ND", "THIRD": "3RD", "FOURTH": "4TH", "FIFTH": "5TH", "SIXTH": "6TH", "SEVENTH": "7TH",
       "EIGHTH": "8TH", "NINTH": "9TH", "TENTH": "10TH", "ELEVENTH": "11TH", "TWELFTH": "12TH"}


def street_key(a):
    """'2505 Monroe St' -> ('2505', 'MONROE'); '1000 OSAGE STREET' -> ('1000', 'OSAGE'); 'E Colfax Ave' keeps 'COLFAX'."""
    if not isinstance(a, str):
        return None, None
    a = re.sub(r"[.,#]", " ", road(a))
    # "20940-A North Frederick Ave": a hyphenated unit letter is part of the number (Maryland's Montgomery County wrote them so)
    m = re.match(r"^\s*(\d+)(?:-?[A-Z])?(?:\s*-\s*\d+[A-Z]?)?\s+(.*)$", a)
    if not m:
        return None, None
    words = [w for w in m.group(2).split() if w]
    if len(words) > 1 and words[0] in DIRS:
        words = words[1:]
    core = []
    for w in words:
        if w in TYPES and core:
            break
        core.append(w)
    core = [ORD.get(w, w) for w in core]
    return m.group(1), " ".join(core[:3]) or None


def street_compat(a, b):
    """Same street, or one is a whole-word prefix of the other: Boulder's 2025 set sometimes truncates ("1206 CENTAUR" = Centaur Village Dr)."""
    if not isinstance(a, str) or not isinstance(b, str) or not a or not b:
        return False
    return a == b or a.startswith(b + " ") or b.startswith(a + " ")


def street_nums(a):
    """'157-159 W Main St' -> {'157', '159'}; '2505 Monroe St' -> {'2505'}."""
    if not isinstance(a, str):
        return set()
    a = road(a)
    m = re.match(r"^\s*(\d+)[A-Z]?(?:\s*-\s*(\d+)[A-Z]?)?\s", a.upper() + " ")
    if not m:
        return set()
    lo = int(m.group(1)); hi = int(m.group(2)) if m.group(2) else lo
    if hi < lo:   # "1500-02"
        hi = int(str(lo)[: len(str(lo)) - len(m.group(2))] + m.group(2)) if m.group(2) else lo
    return {str(x) for x in range(lo, hi + 1, 2 if (hi - lo) % 2 == 0 else 1)} if 0 <= hi - lo <= 12 else {str(lo)}


def _names(*vals):
    out = []
    for v in vals:
        if not isinstance(v, str):
            continue
        v = re.sub(r"\s*\((?:MOBILE|MOBILE UNIT|COMMISSARY|CATERING|SPECIAL EVENT|SPEC EVENT|TEMP(?:ORARY)? EVENT|CP|INSIDE [^)]*)\)\s*$", "", v, flags=re.I)
        for part in re.split(r"\s*/\s*|\s+\bdba\b\s+|\s+&\s+(?=[A-Z][a-z])", v, flags=re.I):
            k = norm_name(re.sub(r"\b(?:LLC|INC|CORP|CORPORATION|LTD|CO)\b\.?", "", part, flags=re.I))
            if k and k not in out:
                out.append(k)
    return out


META = {}
LIST_DATE = None
THROUGH = None
MPLS_PAGE = ""
# DIAL's statewide inspection search (every jurisdiction's reports; search-only, so it is only linked)
INSPECTIONS_URL = "https://iowa.safefoodinspection.com/Inspection/PublicInspectionSearch.aspx"
ONPREM_T = ()
MAKER_T = ()
RESULTS = ()


def liq_kind(t):
    return None


COLUMNS = ["jur", "lic", "name", "dba", "holder", "keys", "addr", "city", "zip", "num", "street", "lat", "lon", "kind", "active", "ltype",
           "insp", "issued", "biz", "drinks", "county"]


def _zip(z):
    z = re.sub(r"\D", "", str(z or ""))
    return z[:5] if len(z) >= 5 else ""


def _addr(a):
    """'2790 VETERANS MEMORIAL BLVD STE 130' -> '2790 Veterans Memorial Blvd Ste 130'."""
    a = re.sub(r"\s+", " ", a or "").strip()
    return re.sub(r"\b([A-Z]{2,})\b", lambda m: m.group(1).title(), a)


def _city(c):
    return canon_city(" ".join(w.capitalize() for w in str(c or "").split())) if isinstance(c, str) and c.strip() else None


def _ms(v):
    """An ArcGIS date (epoch milliseconds, UTC) -> YYYY-MM-DD in Iowa's time (the district's own day)."""
    if not isinstance(v, (int, float)):
        return None
    d = datetime.datetime.fromtimestamp(v / 1000, datetime.timezone.utc) - datetime.timedelta(hours=4)
    return d.date().isoformat()


def load():
    """Iowa has no official list a script may read (see the docstring): an empty table of the right shape."""
    df = pd.DataFrame({c: pd.Series(dtype=object) for c in COLUMNS + ["apn"]})
    df["lat"] = df["lat"].astype(float); df["lon"] = df["lon"].astype(float); df["active"] = df["active"].astype(bool)
    df["biz"] = np.arange(len(df))
    return df
