//
//  StandingsView.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-06.
//

import SwiftUI

struct StandingsView: View {
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
                
                if scraper.standings.isEmpty {
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
                    List(scraper.standings) { team in
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
                                
                                // Stats (Placeholder 0s until merged)
                                Text("\(team.points)")
                                    .frame(width: 40)
                                    .fontWeight(.bold)
                                
                                Text("\(team.matchWins)-\(team.matchLosses)")
                                    .frame(width: 50)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        scraper.fetchStandings()
                    }
                }
            }
            .navigationTitle("CDL Standings")
            .onAppear {
                scraper.fetchStandings()
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
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
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

struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        StandingsView()
            .preferredColorScheme(.dark)
    }
}
