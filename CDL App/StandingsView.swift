//
//  StandingsView.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-06.
//


import SwiftUI

import SwiftUI

struct StandingsView: View {
    // We now only need the ScraperService as our source of truth
    @StateObject var scraper = ScraperService()

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
                
                // Use the scraper's standings. If empty, show loading.
                if scraper.standings.isEmpty {
                    Spacer()
                    ProgressView("Fetching Live Rosters...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                    Spacer()
                } else {
                    List(scraper.standings) { team in
                        NavigationLink(destination: TeamDetailView(team: team)) {
                            HStack {
                                // Rank
                                Text("\(team.rank)")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .frame(width: 30)
                                
                                // Team Info (Logo + Name)
                                HStack {
                                    Image(team.logo)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                    
                                    Text(team.name)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Points (Currently 0 until we merge the other page)
                                Text("\(team.points)")
                                    .frame(width: 40)
                                    .fontWeight(.bold)
                                
                                // Series Record
                                Text("\(team.matchWins)-\(team.matchLosses)")
                                    .frame(width: 50)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                    // Pull to Refresh now triggers the scraper!
                    .refreshable {
                        scraper.fetchStandings()
                    }
                }
            }
            .navigationTitle("CDL Standings")
            .onAppear {
                // Trigger the live fetch when the app opens
                scraper.fetchStandings()
            }
        }
    }
}

// Keep your TeamDetailView and Previews exactly as they were below this!

struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        StandingsView()
            .preferredColorScheme(.dark)
    }
}

struct TeamDetailView: View {
    let team: TeamStanding

    var body: some View {
        List {
            // Header with Logo and Stats
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
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            // Roster Section
            Section(header: Text("Active Roster")) {
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
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
