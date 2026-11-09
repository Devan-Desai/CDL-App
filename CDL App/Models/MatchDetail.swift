//
//  MatchDetail.swift
//  CDL App
//
//  Everything a CDL match page knows about one match: the two teams, the series
//  score, and the map-by-map results. (A `Match` from the schedule is the short
//  version; this is the full one.)
//

import Foundation

struct MatchDetail {

    struct Side {
        let id: Int               // CDL team ID
        let name: String          // "Los Angeles Thieves"
        let abbreviation: String  // "LAT"
        let colorHex: String?     // "#ff0000"
    }

    let id: Int
    let date: Date?
    let status: String            // the site's own word: "SCHEDULED", "COMPLETED", …
    let team1: Side               // home team (shown on the left)
    let team2: Side               // away team (shown on the right)
    let maps: [MapResult]         // every map slot the site lists, in order — some may be unplayed
    let seriesTeam1: Int?         // the site's own series score (backup if maps are missing)
    let seriesTeam2: Int?
    let vodURL: URL?

    var isFinal: Bool { status == "COMPLETED" }

    /// Maps that have a winner, in order.
    var playedMaps: [MapResult] { maps.filter { $0.winnerTeamId != nil } }

    /// The map being played right now: the first one that has a name but no winner yet.
    /// Only while the match isn't over — in a finished 3–1, map 5 is listed with no winner too.
    var currentMap: MapResult? {
        guard !isFinal else { return nil }
        return maps.first { $0.mapName != nil && $0.winnerTeamId == nil }
    }

    /// Series score: maps won by each team.
    var team1MapsWon: Int {
        playedMaps.isEmpty ? (seriesTeam1 ?? 0) : playedMaps.filter { $0.winnerTeamId == team1.id }.count
    }
    var team2MapsWon: Int {
        playedMaps.isEmpty ? (seriesTeam2 ?? 0) : playedMaps.filter { $0.winnerTeamId == team2.id }.count
    }

    /// Maps a team needs to win the series: the match page lists one slot per map,
    /// so 5 slots = best of 5 = first to 3. Bo7 → 4, Bo9 → 5. No slots → assume Bo5.
    var mapsToWin: Int {
        maps.isEmpty ? 3 : (maps.count + 1) / 2
    }

    /// Maps to show: the ones played, plus the current one during a live match.
    var visibleMaps: [MapResult] {
        maps.filter { $0.winnerTeamId != nil || $0.id == currentMap?.id }
    }
}

/// One map of a match.
struct MapResult: Identifiable {
    let id: Int
    let number: Int          // 1–5 (the site counts from 0; we add 1)
    let mapName: String?     // "Sake" — nil while the map isn't decided
    let mode: String?        // "Hardpoint", "Search & Destroy", "Overload"
    let team1Score: Int?     // e.g. 250 — nil before the map starts
    let team2Score: Int?     // e.g. 137
    let winnerTeamId: Int?   // nil until the map is over

    /// Short mode names for small spaces like the Dynamic Island.
    var shortMode: String {
        switch mode ?? "" {
        case "Hardpoint": return "HP"
        case "Search & Destroy": return "SND"
        case "Overload": return "OVL"
        case "Hijack": return "HJK"
        case "Control": return "CTL"
        default: return mode ?? ""
        }
    }
}
