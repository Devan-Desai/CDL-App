//
//  BreakingPointMatchService.swift
//  CDL App
//
//  TEST ONLY: lets us try the Live Activity on a real live event before Dec 4.
//  The Monster Energy Launch Invitational (Nov 6–8, 2026) isn't on the CDL site, so
//  this reads BreakingPoint's public pages and turns them into the SAME MatchDetail
//  the CDL scraper produces. Everything after this file works unchanged.
//
//  `#if DEBUG` means this file doesn't exist in a Release build. BreakingPoint's terms
//  require written consent for use (docs/ROADMAP.md §4), so it must never ship without it.
//
//  What the real pages look like (checked Nov 6, 2026, during the event):
//  • status is "upcoming", "live" or "complete"
//  • `games` lists finished maps with their scores
//  • a query called fetchGameBans lists the planned maps once a match has started
//

#if DEBUG
import Foundation

enum BreakingPointMatchService {

    static let monsterEventId = 1244

    // MARK: One match → MatchDetail

    static func fetch(matchId: Int) async throws -> MatchDetail {
        let url = URL(string: "https://breakingpoint.gg/match/\(matchId)")!
        return try matchDetail(fromNextData: try await CDLPageLoader.nextData(url: url))
    }

    /// Separate from fetch so it can be tested on a saved page, without the network.
    static func matchDetail(fromNextData json: Data) throws -> MatchDetail {
        guard let block = try JSONFinder.findAll(key: "initialMatchState", in: json).first else {
            throw CDLPageLoader.LoadError.noNextData
        }
        let match = try decoder.decode(BPMatch.self, from: block)
        guard let team1 = match.team1, let team2 = match.team2 else {
            throw MatchDetailService.DetailError.notAvailableYet
        }

        return MatchDetail(
            id: match.id,
            date: date(from: match.datetime),
            status: appStatus(from: match.status),
            team1: side(from: team1),
            team2: side(from: team2),
            maps: try mapResults(for: match, nextData: json),
            seriesTeam1: match.team1Score,
            seriesTeam2: match.team2Score,
            vodURL: nil
        )
    }

    /// Finished maps with their scores, plus the planned maps not finished yet (no score).
    /// That makes MatchDetail.currentMap work the same way as it does for CDL pages.
    private static func mapResults(for match: BPMatch, nextData: Data) throws -> [MapResult] {
        var byNumber: [Int: MapResult] = [:]

        // Before the match starts there is no "current map", so skip the planned maps.
        if match.status != "upcoming" {
            let plan = try plannedMaps(in: nextData)
            for slot in plan.slots {
                byNumber[slot.mapNumber] = MapResult(
                    id: slot.mapNumber,
                    number: slot.mapNumber,
                    mapName: plan.mapNames[slot.mapId],
                    mode: plan.modeNames[slot.modeId],
                    team1Score: nil,
                    team2Score: nil,
                    winnerTeamId: nil
                )
            }
        }

        for game in match.games ?? [] {
            byNumber[game.gameNum] = MapResult(
                id: game.gameNum,
                number: game.gameNum,
                mapName: game.maps?.name,
                mode: game.modes?.name,
                team1Score: game.team1Score,
                team2Score: game.team2Score,
                winnerTeamId: game.winnerId.map { appTeamId($0) }
            )
        }
        return byNumber.values.sorted { $0.number < $1.number }
    }

