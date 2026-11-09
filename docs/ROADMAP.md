# CDL Live Activities App — Plan & Roadmap

> Copied from the Claude Project ("CDL Live Activities App") on Nov 6, 2026 so Claude Code can read it.
> The Project keeps a copy too: if you update one, update the other.

*Written Oct 26, 2026; updated Nov 9. Season 2027 (Modern Warfare 4) starts with the Major I Kickoff Tournament, Fri Dec 4, 2026, 3:00 PM ET.*

---

## 1. Where the project stands

**App (SwiftUI, iOS 26.2, Xcode synchronized folders)**
- Tabs: Schedule, Live, Standings, Teams. Tapping a match in Schedule opens its match page (map-by-map results).
- Live Activity (Lock Screen + Dynamic Island) now runs on **real match data**. You can follow a match (updates every 30 s while the app is open) or replay a finished match to test.
- **Redesigned Live Activity (Nov 9, branch `live-activity-redesign`)**: the live map's score in the middle, series dots (first to 3/4/5), team records, Saira fonts, three background styles (`LiveBackgroundStyle`: blend / split / accent; blend is the default). Built to be the mock-up in the data-access pitch to the CDL / BreakingPoint.
- Repo: `github.com/Devan-Desai/CDL-App`.
  - `origin/main` = Phase 2, built and tested (merged + pushed Nov 9).
  - `monster-test` (pushed): debug-only test that follows BreakingPoint matches (Monster Invitational, Nov 6). Not merged; it also holds the `HJK` short name for Hijack.
  - `live-activity-redesign` (local, not pushed): the redesign above.
- Git flow: work on a branch → merge into `main` (pull request, or local merge + `git push origin main`) → `git pull` → start the next branch from `main`.
- Learning notes: `docs/PHASE-2-WALKTHROUGH.md` explains each Nov 4 commit.

**Folder layout (since Nov 4)**
```
CDL App/
  App/           entry point + tab bar, TeamLogos (team ID → logo, one on/off switch)
  Models/        Team, Player, TeamStanding, Match (+ MatchStatus), MatchDetail (+ MapResult)
  Scrapers/      CDLPageLoader, JSONFinder + one scraper per CDL page (incl. MatchDetailService)
  Storage/       DataCache (last good copy on the phone)
  LiveActivity/  LiveActivityController (follow / replay / stop)
  Views/         Schedule/ Standings/ Teams/ Live/ Match/ Components/
  Shared/        compiled into BOTH app and widget (Color+Hex)
CDLWidgets/      Live Activity UI (CDLAttributes + Lock Screen/Dynamic Island)
```

**Scrapers (status as of Nov 4)**

| Scraper | Source | Status |
|---|---|---|
| `TeamsScraperService` | CDL `/en-us/teams` | ✅ All 12 teams with colors and rosters. Shared app-wide (1.5). |
| `StandingsScraperService` | CDL `/en-us/standings` | ✅ 2027 season (all 0–0). Team IDs. Since Nov 9 also reads Major records (`record(forTeamId:)`), falling back to the season record. |
| `ScheduleScraperService` | CDL `/en-us/schedule` | ✅ 34 Kickoff matches (Dec 4–13), all TBD vs TBD. |
| `MatchDetailService` | CDL `/en-us/match/{id}` | ✅ New (2.1). Series + map-by-map; "not published yet" for TBD matches. |

**Hard-coded data:** `TeamTheme` (name-based) was **deleted Nov 4**. Logos now come from `TeamLogos` (team ID → image name), colors and abbreviations from the teams page. M80 Boston (ID 138) has no logo image, so it gets a colored badge.

**UI fixes:** Standings column headers sit inside the list (Nov 2). Missing logos no longer log "No image named 'default'" (Nov 3). Text on team colors is black or white depending on brightness (Nov 4).

---

## 2. Data sources

All CDL pages are built with Next.js and carry their data as JSON in `<script id="__NEXT_DATA__">`.

