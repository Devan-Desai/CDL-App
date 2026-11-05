//
//  MatchDetailService.swift
//  CDL App
//
//  Downloads one match page — callofdutyleague.com/en-us/match/{id} — and turns it
//  into a MatchDetail. Used by the match screen and by the Live Activity.
//
//  What the real pages look like (checked Nov 4, 2026):
//  • Finished match (e.g. 13100, LAT 3–1 MIA): team cards, status "COMPLETED", and one
//    entry per map slot. Played maps have a result; the unplayed map 5 has a name but no result.
//  • Teams known, not played yet (e.g. 12778): status "SCHEDULED", five empty map slots.
//  • Teams not decided yet (every 2027 Kickoff match right now): no match data at all.
//  • Live matches: not seen yet — check on Kickoff weekend (Dec 4).
//

import Foundation

enum MatchDetailService {

    enum DetailError: LocalizedError {
        case notAvailableYet
        var errorDescription: String? {
            "The CDL hasn't published details for this match yet — usually that means the teams aren't decided."
        }
    }

    static func fetch(matchId: Int) async throws -> MatchDetail {
        let json = try await CDLPageLoader.nextData(path: "match/\(matchId)")

        // blocks → cdlMatchDetail → matchData (found wherever it is, like the schedule)
        let blocks = try JSONFinder.findAll(key: "cdlMatchDetail", in: json)
        guard let block = blocks.first,
              let page = try JSONDecoder().decode(CDLMatchDetailBlock.self, from: block).matchData,
              let extended = page.matchExtended,
              let home = extended.homeTeamCard,
              let away = extended.awayTeamCard else {
            throw DetailError.notAvailableYet
        }

        let maps = (page.matchGamesExtended ?? [])
            .map { entry in
                MapResult(
                    id: entry.matchGame.id,
                    number: (entry.matchGame.number ?? 0) + 1,
                    mapName: entry.matchGame.map,
                    mode: entry.matchGame.mode.map { cleanMode($0) },
                    // "host" is always the home team (checked on 33 real maps from last season)
                    team1Score: entry.matchGameResult?.hostGameScore,
                    team2Score: entry.matchGameResult?.guestGameScore,
                    winnerTeamId: entry.matchGameResult?.winnerTeamId
                )
            }
            .sorted { $0.number < $1.number }

        var vodURL: URL? = nil
        if let link = extended.match.vodLink, !link.isEmpty {
            vodURL = URL(string: link)
        }

        return MatchDetail(
            id: extended.match.id,
            date: extended.match.playTime.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            status: extended.match.status ?? "UNKNOWN",
            team1: side(from: home),
            team2: side(from: away),
            maps: maps,
            seriesTeam1: extended.result?.homeTeamGamesWon,
            seriesTeam2: extended.result?.awayTeamGamesWon,
            vodURL: vodURL
        )
    }

    private static func side(from card: CDLMatchPage.Card) -> MatchDetail.Side {
        MatchDetail.Side(
            id: card.id,
            name: card.name,
            abbreviation: card.abbreviation ?? String(card.name.prefix(3)).uppercased(),
            colorHex: card.color
        )
    }

    /// "CDL Hardpoint" → "Hardpoint"
    private static func cleanMode(_ mode: String) -> String {
        mode.hasPrefix("CDL ") ? String(mode.dropFirst(4)) : mode
    }
}

// MARK: - Raw JSON from a CDL match page (only the fields we use)

struct CDLMatchDetailBlock: Decodable {
    let matchData: CDLMatchPage?        // missing on pages for matches without teams yet
}

struct CDLMatchPage: Decodable {
    let matchExtended: Extended?
    let matchGamesExtended: [GameEntry]?

    struct Extended: Decodable {
        let homeTeamCard: Card?
        let awayTeamCard: Card?
        let match: Info
        let result: SeriesScore?
    }
    struct Card: Decodable {
        let id: Int
        let name: String
        let abbreviation: String?
        let color: String?              // "#ff0000"
    }
    struct Info: Decodable {
        let id: Int
        let playTime: Int?
        let status: String?             // "SCHEDULED", "COMPLETED", …
        let vodLink: String?
    }
    struct SeriesScore: Decodable {
        let homeTeamGamesWon: Int?
        let awayTeamGamesWon: Int?
    }
    struct GameEntry: Decodable {
        let matchGame: Game
        let matchGameResult: GameResult?    // nil until the map has been played
    }
    struct Game: Decodable {
        let id: Int
        let number: Int?                // 0, 1, 2, … (map 1 is 0)
        let map: String?                // "Sake"
        let mode: String?               // "CDL Hardpoint"
    }
    struct GameResult: Decodable {
        let hostGameScore: Int?
        let guestGameScore: Int?
        let winnerTeamId: Int?
    }
}
