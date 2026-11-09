# Iowa sources and calibration (checked 2026-11-06)

## Official sources
| Source | What it has | Can a script read it? | Used |
|---|---|---|---|
| DIAL's inspection search (iowa.safefoodinspection.com/Inspection/PublicInspectionSearch.aspx) | every jurisdiction's reports: date, type, jurisdiction, violations (risk factors vs good retail practices) | search-only (ASP.NET postbacks; an Export per query); being replaced by SAFHER (no date) | linked from every place; no score or grade exists, none computed |
| Department of Revenue "Retail Sales and Retail Use Business Registrations" (data.iowa.gov dataset 723, CC BY 4.0) | 373,822 permits with NAICS, address, county FIPS, status | data.iowa.gov's robots.txt disallows ClaudeBot | no: Nick's call (he could download it, or approve) |
| Department of Revenue alcohol license lookup (govconnect.iowa.gov) | licensees | search-only, needs cookies and scripts | no; "Serves alcohol" is unknown everywhere |
| Iowa Open Records portal (iowaopenrecords.nextrequest.com) | bulk extracts on request | a records request | not sent (Nick's call) |

No official list is read, so nothing is calibrated against one: the keep rule is the family's (Meta 0.95, or 0.90 with a website). No
Google data is read anywhere.

## Counts
App: 7,448 places, 6,739 restaurants (Census CBP 2023: 6,646 NAICS 722 establishments). Overture: 14,948 eating and drinking listings.
Casey's and Hy-Vee counters are hidden with the non-restaurants (shown with "include non-restaurants"): Nick's call whether they appear.

## Research hosts (check_sources.py)
Usable: traveliowa.com, iowapork.org, iabeef.org, catchdesmoines.com, visitquadcities.com, littlevillagemag.com, axios.com,
iowapublicradio.org, thegazette.com, siouxcityjournal.com, pella.org, dsmmagazine.com, tastingtable.com, qctimes.com, visitsiouxcity.org,
visitdubuque.com, weareiowa.com, jamesbeard.org. Blocked: desmoinesregister.com, kcci.com, who13.com, travelandleisure.com (robots.txt);
amanacolonies.com (bot check). The Iowa Beef Industry Council's Iowa's Best Burger list is a public vote, so it isn't used.
