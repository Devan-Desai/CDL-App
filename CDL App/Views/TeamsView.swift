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

/// A logo-free team badge: the team's color plus its abbreviation.
/// Uses no team artwork, so it's safe in a published app (see the roadmap's licensing notes).
struct TeamBadge: View {
    let team: Team
    var size: CGFloat = 32

    var body: some View {
        Circle()
            .fill(team.primaryColor.gradient)
            .frame(width: size, height: size)
            .overlay {
                Text(team.abbreviation)
                    .font(.system(size: size * 0.32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 1)   // keeps white text readable on bright colors like M80's
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(4)
            }
    }
}

#Preview {
    TeamsView()
        .preferredColorScheme(.dark)
}
