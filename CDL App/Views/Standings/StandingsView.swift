//
//  StandingsView.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-06.
//

import SwiftUI

struct StandingsView: View {
    // The app's shared copies (created once in CDL_AppApp):
    @EnvironmentObject var teamsScraper: TeamsScraperService          // rosters + colors (CDL teams page)
    @EnvironmentObject var standingsScraper: StandingsScraperService  // rank, points, W-L (CDL standings page)

    /// Each standings row + its team's roster and color, matched by team ID.
    var mergedStandings: [TeamStanding] {
        standingsScraper.standings.map { standing in
            // nil if the teams page hasn't finished loading yet
            let team = teamsScraper.teamsByID[standing.teamId]

            return TeamStanding(
                rank: standing.rank,
                name: standing.name,
                points: standing.points,
                matchWins: standing.matchWins,
                matchLosses: standing.matchLosses,
                mapWins: standing.mapWins,
                mapLosses: standing.mapLosses,
                roster: team?.roster.map(\.alias) ?? [],
                teamId: standing.teamId,
                colorHex: team?.primaryColorHex
            )
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if standingsScraper.standings.isEmpty {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                            .scaleEffect(1.5)
                        Text("Loading Live CDL Data...")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        Section {
                            ForEach(mergedStandings) { team in
                                NavigationLink(destination: TeamDetailView(team: team)) {
                                    HStack {
                                        // Rank
                                        Text("\(team.rank)")
                                            .font(.system(.body, design: .monospaced))
                                            .fontWeight(.bold)
                                            .frame(width: 30)
                                
                                        // Team Info
                                        HStack {
                                            TeamLogo(teamId: team.teamId, size: 30)
                                    
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
                        } header: {
                            columnHeaders
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        standingsScraper.fetchStandings()
                        await teamsScraper.fetchTeams()
                    }
                }
            }
            .navigationTitle("CDL Standings")
        }
    }

    /// The RANK / TEAM / PTS / W-L column titles.
    /// They live INSIDE the list as its section header, so they scroll together with the
    /// rows, stick to the top while you scroll, and the big "CDL Standings" title can't
    /// slide through them when you pull to refresh (it could when they sat above the list).
    private var columnHeaders: some View {
        HStack {
            Text("RANK").frame(width: 40, alignment: .leading)
            Text("TEAM").frame(maxWidth: .infinity, alignment: .leading)
            Text("PTS").frame(width: 40)
            Text("W-L").frame(width: 50)
        }
        .font(.caption.bold())
        .foregroundColor(.gray)
    }
}

struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        StandingsView()
            .withPreviewData()
            .preferredColorScheme(.dark)
    }
}
