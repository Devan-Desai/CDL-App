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
                
                // Use a decoder that handles the website's snake_case (e.g. team_name) automatically
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let decoded = try decoder.decode(BPTeamsResponse.self, from: jsonData)
                let bpTeams = decoded.props.pageProps.teams
                
                DispatchQueue.main.async {
                    self.standings = bpTeams.enumerated().map { (index, team) in
                        // We use the 'teamName' property which the decoder converted from 'team_name'
                        let name = team.teamName ?? "Unknown Team"
                        let theme = TeamTheme.theme(for: name)
                        
                        // Map the player names
                        let playerList = team.players?.map { $0.playerName ?? "TBD" } ?? []
                        
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
                    print("--- [SCRAPER] SUCCESS! Loaded \(self.standings.count) Teams & Rosters ---")
                }
            } catch {
                print("--- [SCRAPER] FINAL ERROR: \(error) ---")
            }
        }.resume()
    }
}

// MARK: - Refined Models
struct BPTeamsResponse: Codable { let props: BPProps }
struct BPProps: Codable { let pageProps: BPPageProps }
struct BPPageProps: Codable { let teams: [BPTeamEntry] }

struct BPTeamEntry: Codable {
    // These use Optional (?) so the app won't crash if one is missing
    let teamName: String?
    let players: [BPPlayerEntry]?
}

struct BPPlayerEntry: Codable {
    let playerName: String?
}