| Page | What's in it | Where in the JSON |
|---|---|---|
| `/en-us/teams` | Team ID, full name, location, name, abbreviation, colors, logo URLs (SVG), roster (alias, real name, role, headshot) | `blocks[] → cdlTeamListV3 → teams[]` |
| `/en-us/standings` | Rank, CDL points, series W-L, map W-L, `teamCard {id, name, abbreviation, logos}`; season tabs 2020–2027; inside 2027 one tab per stage: "Regular Season" (open), "MAJOR I"–"MAJOR IV", "POST SEASON" | `… → cdlProStandings → standings[]` |
| `/en-us/schedule` | Grouped by Major → tournament → `cdlMatchCards` with `liveMatches`, `preScheduledMatches`, `upcomingMatches`, `finalMatches` | found with `JSONFinder` |
| `/en-us/match/{id}` | `matchExtended` (team cards with id/name/abbreviation/color, match {id, playTime, status, vodLink}, result) + `matchGamesExtended` (per map: number, map, mode, `matchGameResult {hostGameScore, guestGameScore, winnerTeamId}`) + `matchStats` | `blocks[] → cdlMatchDetail → matchData` |
| BreakingPoint | Deeper stats; an internal API the site itself calls (`/api/trpc/cached.matches.fetchLiveMatches`, `fetchUpcomingMatches`) | not public |

**Schedule page notes (Nov 1):**
- The server only fills in the default-open tab; `?season=2026` doesn't load past seasons.
- Pre-scheduled entries have no team cards. Once teams are known they're expected to gain `homeTeamCard` / `awayTeamCard` / `result`. **Confirm when the Kickoff matchups are announced.**

**Standings page notes (Nov 9):** the Major tabs exist but have no rows yet (only the open tab is filled by the server). The app uses the last Major tab with any series played; until then it shows the season record. **Check on Kickoff weekend** whether Major I gets rows, or becomes the open tab.

