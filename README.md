# CDL App (working title)

An **unofficial** iPhone app for following the Call of Duty League, with Live Activities
(Lock Screen + Dynamic Island) in the style of Apple Sports.

The plan and roadmap live in the Claude Project docs: **"CDL App — Plan & Roadmap"**.

## Project map

```
CDL App/                         the iPhone app — Xcode includes every file in here automatically
├── App/                         app entry point + the tab bar (ContentView)
├── Models/                      OUR clean data types: Team, Player, TeamStanding, Match
├── Scrapers/                    everything that talks to websites
│   ├── CDLPageLoader            download a CDL page → its __NEXT_DATA__ JSON
│   ├── TeamsScraperService      /en-us/teams      → [Team]
│   ├── StandingsScraperService  /en-us/standings  → [TeamStanding]
│   ├── ScheduleScraperService   /en-us/schedule   → [Match]   ⚠️ broken by the 2027 site update (step 1.3)
│   └── BreakingPointRosterScraper                             ⚠️ legacy — delete in step 1.2
├── Views/                       one folder per tab
│   ├── Schedule/  Standings/  Teams/  Live/
│   └── Components/              small reusable pieces (TeamBadge)
├── Shared/                      ⚠️ compiled into BOTH the app and the widget
│   ├── TeamTheme.swift          hard-coded team list (being replaced by scraped data)
│   └── Color+Hex.swift          Color(hex: "#782CF2")
└── Assets.xcassets              images (also shared with the widget)

CDLWidgets/                      the widget extension — the Live Activity's look
```

## How data flows

```
CDL website JSON  →  Scraper (raw structs that mirror the JSON)  →  our Model (Team, …)  →  Views
```

Views never touch raw website JSON. If the CDL changes its site, only the scraper changes.

## House rules

1. **Match teams by their numeric CDL team ID, never by name.** The same team has different
   names on different CDL pages ("New York Cloud9" vs "Cloud9 New York").
2. **New Swift file?** Create it in the right folder; Xcode picks it up automatically.
3. **Need a file in the widget too?** Put it in `Shared/` *and* tick **CDLWidgetsExtension** under
   Target Membership (File inspector, right sidebar).
4. **The Live Activity can't download anything.** Everything it shows must be handed to it
   (team abbreviation, color, scores…).
5. Unofficial project: not affiliated with the Call of Duty League or Activision.
