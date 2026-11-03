//
//  ScheduleScraperService.swift
//  CDL App
//
//  Scrapes https://www.callofdutyleague.com/en-us/schedule and turns it into [Match].
//  Rewritten Nov 1, 2026 for the 2027 site layout (step 1.3).
//

import Foundation
import Combine

class ScheduleScraperService: ObservableObject {
    @Published var matches: [Match] = []
    @Published var errorMessage: String?

    func fetchSchedule() async {
        if matches.isEmpty, let saved = DataCache.load([Match].self, from: "matches") {
            matches = saved
            print("📦 [Matches] Showing \(saved.count) saved matches while downloading fresh ones")
        }
        do {
            let json = try await CDLPageLoader.nextData(path: "schedule")

            // Grab every "cdlMatchCards" block, wherever it sits among the tabs.
            let blocks = try JSONFinder.findAll(key: "cdlMatchCards", in: json)

            var all: [Match] = []
            for block in blocks {
                let cards = try JSONDecoder().decode(CDLMatchCards.self, from: block)
                all += cards.allMatches
            }

            // The same match can show up in more than one block — keep each ID once.
            var seen = Set<Int>()
            matches = all
                .filter { seen.insert($0.id).inserted }
                .sorted { $0.date < $1.date }

            errorMessage = blocks.isEmpty ? "Couldn't find any matches on the CDL schedule page." : nil
            DataCache.save(matches, as: "matches")

            print("✅ [Schedule] Loaded \(matches.count) matches from \(blocks.count) blocks")
            for match in matches.prefix(3) {
                print("   #\(match.id) \(match.shortDisplayDate) [\(match.status.rawValue)] \(match.team1Name) vs \(match.team2Name)")
            }
        } catch {
            errorMessage = matches.isEmpty
                ? "Couldn't load the schedule: \(error.localizedDescription)"
                : "Couldn't refresh — showing saved schedule."
            print("❌ [Schedule] \(error)")
        }
    }

    // MARK: Matches for one team — matched by CDL team ID, never by name

    func matchesForTeam(_ teamId: Int) -> [Match] {
        matches.filter { $0.team1Id == teamId || $0.team2Id == teamId }
    }

    /// Newest first
    func completedMatchesForTeam(_ teamId: Int) -> [Match] {
        matchesForTeam(teamId)
            .filter { $0.isCompleted }
            .sorted { $0.date > $1.date }
    }

    /// Soonest first
    func upcomingMatchesForTeam(_ teamId: Int) -> [Match] {
        matchesForTeam(teamId)
            .filter { !$0.isCompleted }
            .sorted { $0.date < $1.date }
    }
}

// MARK: - Raw JSON from the CDL schedule page
//
// Each "cdlMatchCards" block sorts its matches into four lists by state.
// Which list a match is in tells us its status — more reliable than guessing
// the website's status words.
//
//   { "liveMatches": [], "preScheduledMatches": [ … ], "upcomingMatches": [], "finalMatches": [], "count": 5 }

struct CDLMatchCards: Decodable {
    let liveMatches: [CDLScheduleEntry]?
    let preScheduledMatches: [CDLScheduleEntry]?
    let upcomingMatches: [CDLScheduleEntry]?
    let finalMatches: [CDLScheduleEntry]?

    /// Every match in this block, labelled with the list it came from.
    var allMatches: [Match] {
        var result: [Match] = []
        result += (preScheduledMatches ?? []).map { $0.toMatch(status: .preScheduled) }
        result += (upcomingMatches ?? []).map { $0.toMatch(status: .upcoming) }
        result += (liveMatches ?? []).map { $0.toMatch(status: .live) }
        result += (finalMatches ?? []).map { $0.toMatch(status: .final) }
        return result
    }
}

/// One match in a list. Right now (Nov 2026) every Kickoff match looks like:
///   { "match": { "id": 13467, "playTime": 1796414400, "status": "PRESCHEDULED" }, ... }
/// Once teams are decided, it also gets team cards and (after it's played) a result —
/// same shape as last season's matches:
///   "homeTeamCard": { "id": 69, "name": "Los Angeles Thieves", "abbreviation": "LAT", ... },
///   "awayTeamCard": { "id": 9,  "name": "Miami Heretics", ... },
///   "result":       { "homeTeamGamesWon": 3, "awayTeamGamesWon": 1, "winnerTeamId": 69 }
struct CDLScheduleEntry: Decodable {
    let match: Info
    let homeTeamCard: TeamCardRef?   // nil until the teams are decided
    let awayTeamCard: TeamCardRef?
    let result: Score?               // nil until there's a score

    struct Info: Decodable {
        let id: Int
        let playTime: Int            // seconds since Jan 1 1970 (a "Unix timestamp")
        let status: String           // "PRESCHEDULED", "COMPLETED", …
    }
    struct TeamCardRef: Decodable {
        let id: Int
        let name: String
    }
    struct Score: Decodable {
        let homeTeamGamesWon: Int?
        let awayTeamGamesWon: Int?
    }
}

// MARK: - Raw → clean conversion

extension CDLScheduleEntry {
    func toMatch(status: MatchStatus) -> Match {
        let team1Id: Int? = homeTeamCard?.id
        let team1Name = homeTeamCard?.name ?? "TBD"
        let team1Score: Int? = result?.homeTeamGamesWon

        let team2Id: Int? = awayTeamCard?.id
        let team2Name = awayTeamCard?.name ?? "TBD"
        let team2Score: Int? = result?.awayTeamGamesWon

        return Match(
            id: match.id,
            date: Date(timeIntervalSince1970: TimeInterval(match.playTime)),
            status: status,
            team1Id: team1Id,
            team1Name: team1Name,
            team1Logo: TeamTheme.theme(for: team1Name).logo,
            team1Score: team1Score,
            team2Id: team2Id,
            team2Name: team2Name,
            team2Logo: TeamTheme.theme(for: team2Name).logo,
            team2Score: team2Score
        )
    }
}
