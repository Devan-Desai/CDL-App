//
//  StandingsScraperService.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-15.
//


//
//  StandingsScraperService.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-15.
//

import Foundation
import SwiftSoup
import Combine

class StandingsScraperService: ObservableObject {
    @Published var standings: [TeamStanding] = []

    /// CDL team ID → series record in the latest Major that has results, e.g. [6: "3–1"].
    /// Empty until a Major has been played (checked Nov 9: the Major tabs exist but are empty).
    @Published var majorRecords: [Int: String] = [:]

    /// The record to show next to a team: its Major record if the site has one, else its
    /// season record (series W–L), else nil.
    func record(forTeamId id: Int) -> String? {
        if let major = majorRecords[id] { return major }
        guard let row = standings.first(where: { $0.teamId == id }) else { return nil }
        return "\(row.matchWins)–\(row.matchLosses)"
    }

    func fetchStandings() {
        // Show the standings saved last time while we download (same idea as fetchTeams()).
        if standings.isEmpty, let saved = DataCache.load([TeamStanding].self, from: "standings") {
            standings = saved
            print("📦 [Standings] Showing \(saved.count) saved rows while downloading fresh ones")
        }

        guard let url = URL(string: "https://callofdutyleague.com/en-us/standings") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let html = String(data: data, encoding: .utf8) else { return }

            do {
                let doc: Document = try SwiftSoup.parse(html)
                guard let scriptTag = try doc.select("script#__NEXT_DATA__").first() else { return }
                
                let jsonData = scriptTag.data().data(using: .utf8)!
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let decoded = try decoder.decode(CDLStandingsResponse.self, from: jsonData)
                
                // Navigate to the standings array
                guard let blocks = decoded.props.pageProps.blocks.first(where: { $0.cdlContainerBlockList != nil }),
                      let items = blocks.cdlContainerBlockList?.items.first(where: { $0.default == true }),
                      let tabBlocks = items.blocks,
                      let tabsBlock = tabBlocks.first(where: { $0.tabs != nil }),
                      let tabs = tabsBlock.tabs?.tabs.first(where: { $0.openDefault == true }),
                      let standingsBlocks = tabs.blocks,
                      let standingsBlock = standingsBlocks.first(where: { $0.cdlProStandings != nil }),
                      let standingsData = standingsBlock.cdlProStandings?.standings else {
                    print("❌ Could not navigate to standings data")
                    return
                }

                // The same tab bar also has one tab per Major ("MAJOR I", "TORONTO KOI MAJOR III", …).
                // Use the last Major where at least one series has been played.
                let majorTabs = (tabsBlock.tabs?.tabs ?? []).filter { ($0.title ?? "").uppercased().contains("MAJOR") }
                let latestMajor = majorTabs
                    .compactMap { tab in tab.blocks?.first(where: { $0.cdlProStandings != nil })?.cdlProStandings?.standings }
                    .last { rows in rows.contains { $0.standing.matchWin + $0.standing.matchLoss > 0 } }
                var majorRecords: [Int: String] = [:]
                for entry in latestMajor ?? [] {
                    majorRecords[entry.teamCard.id] = "\(entry.standing.matchWin)–\(entry.standing.matchLoss)"
                }

                DispatchQueue.main.async {
                    self.majorRecords = majorRecords
                    self.standings = standingsData.map { entry in
                        return TeamStanding(
                            rank: entry.standing.rank,
                            name: entry.teamCard.name,
                            points: entry.standing.cdlPoints,
                            matchWins: entry.standing.matchWin,
                            matchLosses: entry.standing.matchLoss,
                            mapWins: entry.standing.gameWin,
                            mapLosses: entry.standing.gameLoss,
                            roster: [], // Roster data not in standings endpoint
                            teamId: entry.teamCard.id,
                            colorHex: nil  // the standings page has no colors; StandingsView fills this in
                        )
                    }
                    DataCache.save(self.standings, as: "standings")   // save the fresh copy for next time
                    print("✅ Loaded \(self.standings.count) teams with standings data")
                }
            } catch {
                print("❌ Decoding error: \(error)")
            }
        }.resume()
    }
}

// MARK: - CDL Standings Response Models
struct CDLStandingsResponse: Codable {
    let props: CDLProps
}

struct CDLProps: Codable {
    let pageProps: CDLPageProps
}

struct CDLPageProps: Codable {
    let blocks: [CDLBlock]
}

struct CDLBlock: Codable {
    let cdlContainerBlockList: CDLContainerBlockList?
    let tabs: CDLTabs?
    let cdlProStandings: CDLProStandings?
}

struct CDLContainerBlockList: Codable {
    let items: [CDLContainerItem]
}

struct CDLContainerItem: Codable {
    let `default`: Bool
    let blocks: [CDLBlock]?
}

struct CDLTabs: Codable {
    let tabs: [CDLTab]
}

struct CDLTab: Codable {
    let title: String?          // "Regular Season", "MAJOR I", …
    let openDefault: Bool
    let blocks: [CDLBlock]?
}

struct CDLProStandings: Codable {
    let standings: [CDLStandingEntry]
}

struct CDLStandingEntry: Codable {
    let standing: Standing
    let teamCard: TeamCard
}

struct Standing: Codable {
    let rank: Int
    let cdlPoints: Int
    let matchWin: Int
    let matchLoss: Int
    let gameWin: Int
    let gameLoss: Int
}

struct TeamCard: Codable {
    let id: Int
    let name: String
    let abbreviation: String
}
