//
//  MatchDetailView.swift
//  CDL App
//
//  Tap a match in the Schedule → this screen: both teams, the series score,
//  and every map's mode, map name and score.
//

import SwiftUI

struct MatchDetailView: View {
    let match: Match                        // what the schedule already knows — shown while the page loads
    @EnvironmentObject var teams: TeamsScraperService
    @EnvironmentObject var live: LiveActivityController

    @State private var detail: MatchDetail?
    @State private var message: String?     // "not published yet" or an error

    var body: some View {
        List {
            Section {
                header
            }

            Section("Maps") {
                mapsSection
            }

            liveSection

            if let vod = detail?.vodURL {
                Section {
                    Link(destination: vod) {
                        Label("Watch the VOD", systemImage: "play.rectangle.fill")
                    }
                }
            }
        }
        .navigationTitle("Match")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            detail = try await MatchDetailService.fetch(matchId: match.id)
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }

    // MARK: Header —  [LAT]  3 – 1  [MIA]

    private var header: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                teamColumn(id: detail?.team1.id ?? match.team1Id, name: detail?.team1.name ?? match.team1Name)

                VStack(spacing: 4) {
                    Text(scoreText)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(statusText)
                        .font(.caption.bold())
                        .foregroundColor(isLive ? Color.red : Color.secondary)
                }

                teamColumn(id: detail?.team2.id ?? match.team2Id, name: detail?.team2.name ?? match.team2Name)
            }
            Text(match.displayDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func teamColumn(id: Int?, name: String) -> some View {
        VStack(spacing: 6) {
            TeamLogo(teamId: id, size: 56)
            Text(teams.team(withId: id)?.abbreviation ?? "TBD")
                .font(.headline)
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private var isLive: Bool { detail?.currentMap != nil }

    private var scoreText: String {
        if let detail, detail.isFinal || isLive || !detail.playedMaps.isEmpty {
            return "\(detail.team1MapsWon) – \(detail.team2MapsWon)"
        }
        if let s1 = match.team1Score, let s2 = match.team2Score {
            return "\(s1) – \(s2)"
        }
        return "VS"
    }

    private var statusText: String {
        if let detail {
            if detail.isFinal { return "FINAL" }
            if let current = detail.currentMap { return "LIVE · MAP \(current.number)" }
        }
        return match.status.label.uppercased()
    }

    // MARK: Live Activity

    @ViewBuilder
    private var liveSection: some View {
        if let detail, !detail.isFinal {
            Section {
                if live.followedMatchId == match.id {
                    Button(role: .destructive) {
                        live.stop()
                    } label: {
                        Label("Stop following", systemImage: "stop.circle")
                    }
                } else {
                    Button {
                        live.follow(matchId: match.id, teams: teams)
                    } label: {
                        Label("Follow on Lock Screen", systemImage: "bolt.fill")
                    }
                }
                if let status = live.status {
                    Text(status).font(.footnote).foregroundColor(.secondary)
                }
            } footer: {
                Text("Updates every 30 seconds while the app is open.")
            }
        } else if let detail, detail.isFinal, !detail.playedMaps.isEmpty {
            Section {
                Button {
                    live.replay(matchId: match.id, teams: teams)
                } label: {
                    Label("Replay on Lock Screen", systemImage: "play.circle")
                }
                .disabled(live.isReplaying)
                if let status = live.status {
                    Text(status).font(.footnote).foregroundColor(.secondary)
                }
            } footer: {
                Text("Plays the match back map by map — a quick way to see the Live Activity.")
            }
        }
    }

    // MARK: Maps

    @ViewBuilder
    private var mapsSection: some View {
        if let detail {
            if detail.visibleMaps.isEmpty {
                Text("No maps played yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(detail.visibleMaps) { map in
                    MapResultRow(map: map, detail: detail, isCurrent: map.id == detail.currentMap?.id)
                }
            }
        } else if let message {
            Text(message)
                .foregroundColor(.secondary)
        } else {
            HStack(spacing: 8) {
                ProgressView()
                Text("Loading…")
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// One row:  MAP 1  Hardpoint · Sake        250 – 137   (winner's score bold, in their color)
struct MapResultRow: View {
    let map: MapResult
    let detail: MatchDetail
    let isCurrent: Bool
    @EnvironmentObject var teams: TeamsScraperService

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isCurrent ? "MAP \(map.number) · LIVE" : "MAP \(map.number)")
                    .font(.caption2.bold())
                    .foregroundColor(isCurrent ? Color.red : Color.secondary)
                Text(map.mode ?? "TBD")
                    .font(.subheadline.bold())
                Text(map.mapName ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            score(map.team1Score, teamId: detail.team1.id)
            Text("–")
                .foregroundColor(.secondary)
            score(map.team2Score, teamId: detail.team2.id)
        }
        .padding(.vertical, 2)
    }

    private func score(_ value: Int?, teamId: Int) -> some View {
        let won = map.winnerTeamId == teamId
        let teamColor = teams.team(withId: teamId)?.primaryColor ?? Color.primary
        return Text(value.map { String($0) } ?? "–")
            .font(.title3.monospacedDigit())
            .fontWeight(won ? .bold : .regular)
            .foregroundColor(won ? teamColor : Color.secondary)
            .frame(minWidth: 44)
    }
}

#Preview("Finished match — LAT 3–1 MIA") {
    NavigationView {
        MatchDetailView(match: Match(
            id: 13100,
            date: Date(timeIntervalSince1970: 1776457800),
            status: .final,
            team1Id: 69, team1Name: "Los Angeles Thieves", team1Score: 3,
            team2Id: 9, team2Name: "Miami Heretics", team2Score: 1
        ))
    }
    .withPreviewData()
}
