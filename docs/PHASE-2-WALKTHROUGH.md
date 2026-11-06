# Phase 2 walkthrough — what changed and why (Nov 4, 2026)

> Copied from the Claude Project ("CDL Live Activities App") on Nov 6, 2026.

Written for later, when you have time to learn it. Each section is one commit on the `phase-2` branch, so you can open it in Xcode's Source Control navigator (or on GitHub once pushed) and see exactly what changed.

**Status when written:** five commits on `phase-2`, not built yet (no Xcode on Claude's side) and not pushed. First step: build (⌘B) and fix any errors.

---

## 0. Finishing 1.5: shared data stores (`b40f82d`)

**What:** the app creates the teams, standings and schedule stores **once** (`App/CDL_AppApp.swift`) and puts them in the SwiftUI *environment*. Every screen reads the same copy with `@EnvironmentObject`. Your TODO (team schedule rows using scraped abbreviations/colors) was finished the way the hints described.

**Concept: the environment.** A shelf that every screen inside `ContentView` can reach. The app puts objects on the shelf with `.environmentObject(x)`; a screen takes one with `@EnvironmentObject var x: SomeType`. Objects are found by *type*, so there can only be one of each type on the shelf.

**Gotcha:** previews don't start the app, so nothing is on the shelf. That's why previews call `.withPreviewData()`.

---

## 1. Logos by team ID, badges as fallback (`aaa4eea`)

**What:**
- `App/TeamLogos.swift`: team ID → logo image name. Has **one switch**, `useBundledLogos`. `true` shows the images in Assets; `false` makes the whole app logo-free (colored badges), which is the safe setting for anything published.
- `Views/Components/TeamLogo.swift` now takes a `teamId` and shows, in order: the logo → a colored badge with the abbreviation → a gray circle (TBD).
- Removed every name-based logo/color lookup from Standings, Schedule and team pages.
- `Color.readableText(onHex:)` (in `Shared/Color+Hex.swift`) picks black or white text for any team color. For example, black on M80's neon yellow, white on KOI purple.

**Concept: brightness.** Our eyes see green as much brighter than blue. The formula `0.299·red + 0.587·green + 0.114·blue` estimates how bright a color *looks*. Above 0.6 → use black text.

**Try it:** set `useBundledLogos = false`, run, and every logo becomes a badge.

---

## 2. Match detail page (`0770265`) — roadmap 2.1

**What:** tap any match in Schedule → `Views/Match/MatchDetailView.swift`: both teams, series score, each map (mode, map name, score, winner in bold team color) and a VOD link.

**How the data works** (`Scrapers/MatchDetailService.swift`, `Models/MatchDetail.swift`):
- Reads `callofdutyleague.com/en-us/match/{id}`, finding the `cdlMatchDetail` block with `JSONFinder` (same trick as the schedule).
- Facts checked on real pages before writing the code:
  - **"host" = home team.** True on all 33 maps sampled from last season, so host score → team 1.
  - **Unplayed maps are still listed.** In LAT 3–1 MIA, map 5 (Gridlock) has a name but no result. So a map only counts as played when it has a winner.
  - **Teams known but not played** (e.g. match 12778): five empty map slots.
  - **Teams not decided** (every 2027 Kickoff match right now): no match data at all → "hasn't published details yet".
- During a live match, the **current map** = the first map with a name but no winner. This is a guess based on the shapes above; confirm on Dec 4.

**Concept: computed properties do the thinking.** `MatchDetail` stores the raw facts (maps, winners). Things like `team1MapsWon`, `currentMap` and `visibleMaps` are worked out from them on demand, so they can never disagree with each other.

**Checked:** the decoding rules were mirrored in Python and run against the real LAT–MIA and G2–LAG pages, plus a made-up "halfway through map 4" version. All passed: series 3–1, map 5 hidden, live map 4 detected.

---

## 3. Live Activity driven by real data (`48c0974`) — roadmap 2.2 + 2.3

**What changed in the data** (`CDLWidgets/CDLWidgetsLiveActivity.swift`):
- **Fixed part** (`CDLAttributes`): match ID + each team's abbreviation, color and logo name. The widget can't look anything up, so the app hands it everything.
- **Changing part** (`ContentState`): series score, map number, map name, mode, the score *on that map*, and whether it's final.

**The look:** same idea as your design (team-color gradient, logos, big series score, map pill). The pill now reads e.g. `MAP 4 · HARDPOINT · COLOSSUS   140–121`. With no logo, a team gets a colored badge. The Dynamic Island shows logos and score (compact) or the full scoreboard (expanded).

**The controller** (`LiveActivity/LiveActivityController.swift`):
- `follow(matchId:)`: every 30 s, reads the match page, turns it into a `ContentState`, and updates the Lock Screen. It ends itself when the match is final.
- `replay(matchId:)`: takes a finished match and plays it back as 13 "frames" (each map: kick-off → halfway → final). That lets us test with real data before the season.
- `stop()`: cancels and clears the Lock Screen.

**Where you use it:**
- **Live tab** → "Replay LAT vs MIA (last season)", then lock the phone (⌘L in the Simulator).
- **Match page** → "Follow on Lock Screen" for an upcoming/live match, or "Replay on Lock Screen" for a finished one.

**Important limitation:** following only works **while the app is open**. iOS pauses apps soon after you leave them. Updates with the app closed need a server sending push notifications (Phase 4). Until then, if updates stop for 2 minutes, iOS dims the scoreboard as out of date (`staleDate`).

**Concept: `Task` and cancellation.** The follow loop is a `Task` (work that runs alongside the UI). `while !Task.isCancelled { … sleep 30 s … }` keeps it going; `work?.cancel()` stops it cleanly. The old hard-coded `TeamTheme` was deleted here, since nothing used it anymore.

---

## 4. README (`00dc744`)
New project map: `LiveActivity/`, `Views/Match/`, `TeamLogos`, `JSONFinder`, `MatchDetailService`.

---

## Things to verify when you build
1. **Build errors.** Most likely spots, if any: `CDLWidgetsLiveActivity.swift`, `LiveActivityController.swift`, `MatchDetailView.swift`.
2. **Live tab → Replay.** The Lock Screen should step through Sake → Fringe → Scar → Colossus and end at FINAL 3–1.
3. **Schedule → tap a Kickoff match.** You should see "hasn't published details yet" (teams TBD), which is expected.
4. **Standings / Teams.** Logos for 11 teams; M80 Boston gets a neon badge with **black** "BOS" text.

## Exercises for later (when you have time)
- **Easy:** in `MapResult.shortMode`, add the mode used in MW4 if it isn't Hardpoint / S&D / Overload / Control. Then show `shortMode` in the compact Dynamic Island.
- **Medium:** make the Schedule refresh itself every 60 s while any match is `.live`. Hint: a `.task` with a `while` loop, like the follow loop.
- **Medium:** on the match page, show each team's map count next to its logo while live.
