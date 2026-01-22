//
//  StandingsView.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-06.
//

import SwiftUI

struct StandingsView: View {
    @StateObject var rosterScraper = ScraperService()
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

struct TeamDetailView: View {
    let team: TeamStanding

    var body: some View {
        List {
            Section {
                VStack(alignment: .center, spacing: 10) {
                    Image(team.logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                    
                    Text(team.name)
                        .font(.title).bold()
                    
                    HStack(spacing: 30) {
                        VStack {
                            Text("\(team.points)").font(.headline)
                            Text("Points").font(.caption).foregroundColor(.secondary)
                        }
                        VStack {
                            Text("\(team.matchWins)-\(team.matchLosses)").font(.headline)
                            Text("Series").font(.caption).foregroundColor(.secondary)
                        }
                        VStack {
                            Text("\(team.mapWins)-\(team.mapLosses)").font(.headline)
                            Text("Maps").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            Section(header: Text("Active Roster")) {
                if team.roster.isEmpty {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                        Text("Loading roster...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 5)
                } else {
                    ForEach(team.roster, id: \.self) { player in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.orange)
                            Text(player)
                                .font(.headline)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            
            // Team Schedule Section
            TeamScheduleSection(team: team)
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        StandingsView()
            .preferredColorScheme(.dark)
    }
}
