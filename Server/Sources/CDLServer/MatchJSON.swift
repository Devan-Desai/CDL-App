//
//  MatchJSON.swift
//  CDLServer
//
//  The server's OWN clean format for a match (GET /matches/{id}). This is the point of
//  having a server: phones read this simple JSON from us, and only the server has to
//  know how the CDL website is put together. If the site changes, we fix the server
//  once instead of waiting for an App Store update.
//

import Vapor

struct MatchJSON: Content {

    struct Team: Content {
        let id: Int                 // CDL team ID (house rule 1: match teams by ID)
        let name: String
        let abbreviation: String
        let colorHex: String?
    }

    struct Map: Content {
        let number: Int
        let mapName: String?
        let mode: String?
        let team1Score: Int?
        let team2Score: Int?
        let winnerTeamId: Int?
        let isCurrent: Bool         // the map being played right now
    }

    /// How fresh our copy is — useful while we learn how the CDL site behaves.
    struct Source: Content {
        let downloadedAt: Date
        let cdnAgeSeconds: Int?     // how old the site's own copy already was
        let cdnCache: String?
    }

    let id: Int
    let status: String              // the site's word: "SCHEDULED", "COMPLETED", …
    let isFinal: Bool
    let startTime: Date?
    let team1: Team                 // home (left)
    let team2: Team                 // away (right)
    let team1MapsWon: Int
    let team2MapsWon: Int
    let mapsToWin: Int
    let maps: [Map]                 // played maps + the current one
    let vodURL: URL?
    let source: Source

    init(entry: MatchStore.Entry) {
        let d = entry.detail
        id = d.id
        status = d.status
        isFinal = d.isFinal
        startTime = d.date
        team1 = Team(id: d.team1.id, name: d.team1.name, abbreviation: d.team1.abbreviation, colorHex: d.team1.colorHex)
        team2 = Team(id: d.team2.id, name: d.team2.name, abbreviation: d.team2.abbreviation, colorHex: d.team2.colorHex)
        team1MapsWon = d.team1MapsWon
        team2MapsWon = d.team2MapsWon
        mapsToWin = d.mapsToWin
        maps = d.visibleMaps.map { m in
            Map(number: m.number, mapName: m.mapName, mode: m.mode,
                team1Score: m.team1Score, team2Score: m.team2Score,
                winnerTeamId: m.winnerTeamId, isCurrent: m.id == d.currentMap?.id)
        }
        vodURL = d.vodURL
        source = Source(downloadedAt: entry.page.downloadedAt,
                        cdnAgeSeconds: entry.page.ageSeconds,
                        cdnCache: entry.page.cacheStatus)
    }
}
