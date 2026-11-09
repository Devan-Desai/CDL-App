//
//  LiveTestView.swift
//  CDL App
//
//  The "Live" tab. Before the season starts there are no live matches, so this
//  replays a REAL finished match (LA Thieves 3–1 Miami Heretics, last season) on the
//  Lock Screen, map by map, using the same code that follows a live match.
//

import SwiftUI

struct LiveTestView: View {
    @EnvironmentObject var live: LiveActivityController
    @EnvironmentObject var teams: TeamsScraperService
    @EnvironmentObject var standings: StandingsScraperService

    /// callofdutyleague.com/en-us/match/13100 — LAT 3–1 MIA, April 2026
    private let sampleMatchId = 13100

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button {
                        live.replay(matchId: sampleMatchId, teams: teams, standings: standings)
                    } label: {
                        Label("Replay LAT vs MIA (last season)", systemImage: "play.circle.fill")
                    }
                    .disabled(live.isReplaying)

                    Button(role: .destructive) {
                        live.stop()
                    } label: {
                        Label("End Live Activity", systemImage: "stop.circle")
                    }
                } header: {
                    Text("Test the Live Activity")
                } footer: {
                    Text("Plays a real finished match back map by map (about a minute). Lock the phone — ⌘L in the Simulator — to watch it on the Lock Screen.")
                }

                if let status = live.status {
                    Section("Status") {
                        Text(status)
                    }
                }

                Section {
                    Text("To follow a real match, open it from the Schedule tab and tap “Follow on Lock Screen”. The season starts Dec 4.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Live")
        }
    }
}

#Preview {
    LiveTestView()
        .withPreviewData()
}
