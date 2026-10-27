//
//  StandingsView.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-06.
//

import SwiftUI

struct StandingsView: View {
    @StateObject var rosterScraper = BreakingPointRosterScraper()   // LEGACY — replaced in step 1.2
    @StateObject var standingsScraper = StandingsScraperService()
    
    var mergedStandings: [TeamStanding] {
        standingsScraper.standings.map { standing in
            // Find matching roster from rosterScraper
            let roster = rosterScraper.standings.first(where: {
                $0.name == standing.name
            })?.roster ?? []
            
            return TeamStanding(
                rank: standing.rank,
                name: standing.name,
                logo: standing.logo,
                points: standing.points,
                matchWins: standing.matchWins,
                matchLosses: standing.matchLosses,
                mapWins: standing.mapWins,
                mapLosses: standing.mapLosses,
                roster: roster
            )
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Header Row
                HStack {
                    Text("RANK").frame(width: 40, alignment: .leading)
                    Text("TEAM").frame(maxWidth: .infinity, alignment: .leading)
                    Text("PTS").frame(width: 40)
                    Text("W-L").frame(width: 50)
                }
                .font(.caption.bold())
                .foregroundColor(.gray)
                .padding(.horizontal)
                
                Divider()
                
                if standingsScraper.standings.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                            .scaleEffect(1.5)
                        Text("Loading Live CDL Data...")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(mergedStandings) { team in
                        NavigationLink(destination: TeamDetailView(team: team)) {
                            HStack {
                                // Rank
                                Text("\(team.rank)")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .frame(width: 30)
                                
                                // Team Info
                                HStack {
                                    Image(team.logo)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                    
                                    Text(team.name)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Stats
                                Text("\(team.points)")
                                    .frame(width: 40)
                                    .fontWeight(.bold)
                                
                                Text("\(team.matchWins) - \(team.matchLosses)")
                                    .frame(width: 50)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        standingsScraper.fetchStandings()
                        rosterScraper.fetchStandings()
                    }
                }
            }
            .navigationTitle("CDL Standings")
            .onAppear {
                standingsScraper.fetchStandings()
                rosterScraper.fetchStandings()
            }
        }
    }
}

struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        StandingsView()
            .preferredColorScheme(.dark)
    }
}
