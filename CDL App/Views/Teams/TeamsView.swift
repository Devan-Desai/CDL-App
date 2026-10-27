//
//  TeamsView.swift
//  CDL App
//
//  Shows what the teams scraper found. For now it's our test screen;
//  later it becomes the real Teams tab.
//

import SwiftUI

struct TeamsView: View {
    @StateObject private var scraper = TeamsScraperService()

    var body: some View {
        NavigationStack {
            List {
                if let error = scraper.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                ForEach(scraper.teams) { team in
                    HStack(spacing: 12) {
                        TeamBadge(team: team, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(team.fullName)
                                .font(.headline)
                            Text(team.roster.isEmpty ? "No roster yet" : team.roster.map(\.alias).joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("#\(team.id)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .overlay {
                if scraper.teams.isEmpty && scraper.errorMessage == nil {
                    ProgressView("Loading teams…")
                }
            }
            .navigationTitle("Teams")
            .task { await scraper.fetchTeams() }        // runs once when the screen appears
            .refreshable { await scraper.fetchTeams() } // pull down to reload
        }
    }
}

#Preview {
    TeamsView()
        .preferredColorScheme(.dark)
}
