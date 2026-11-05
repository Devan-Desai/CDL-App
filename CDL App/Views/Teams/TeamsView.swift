//
//  TeamsView.swift
//  CDL App
//
//  Shows what the teams scraper found. For now it's our test screen;
//  later it becomes the real Teams tab.
//

import SwiftUI

struct TeamsView: View {
    @EnvironmentObject var scraper: TeamsScraperService   // the app's shared copy (see CDL_AppApp)

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
            .refreshable { await scraper.fetchTeams() } // pull down to reload (the app loads it at launch)
        }
    }
}

#Preview {
    TeamsView()
        .withPreviewData()
        .preferredColorScheme(.dark)
}
