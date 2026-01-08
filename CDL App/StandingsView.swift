//
//  StandingsView.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-06.
//


import SwiftUI

import SwiftUI

struct StandingsView: View {
    // 1. ADD THIS LINE: This creates the connection to your data engine
    @StateObject var loader = DataLoader()

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
                
                // 2. CHECK THIS: If standings is empty, show a loading spinner
                if loader.standings.isEmpty {
                    Spacer()
                    ProgressView("Fetching Rosters...") // Built-in Apple spinner
                    Spacer()
                } else {
                    List(loader.standings) { team in
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
                                
                                // Points
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
                    // 3. ADD THIS: Allows you to pull down to refresh the data!
                    .refreshable {
                        loader.loadData()
                    }
                }
            }
            .navigationTitle("CDL Standings")
            // 4. ADD THIS: This triggers the fetch as soon as the screen opens
            .onAppear {
                loader.loadData()
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