    /// The page also embeds the answers to the site's own data requests ("queries").
    /// fetchGameBans gives map/mode IDs per map number; the other two turn IDs into names.
    private static func plannedMaps(in json: Data) throws
        -> (slots: [BPMapSlot], mapNames: [Int: String], modeNames: [Int: String]) {
        guard let block = try JSONFinder.findAll(key: "queries", in: json).first,
              let queries = try JSONSerialization.jsonObject(with: block) as? [[String: Any]] else {
            return ([], [:], [:])
        }

        func answer(to name: String) -> Any? {
            let query = queries.first { query in
                let key = query["queryKey"] as? [Any]
                return (key?.first as? [String])?.last == name
            }
            return (query?["state"] as? [String: Any])?["data"]
        }
        func decodeList<T: Decodable>(_ value: Any?) throws -> [T] {
            guard let value else { return [] }
            let data = try JSONSerialization.data(withJSONObject: value)
            return try decoder.decode([T].self, from: data)
        }

        let slots: [BPMapSlot] = try decodeList(answer(to: "fetchGameBans"))
        let maps: [BPNamed] = try decodeList(answer(to: "fetchMapsForEvent"))
        // fetchModes wraps its list one level deeper: { "data": [...] }
        let modes: [BPNamed] = try decodeList((answer(to: "fetchModes") as? [String: Any])?["data"])

        // The maps list repeats a map once per mode, so keep just one name per ID.
        return (slots,
                Dictionary(maps.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first }),
                Dictionary(modes.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first }))
    }

    // MARK: One event → the matches you can follow

    struct EventMatch: Identifiable {
        let id: Int
        let title: String   // "TX vs MIN"
        let round: String   // "GP A WQR"
        let status: String  // "upcoming" or "live"
        let date: Date?
    }

    /// Live and upcoming matches whose teams are known, soonest first.
    static func fetchEventMatches(eventId: Int) async throws -> [EventMatch] {
        let url = URL(string: "https://breakingpoint.gg/events/\(eventId)")!
        return try eventMatches(fromNextData: try await CDLPageLoader.nextData(url: url))
    }

    static func eventMatches(fromNextData json: Data) throws -> [EventMatch] {
        guard let block = try JSONFinder.findAll(key: "matches", in: json).first else {
            throw CDLPageLoader.LoadError.noNextData
        }
        return try decoder.decode([BPMatch].self, from: block)
            .filter { $0.status == "live" || $0.status == "upcoming" }
            .compactMap { match -> EventMatch? in
                guard let team1 = match.team1, let team2 = match.team2 else { return nil }
                return EventMatch(id: match.id,
                                  title: "\(team1.nameShort ?? team1.name) vs \(team2.nameShort ?? team2.name)",
                                  round: match.round?.nameShort ?? "",
                                  status: match.status,
                                  date: date(from: match.datetime))
            }
            .sorted {
                // Live matches first, then by start time.
                if ($0.status == "live") != ($1.status == "live") { return $0.status == "live" }
                return ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture)
            }
    }

    // MARK: Translating BreakingPoint's words and IDs into ours

    /// BreakingPoint has its own team IDs, and they clash with the CDL's: 11 is G2 there but
    /// Gentle Mates here. Without this table the Lock Screen shows the wrong logo and color.
    private static let cdlTeamIdByBPId: [Int: Int] = [
        1: 7,        // FaZe Vegas
        2: 69,       // Los Angeles Thieves
        3: 16,       // Vancouver Surge
        4: 6,        // OpTic Texas
        11: 12,      // G2 Minnesota
        12: 17,      // Toronto KOI
        26: 10,      // Carolina Royal Ravens
        27: 9,       // Miami Heretics
        62: 15,      // Riyadh Falcons
        63: 13,      // Cloud9 New York
        743: 11,     // Paris Gentle Mates
        1176: 138,   // M80 Boston
    ]

    /// Teams outside the CDL (Huntsmen, OMiT, Stallions, Bush) get a negative ID, which can
    /// never match a real CDL team. They appear as colored badges using BreakingPoint's colors.
    private static func appTeamId(_ bpId: Int) -> Int {
        cdlTeamIdByBPId[bpId] ?? -bpId
    }

    /// MatchDetail.isFinal looks for the CDL's word, "COMPLETED".
    private static func appStatus(from status: String) -> String {
        switch status {
        case "complete": return "COMPLETED"
        case "upcoming": return "SCHEDULED"
        default:         return status.uppercased()   // "live" → "LIVE"
        }
    }

    private static func side(from team: BPTeam) -> MatchDetail.Side {
        MatchDetail.Side(id: appTeamId(team.id),
                         name: team.name,
                         abbreviation: team.nameShort ?? String(team.name.prefix(3)).uppercased(),
                         colorHex: team.colorHex)
    }

    private static func date(from text: String?) -> Date? {
        text.flatMap { ISO8601DateFormatter().date(from: $0) }
    }

    /// convertFromSnakeCase turns the site's team_1_score into our team1Score.
    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

// MARK: - Raw JSON from BreakingPoint (only the fields we use)

private struct BPMatch: Decodable {
    let id: Int
    let datetime: String?
    let status: String          // "upcoming", "live", "complete"
    let team1Score: Int?        // maps won in the series
    let team2Score: Int?
    let team1: BPTeam?          // missing until the teams are decided
    let team2: BPTeam?
    let round: BPRound?
    let games: [BPGame]?        // only on match pages, not on the event page
}

private struct BPTeam: Decodable {
    let id: Int
    let name: String            // "OpTic Texas"
    let nameShort: String?      // "TX"
    let colorHex: String?       // "#93C852"
}

private struct BPRound: Decodable {
    let nameShort: String?      // "GP A WQR"
}

private struct BPGame: Decodable {
    let gameNum: Int            // 1, 2, 3… (unlike the CDL, which counts from 0)
    let maps: BPName?
    let modes: BPName?
    let team1Score: Int?
    let team2Score: Int?
    let winnerId: Int?
}

private struct BPName: Decodable {
    let name: String
}

private struct BPMapSlot: Decodable {
    let mapNumber: Int
    let mapId: Int
    let modeId: Int
}

private struct BPNamed: Decodable {
    let id: Int
    let name: String
}
#endif
