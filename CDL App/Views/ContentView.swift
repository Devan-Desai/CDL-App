//
//  ContentView.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-06.
//
import SwiftUI
import ActivityKit

struct ContentView: View {
    var body: some View {
        TabView {
            // TAB 1: Schedule
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
            // TAB 2: Live Activity Controls
            VStack(spacing: 30) {
                Text("CDL Match Control")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    Button("Start Live Scoreboard") {
                        startActivity()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    // Update button so you can test it changing!
                    Button("Update Score to 3-1") {
                        updateActivity()
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)

                    Button("End Match") {
                        endActivity()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            .tabItem {
                Label("Live", systemImage: "bolt.fill")
            }

            // TAB 3: Standings
            StandingsView()
                .tabItem {
                    Label("Standings", systemImage: "list.number")
                }
        }
    }

    func startActivity() {
        // 1. Check if the phone allows Live Activities
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Error: Live Activities are disabled in iPhone Settings")
            return
        }

        let attributes = CDLAttributes(
        team1Name: "Toronto KOI",
        team2Name: "FaZe Vegas")
        let initialState = CDLAttributes.ContentState(team1Score: 2, team2Score: 1, mapName: "Exposure - Hardpoint")
        let content = ActivityContent(state: initialState, staleDate: nil)
        
        do {
            let activity = try Activity<CDLAttributes>.request(attributes: attributes, content: content)
            print("✅ Activity Started! ID: \(activity.id)")
            print("👉 SWIPE UP TO HOME OR LOCK YOUR SCREEN TO SEE IT")
        } catch {
            print("❌ Error starting activity: \(error.localizedDescription)")
        }
    }

    func updateActivity() {
        Task {
            for activity in Activity<CDLAttributes>.activities {
                let updatedState = CDLAttributes.ContentState(team1Score: 3, team2Score: 1, mapName: "Raid")
                let content = ActivityContent(state: updatedState, staleDate: nil)
                await activity.update(content)
                print("✅ Score updated to 3-1")
            }
        }
    }

    func endActivity() {
        Task {
            for activity in Activity<CDLAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
                print("✅ Activity ended")
            }
        }
    }
}
