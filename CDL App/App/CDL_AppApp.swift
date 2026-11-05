//
//  CDL_AppApp.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-06.
//

import SwiftUI

@main
struct CDL_AppApp: App {
    // The app's data lives HERE — created once, when the app starts.
    // Every screen reads these same three copies (before 1.5, each screen made its own
    // and downloaded everything separately).
    @StateObject private var teams = TeamsScraperService()
    @StateObject private var standings = StandingsScraperService()
    @StateObject private var schedule = ScheduleScraperService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Put the three stores "in the environment": every screen inside ContentView
                // can now grab them with @EnvironmentObject.
                .environmentObject(teams)
                .environmentObject(standings)
                .environmentObject(schedule)
                // Load everything once at launch. (Each shows its saved copy first — step 1.4.)
                .task {
                    standings.fetchStandings()
                    await teams.fetchTeams()
                    await schedule.fetchSchedule()
                }
        }
    }
}

// MARK: - Previews
// Previews don't start the app, so nothing puts the stores in the environment.
// Screens that use @EnvironmentObject need this, or the preview crashes.
extension View {
    func withPreviewData() -> some View {
        self
            .environmentObject(TeamsScraperService())
            .environmentObject(StandingsScraperService())
            .environmentObject(ScheduleScraperService())
    }
}
