//
//  CDLAttributes.swift
//  CDL App (Shared: app, widget AND the server in Server/)
//
//  The data a match Live Activity shows. Moved out of CDLWidgetsLiveActivity.swift
//  (Nov 12) so the server can use the very same types: what it sends in a push
//  update later has to match `ContentState` exactly.
//
//  Only Foundation here — no SwiftUI or ActivityKit — because the server runs on a
//  Mac/Linux, where those don't exist. The ActivityKit part is added at the bottom,
//  only when building for iPhone.
//

import Foundation

// MARK: - The data

struct CDLAttributes: Codable, Hashable {

    /// The part that changes during the match — the app sends a new one on every update.
    public struct ContentState: Codable, Hashable {
        var team1Maps: Int          // series score: maps won
        var team2Maps: Int
        var mapNumber: Int          // the map this is about (1, 2, …): live, up next, or the last one when final
        var mapName: String         // "Colossus" ("" if not known yet)
        var modeName: String        // "Hardpoint"
        var shortMode: String       // "HP"
        var team1MapScore: Int?     // score on that map, e.g. 140 — nil = no score yet (map not started)
        var team2MapScore: Int?
        var mapsToWin: Int          // first to 3 (Bo5), 4 (Bo7) or 5 (Bo9)
        var isFinal: Bool
    }

    /// One team — fixed for the whole match.
    struct Side: Codable, Hashable {
        var abbreviation: String    // "LAT"
        var colorHex: String        // "#ED2224"
        var logoAsset: String?      // logo image in Assets, or nil → colored badge
        var record: String?         // "3–1" this Major (or this season); nil = don't show
    }

    var matchId: Int
    var team1: Side                 // home team (left)
    var team2: Side                 // away team (right)
}

extension CDLAttributes.ContentState {

    /// A map is live when it has a score and the match isn't over.
    /// A map without a score (yet) counts as "up next".
    var isMapLive: Bool {
        !isFinal && team1MapScore != nil && team2MapScore != nil
    }

    /// The small line at the top: "LIVE · MAP 4", "UP NEXT · MAP 5" or "FINAL".
    var statusLine: String {
        if isFinal { return "FINAL" }
        let map = "MAP \(max(mapNumber, 1))"
        return isMapLive ? "LIVE · \(map)" : "UP NEXT · \(map)"
    }

    /// The big numbers: the live map's score; the series score between maps and at the end.
    var bigScore: (Int, Int) {
        if isMapLive, let a = team1MapScore, let b = team2MapScore {
            return (a, b)
        }
        return (team1Maps, team2Maps)
    }

    /// The line under the score: "HARDPOINT · COLOSSUS", or "MAP 4 · HARDPOINT · 250–197" when final.
    var detailLine: String {
        if isFinal {
            var parts = ["MAP \(mapNumber)"]
            if !modeName.isEmpty { parts.append(modeName.uppercased()) }
            if let a = team1MapScore, let b = team2MapScore { parts.append("\(a)–\(b)") }
            return parts.joined(separator: " · ")
        }
        return [modeName, mapName]
            .filter { !$0.isEmpty }
            .map { $0.uppercased() }
            .joined(separator: " · ")
    }
}

// MARK: - iPhone only: make it a Live Activity

// `#if` decides at BUILD time which code exists: on the iPhone this adds the
// ActivityAttributes conformance; on the server this part simply isn't compiled.
#if canImport(ActivityKit) && os(iOS)
import ActivityKit

extension CDLAttributes: ActivityAttributes {}
#endif
