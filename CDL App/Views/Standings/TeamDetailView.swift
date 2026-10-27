//
//  TeamDetailView.swift
//  CDL App
//
//  The screen you get when you tap a team in Standings.
//

import SwiftUI

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
                                .foregroundColor(team.color)
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
