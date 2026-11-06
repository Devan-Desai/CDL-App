# CLAUDE.md — CDL App

Read this first, then `README.md` (project map) and `docs/ROADMAP.md` (plan, data-source notes, status).

## What this is
An **unofficial** iPhone app for the Call of Duty League (CDL) with Live Activities (Lock Screen +
Dynamic Island), in the style of Apple Sports.
- SwiftUI, iOS 26.2 deployment target, Swift 5 language mode, default actor isolation = MainActor.
- Two targets: `CDL App` (the app) and `CDLWidgetsExtension` (the Live Activity). Only dependency: SwiftSoup (SPM).
- Data comes from scraping callofdutyleague.com: every page is Next.js, with its data as JSON in
  `<script id="__NEXT_DATA__">`. There is no official API.
- Season 2027 (Modern Warfare 4) starts Fri Dec 4, 2026, 3:00 PM ET (Major I Kickoff).

## About Devan (the owner)
- M.Sc. researcher, not a computer scientist; learning Swift through this project.
- Explain what you're doing and why in plain words, with concrete examples from this codebase.
- When he has time, he wants to write parts himself: leave small `// TODO: <step> —` comments with
  hints and a worked example to mirror, instead of doing everything.
- When he says he's busy, do the work, then write a short walkthrough of what changed and why
  (style: `docs/PHASE-2-WALKTHROUGH.md`).

## Build and check
- Build for the Simulator (no signing needed):
  `xcodebuild -project "CDL App.xcodeproj" -scheme "CDL App" -destination "generic/platform=iOS Simulator" build`
  If the destination is rejected: `xcodebuild -showdestinations -project "CDL App.xcodeproj" -scheme "CDL App"`.
- Always build after changes and fix errors before handing work back. The app scheme also builds the widget.
- Xcode uses synchronized folders: new files in `CDL App/` join the app target automatically.
  Files in `CDL App/Shared/` must ALSO be members of `CDLWidgetsExtension`
  (`membershipExceptions` in `project.pbxproj`, or Target Membership in Xcode).

## House rules
1. Match teams by their numeric CDL team ID, never by name (names differ between CDL pages).
2. Views never touch raw website JSON: website JSON → raw `Decodable` structs in `Scrapers/` →
   our models in `Models/` → views.
3. Find JSON blocks by key with `JSONFinder` rather than following exact paths (the site moves things).
4. Shared stores (`TeamsScraperService`, `StandingsScraperService`, `ScheduleScraperService`,
   `LiveActivityController`) are created once in `App/CDL_AppApp.swift` and read with `@EnvironmentObject`.
   Previews need `.withPreviewData()`.
5. The Live Activity (`CDLWidgets/CDLWidgetsLiveActivity.swift`, compiled into both targets) can't
   download anything; the app passes everything it shows in `CDLAttributes`.
6. Logos: `TeamLogos.useBundledLogos` (`App/TeamLogos.swift`) switches every logo on/off.
   It must be off for anything published unless we get permission.
7. Be gentle with the CDL site: no tight loops; poll live matches no more than every 30 s.
   Their Terms of Use forbid automated access, which is OK for personal prototyping but NOT for a
   published app without permission (`docs/ROADMAP.md` §4).
8. No "CDL" / "Call of Duty" in the app's name or icon.

## Git
- Work on a branch → merge into `main` → push → start the next branch from `main`. Small commits, clear messages.
- Ask Devan before pushing or rewriting history.

## Current status (Nov 6, 2026)
- Branch `phase-2`: 5 commits (shared stores, logos by team ID, match detail page, real-data Live
  Activity, README). They were written without a compiler, so build and fix them first.
  Not pushed yet; `origin/main` is at the offline-cache commit.
- Uncommitted: Devan's spacing tweak in `CDLWidgetsLiveActivity.swift` (`" - "` in `LiveSeriesScore`).
- Next: build `phase-2`, fix errors, test the Live tab → Replay (match 13100), merge + push.
  Then plan the month before Dec 4 (`docs/ROADMAP.md` §8).
- Open questions for Kickoff weekend (Dec 4–6): the live status word on match pages, whether the
  current map shows a live score, and whether schedule entries gain team cards (`docs/ROADMAP.md` §2).

## Useful facts
- Real finished match for testing: **13100** (LA Thieves 3–1 Miami Heretics, April 2026).
- Team IDs: OpTic 6, FaZe 7, Heretics 9, Ravens 10, Gentle Mates 11, G2 12, Cloud9 13, Falcons 15,
  Surge 16, KOI 17, Thieves 69, M80 Boston 138 (no logo image → colored badge).
- On match pages, "host" = home team (verified on 33 maps from last season).
