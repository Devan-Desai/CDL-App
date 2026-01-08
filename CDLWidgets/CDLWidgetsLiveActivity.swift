//
//  CDLWidgetsLiveActivity.swift
//  CDLWidgets
//
//  Created by Devan Desai on 2026-01-06.
//
import ActivityKit
import WidgetKit
import SwiftUI

// 1. This defines what data the scoreboard needs.
struct CDLAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var team1Score: Int
        var team2Score: Int
        var mapName: String
    }
    var matchName: String // Static: e.g., "Major 1 Grand Finals"
    var team1Name: String
    var team2Name: String
}

// 2. This defines how the scoreboard looks on your Lock Screen.
struct CDLWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CDLAttributes.self) { context in
            // Look up themes
            let team1 = TeamTheme.theme(for: context.attributes.team1Name)
            let team2 = TeamTheme.theme(for: context.attributes.team2Name)
            
            VStack(spacing: 4) {
                // Header (e.g., Major 1 Finals)
                Text(context.attributes.matchName.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                HStack {
                    // Left Team: Logo then Name
                    VStack(spacing: 6) {
                        Image(team1.logo, bundle: nil)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                        Text(context.attributes.team1Name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(team1.color)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Center Score
                    HStack(spacing: 12) {
                        Text("\(context.state.team1Score)")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                        Text("-")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("\(context.state.team2Score)")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                    }
                    
                    // Right Team: Logo then Name
                    VStack(spacing: 6) {
                        Image(team2.logo, bundle: nil)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                        Text(context.attributes.team2Name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(team2.color)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Map Badge
                Text(context.state.mapName)
                    .font(.system(size: 10, weight: .heavy))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
                    .padding(.bottom, 8)
            }
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            // ... (Your Dynamic Island code)
            DynamicIsland {
                 DynamicIslandExpandedRegion(.leading) {
                     let t1 = TeamTheme.theme(for: context.attributes.team1Name)
                     Label(t1.shortName, image: t1.logo).foregroundColor(t1.color)
                 }
                 DynamicIslandExpandedRegion(.trailing) {
                     let t2 = TeamTheme.theme(for: context.attributes.team2Name)
                     Label(t2.shortName, image: t2.logo).foregroundColor(t2.color)
                 }
                 DynamicIslandExpandedRegion(.bottom) {
                     Text("\(context.state.team1Score) - \(context.state.team2Score)").font(.title).bold()
                 }
            } compactLeading: {
                Image(TeamTheme.theme(for: context.attributes.team1Name).logo).resizable().frame(width: 20, height: 20)
            } compactTrailing: {
                Text("\(context.state.team1Score)-\(context.state.team2Score)")
            } minimal: {
                Image(TeamTheme.theme(for: context.attributes.team1Name).logo).resizable()
            }
        }
    }
}

