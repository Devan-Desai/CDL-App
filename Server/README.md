# CDL server (Phase 4 groundwork)

A small web server, written in Swift with [Vapor](https://vapor.codes). It reads CDL match pages and
serves them as our own clean JSON. For now it runs only on your Mac. Later it will send the push
updates that keep the Live Activity going while the app is closed (`docs/ROADMAP.md` §5, Phase 4).

## Run it

```sh
cd Server
swift run                 # first time: downloads Vapor and builds (a few minutes)
```

Then open in a browser:

| Address | What you get |
|---|---|
| http://127.0.0.1:8080/ | "CDL server is running" |
| http://127.0.0.1:8080/matches/13100 | The match as our own JSON (`MatchJSON.swift`) |
| http://127.0.0.1:8080/matches/13100/live | Exactly the Live Activity's `ContentState` (what a push will carry) |

Stop it with Ctrl-C. You can also open `Server/Package.swift` in Xcode and press Run.

**From your iPhone** (same Wi-Fi): `swift run CDLServer serve --hostname 0.0.0.0`, then use your Mac's
address, e.g. `http://192.168.1.20:8080/...` (System Settings → Wi-Fi → Details → IP address).
Only do this on a home network you trust.

## How it fits together

```
Sources/CDLServer/
  entrypoint.swift   start-up (Vapor's standard opening)
  configure.swift    the addresses (routes)
  MatchStore.swift   keeps the latest copy of each match; the poller; decides when to download
  MatchJSON.swift    our own JSON format for a match
  Shared/            LINKS to the app's files — the server compiles the app's own code:
                     CDLPageLoader, JSONFinder, MatchDetailService, MatchDetail,
                     CDLAttributes, ContentState+MatchDetail
```

Because `Shared/` holds links (not copies), a fix to the match page reader in the app fixes the server too.
Those files must stay Foundation-only (no SwiftUI/ActivityKit/UIKit), or the server won't build.

## Being gentle with the CDL site

- One download per match per minute at most, however many phones ask (finished matches: once an hour).
- The poller only refreshes matches someone asked about in the last 10 minutes.
- The CDL's Terms forbid automated access: fine for personal testing, **not** for a public server
  without permission (`docs/ROADMAP.md` §4).
