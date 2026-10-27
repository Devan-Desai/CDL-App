//
//  ContentView.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-06.
//
import SwiftUI

/// The app's tab bar. Each tab's screen lives in its own folder under Views/.
struct ContentView: View {
    var body: some View {
        TabView {
            ScheduleView()
                .tabItem { Label("Schedule", systemImage: "calendar") }

            LiveTestView()
                .tabItem { Label("Live", systemImage: "bolt.fill") }

            StandingsView()
                .tabItem { Label("Standings", systemImage: "list.number") }

            TeamsView()
                .tabItem { Label("Teams", systemImage: "person.3.fill") }
        }
    }
}