**BreakingPoint notes (Monster Invitational test, Nov 6):** match pages are Next.js with `__NEXT_DATA__` (`initialMatchState`). Status words `upcoming` / `live` / `complete`. Their own team IDs (differ from the CDL's, e.g. 11 = G2 there, Gentle Mates here). Finished maps only: in 73 samples no map appeared until it ended, so no live map score. Pages are cached copies, on average ~3.5 min old, up to 12 min.

**Match page notes (Nov 4, sampled ~35 pages):**
- **host = home team** on 33/33 maps.
- Statuses seen: `SCHEDULED` / `COMPLETED` (displayed "FINAL").
- Finished matches list unplayed map slots with names but no result (e.g. map 5 in a 3–1).
- Scheduled matches have 5 empty map slots.
- Pre-scheduled (TBD) matches have no `matchData` at all.
- **Unknown until Dec 4:** the live status word, and whether the current map shows a live score (`matchGameResult` with no winner) or nothing until the map ends.

---

## 3. Feasibility

| Piece | Verdict | Why |
|---|---|---|
| Teams, standings, schedule, match pages | **High** | All in the official JSON. Mitigations in place: `JSONFinder`, cached last good copy, one central loader. |
| Live scores for the Live Activity | **Medium** | Built and tested with a replayed real match. **Unknown:** how often the match page updates during a live map. Test on Kickoff weekend. |
| Live Activity updating while the app is closed | **Needs a server** | iOS won't let an app poll the web in the background. Needs a server sending ActivityKit push notifications via APNs (paid Apple Developer Program). |
| Publishing on the App Store | **The hard part (legal)** | See §4. |

---

## 4. Legal & publishing (not legal advice)

What we found:
- **CDL Terms of Use** forbid using "any robot, spider, scraper, crawler or other automated means to access the CDL Service". They also claim the logos, data and "compilation" as CDL property.
- **BreakingPoint Terms:** "All use requires our written consent." Their footer "API" link goes to **contact@breakingpoint.gg**.
- **Apple App Review 5.2.1 (Intellectual Property)** and **5.2.2 (Third-Party Sites/Services)**: an app's use of third-party content must be permitted by that service's terms. Apple has rejected sports apps for team and league logos.
- **Precedent:** CODMunity says it reads the league's pages *with the league's permission*.

What this means:
1. **Scraping is fine for building and testing on your own phone.** Keep request volume low.
2. **A published app needs permission or a licensed source.** The data layer stays swappable.
3. **No team logos without permission.** `TeamLogos.useBundledLogos = false` makes the whole app (and the Live Activity) logo-free in one change.
4. **No "CDL" or "Call of Duty" in the app's name or icon**, plus an "Unofficial, not affiliated…" disclaimer.

---

## 5. Target architecture

```
                     (polls every ~20–30 s during live matches)
 CDL site / licensed API ──► OUR SERVER ──► our own clean JSON (teams, schedule, live/{matchId})
                                 │                    ▲
                                 │ APNs push          │ app fetches
                                 ▼                    │
                       Live Activity on iPhone ◄── iOS app
```

**Now:** the app does the server's job itself while it's open (`LiveActivityController.follow`). The pieces a server would need already exist as separate parts: `MatchDetailService` → `LiveActivityController.state(from:)` → `ContentState`. Moving them to a server is mostly relocation. Server language: Swift (Vapor, reuses these exact types) or JavaScript (Cloudflare Workers). Decide in Phase 4.

---

## 6. Features

**MVP (target: before Dec 4)**
- Teams ✅ · Standings ✅ · Schedule with status ✅
- Match detail: map-by-map results ✅ (Nov 4)
- Live Activity from a real match, updated while the app is open ✅ (Nov 4; untested on a real live match)

**v1.0 (during the season)**
- Server + push updates (Live Activity with the app closed).
- Favourite teams that auto-start a Live Activity when they play (push-to-start).
- Notifications: match starting, map results, final.
- Home/Lock Screen widgets: next match, standings.

**Later**
- Player stats (`matchStats`; BP if permitted) · Major brackets · stream links · Apple Watch / StandBy.

---

## 7. Roadmap

### Phase 1 — Data foundation ✅ (done Nov 4, ahead of the Nov 8 target)
- [x] 1.0 Audit (Oct 26)
- [x] 1.1 Teams scraper by ID (Oct 27; Devan wrote `toTeam()`)
- [x] 1.1b Team colors in team view; project reorganized (Oct 27)
- [x] 1.2 Standings → team IDs; BreakingPoint scraper deleted (Nov 1)
- [x] 1.3 Schedule scraper rewritten (Nov 2; Devan wrote `toMatch()`'s teams and scores)
- [x] 1.4 Offline cache (Nov 3; Devan wired the schedule)
- [x] 1.5 Shared stores via the environment (Nov 4; finished by Claude)

### Phase 2 — Real matches in the Live Activity (mostly done Nov 4)
- [x] 2.1 Match detail scraper + page
- [x] 2.2 New `ActivityAttributes` (abbreviation/color/logo per team; series + current-map state)
- [x] 2.3 Follow a match (30 s polling while open) + Replay a finished match
- [x] 2.4 Logo-free fallback badges, readable text, logo on/off switch
- [x] 2.5 Built (no errors), tested follow on a live BreakingPoint match and the replay in the Simulator, merged + pushed (Nov 9). Still to do: test on a real phone.
- [x] 2.6 Live Activity redesign (Nov 9): map score in the center, series dots, records, Saira fonts, three backgrounds. Simulator-tested with the replay.
  - **Caveat:** the status line says LIVE only when the current map has a score. If CDL match pages don't show a score during a map (unknown until Dec 4, see §2), it will say "UP NEXT" for the whole map. Fix then, e.g. with the match status.
- [ ] 2.7 **← NEXT.** Pick the background (blend / split / accent), take mock-up screenshots, write the pitch email (Phase 5)

### Phase 3 — Live test: Kickoff weekend (Dec 4–6)
- [ ] Save snapshots of schedule + match pages during live matches (real status words, live map scores, update speed)
- [ ] Confirm schedule entries gain team cards once the matchups are announced
- [ ] Adjust `MatchDetail.currentMap`, `MatchStatus` and the polling interval to match

### Phase 4 — Server + push (December → January)
- [ ] Join the Apple Developer Program; create an APNs key
- [ ] Server poller → APNs Live Activity pushes (broadcast channel per match)
- [ ] Favourite teams + push-to-start

### Phase 5 — Permissions & publishing (runs in parallel)
- [ ] Email BreakingPoint (contact@breakingpoint.gg, "API access")
- [ ] Contact the CDL/Activision about data use
- [ ] Look into licensed esports data providers
- [ ] Trademark-free app name; disclaimer; privacy policy

---

## 8. Open decisions
- **Logos:** logo-free permanently, or ask for permission? (Switch exists either way.)
- **Server language:** Swift (Vapor) or JavaScript (Cloudflare Workers)?
- **Minimum iOS version:** currently 26.2. Lowering to 18 would reach more people; broadcast Live Activity push needs iOS 18+ anyway.
- **Live Activity background:** blend (default), split or accent? One line: `LiveBackgroundStyle.current`.
- **What to build before Dec 4:** a snapshot recorder for Kickoff weekend, schedule auto-refresh while live, favourite teams, server groundwork, permission emails.
