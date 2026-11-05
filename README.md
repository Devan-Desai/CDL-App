# CDL App (working title)

An **unofficial** iPhone app for following the Call of Duty League, with Live Activities
(Lock Screen + Dynamic Island) in the style of Apple Sports.

The plan, roadmap and walkthroughs live in the Claude Project docs.

## Project map

```
CDL App/                         the iPhone app — Xcode includes every file in here automatically
├── App/                         app entry point, tab bar, TeamLogos (team ID → logo image + on/off switch)
├── Models/                      OUR clean data types: Team, Player, TeamStanding, Match, MatchDetail
├── Scrapers/                    everything that talks to websites
│   ├── CDLPageLoader            download a CDL page → its __NEXT_DATA__ JSON
│   ├── JSONFinder               find a key anywhere in that JSON, however deep
│   ├── TeamsScraperService      /en-us/teams        → [Team]
│   ├── StandingsScraperService  /en-us/standings    → [TeamStanding]
│   ├── ScheduleScraperService   /en-us/schedule     → [Match]
│   └── MatchDetailService       /en-us/match/{id}   → MatchDetail (map-by-map)
├── Storage/                     DataCache — saves the last good data on the phone (offline + instant start)
├── LiveActivity/                LiveActivityController — start / update / end the Lock Screen scoreboard
├── Views/                       one folder per tab
│   ├── Schedule/  Standings/  Teams/  Live/  Match/
│   └── Components/              small reusable pieces (TeamBadge, TeamLogo)
├── Shared/                      ⚠️ compiled into BOTH the app and the widget
│   └── Color+Hex.swift          Color(hex: "#782CF2"), readable text color on any team color
└── Assets.xcassets              images (also shared with the widget)

CDLWidgets/                      the widget extension — the Live Activity's look (CDLWidgetsLiveActivity)
```

## How data flows

```
CDL website JSON → Scraper (raw structs that mirror the JSON) → our Model (Team, Match, …)
                 → shared store (created once in CDL_AppApp, read with @EnvironmentObject) → Views
                 → DataCache (last good copy on the phone)
Match page → LiveActivityController → Live Activity (Lock Screen / Dynamic Island)
```

Views never touch raw website JSON. If the CDL changes its site, only the scraper changes.

## House rules

1. **Match teams by their numeric CDL team ID, never by name.** The same team has different
   names on different CDL pages ("New York Cloud9" vs "Cloud9 New York").
2. **New Swift file?** Create it in the right folder; Xcode picks it up automatically.
3. **Need a file in the widget too?** Put it in `Shared/` *and* tick **CDLWidgetsExtension** under
   Target Membership (File inspector, right sidebar).
4. **The Live Activity can't download anything.** Everything it shows is handed to it by the app.
5. **Logos:** `TeamLogos.useBundledLogos` switches every logo in the app on/off (off = colored badges).
   Keep it off for anything published unless we have permission.
6. Unofficial project: not affiliated with the Call of Duty League or Activision.
