//
//  ScraperService.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-08.
//

import Foundation
import SwiftSoup
import Combine

class ScraperService: ObservableObject {
    @Published var standings: [TeamStanding] = []
    
    func fetchStandings() {
        guard let url = URL(string: "https://www.breakingpoint.gg/cdl/teams-and-players") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let html = String(data: data, encoding: .utf8) else { return }

            do {
                let doc: Document = try SwiftSoup.parse(html)
                guard let scriptTag = try doc.select("script#__NEXT_DATA__").first() else { return }
                
                let jsonData = scriptTag.data().data(using: .utf8)!
                
                let decoder = JSONDecoder()
                // Handles snake_case (like logo_main) automatically
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let decoded = try decoder.decode(BPTeamsResponse.self, from: jsonData)
                let bpTeams = decoded.props.pageProps.teams
                
                DispatchQueue.main.async {
                    self.standings = bpTeams.enumerated().map { (index, team) in
                        // Using the 'name' key found in your debug test
                        let name = team.name ?? "Unknown Team"
                        let theme = TeamTheme.theme(for: name)
                        
                        // Using the 'tag' key found for players (e.g., Cammy, Snoopy)
                        let playerList = team.players?.compactMap { $0.tag } ?? []
                        
                        print("✅ Scraped: \(name) | Roster: \(playerList.joined(separator: ", "))")
                        
                        return TeamStanding(
                            rank: index + 1,
                            name: name,
                            logo: theme.logo,
                            points: 0,
                            matchWins: 0,
                            matchLosses: 0,
                            mapWins: 0,
                            mapLosses: 0,
                            roster: playerList
                        )
                    }
                    print("--- [SCRAPER] SUCCESS! Loaded \(self.standings.count) Teams ---")
                }
            } catch {
                print("--- [SCRAPER] DECODING ERROR: \(error) ---")
            }
        }.resume()
    }
}

// MARK: - Updated Models to match BreakingPoint's Database
struct BPTeamsResponse: Codable { let props: BPProps }
struct BPProps: Codable { let pageProps: BPPageProps }
struct BPPageProps: Codable { let teams: [BPTeamEntry] }

struct BPTeamEntry: Codable {
    let name: String?       // Matches "name": "Boston Breach"
    let players: [BPPlayerEntry]?
}

struct BPPlayerEntry: Codable {
    let tag: String?        // Matches "tag": "Cammy"
}
