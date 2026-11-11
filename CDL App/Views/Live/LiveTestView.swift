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

                recorderSection
            }
            .navigationTitle("Live")
            .onAppear(perform: refreshTotals)
            .onChange(of: live.status) { refreshTotals() }   // a new update may mean a new saved page
        }
    }

    // MARK: Kickoff weekend recorder (see Storage/SnapshotRecorder.swift)

    /// @AppStorage = a @State that's kept in the phone's settings, so the switch
    /// stays on after the app restarts. Same key the recorder reads.
    @AppStorage(SnapshotRecorder.settingKey) private var recordSnapshots = false
    @State private var totals = (files: 0, bytes: 0)
    @State private var confirmDelete = false

    private var recorderSection: some View {
        Section {
            Toggle("Save match pages while following", isOn: $recordSnapshots)
            LabeledContent("Saved pages",
                           value: "\(totals.files) · \(totals.bytes.formatted(.byteCount(style: .file)))")
            if totals.files > 0 {
                Button("Delete all saved pages", role: .destructive) { confirmDelete = true }
                    .confirmationDialog("Delete all saved pages?", isPresented: $confirmDelete, titleVisibility: .visible) {
                        Button("Delete", role: .destructive) {
                            SnapshotRecorder.deleteAll()
                            refreshTotals()
                        }
                    }
            }
        } header: {
            Text("Kickoff weekend recorder")
        } footer: {
            Text("Turn this on before tapping “Follow”. While following, the app keeps every match page it downloads (every 30 s) and the schedule every ~2 min. The screen stays on so the app keeps running — put the phone on a charger. Files: On My iPhone → CDL App → Snapshots.")
        }
    }

    private func refreshTotals() {
        let now = SnapshotRecorder.totals()
        totals = (now.files, now.bytes)
    }
}

#Preview {
    LiveTestView()
        .withPreviewData()
}
