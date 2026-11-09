//
//  MonsterTestSection.swift
//  CDL App
//
//  TEST ONLY: the part of the Live tab that lists Monster Invitational matches.
//  Tap one to follow it on the Lock Screen, using the same LiveActivityController as
//  CDL matches. It just reads BreakingPoint's pages instead of the CDL's.
//

#if DEBUG
import SwiftUI

struct MonsterTestSection: View {
    @EnvironmentObject var live: LiveActivityController
    @EnvironmentObject var teams: TeamsScraperService

    @State private var matches: [BreakingPointMatchService.EventMatch] = []
    @State private var message: String? = "Loading…"

    var body: some View {
        Section {
            ForEach(matches) { match in
                Button {
                    if live.followedMatchId == match.id {
                        live.stop()
                    } else {
                        live.follow(matchId: match.id, teams: teams, load: BreakingPointMatchService.fetch)
                    }
                } label: {
                    row(for: match)
                }
            }
            if let message {
                Text(message).font(.footnote).foregroundColor(.secondary)
            }
            Button("Refresh list") {
                Task { await load() }
            }
        } header: {
            Text("Monster Invitational (test)")
        } footer: {
            Text("Data from BreakingPoint, updated every 30 seconds while the app is open. Tap a match to follow it, tap again to stop.")
        }
        .task { await load() }
    }

    private func row(for match: BreakingPointMatchService.EventMatch) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(match.title)
                Text(match.status == "live"
                     ? "LIVE · \(match.round)"
                     : "\(match.date?.formatted(date: .abbreviated, time: .shortened) ?? "") · \(match.round)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if live.followedMatchId == match.id {
                Image(systemName: "bolt.fill")
            }
        }
    }

    private func load() async {
        do {
            matches = try await BreakingPointMatchService.fetchEventMatches(eventId: BreakingPointMatchService.monsterEventId)
            message = matches.isEmpty ? "Nothing live or upcoming with known teams right now." : nil
        } catch {
            message = "Couldn't load the matches: \(error.localizedDescription)"
        }
    }
}
#endif
