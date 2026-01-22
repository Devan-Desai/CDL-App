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
            ZStack{
                LinearGradient( stops: [.init(color: team1.color, location: -0.5),
                                        .init(color: .black, location: 0.49),
                                        .init(color: .black, location: 0.51),
                                        .init(color: team2.color, location: 1.5)
            ],
            startPoint: .leading,
            endPoint: .trailing)
                VStack(spacing: 4) {
                    // Header
                    Text("CDL".uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(0.7)
                        .padding(.top, 8)
                    
                    HStack {
                        // Left Team: Logo then Name
                        VStack(spacing: 6) {
                            Image(team1.logo, bundle: nil)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .overlay(alignment: .bottom) {
                                    Text(team1.shortName)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .opacity(0.7)
                                        .offset(y: 22)
                                }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Center Score
                        HStack(spacing: 12) {
                            Text("\(context.state.team1Score)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(0.9)
                            Text("-")
                                .font(.title2)
                                .foregroundColor(.white)
                                .opacity(0.9)
                            Text("\(context.state.team2Score)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(0.9)
                        }
                        
                        // Right Team: Logo then Name
                        VStack(spacing: 6) {
                            Image(team2.logo, bundle: nil)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .overlay(alignment: .bottom) {
                                    Text(team2.shortName)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .opacity(0.7)
                                        .offset(y: 22)
                                }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Map Badge
                    Text(context.state.mapName)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                        .padding(.bottom, 8)
                }
            }
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            // ... (Dynamic Island code)
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text("CDL".uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    let team1 = TeamTheme.theme(for: context.attributes.team1Name)
                    let team2 = TeamTheme.theme(for: context.attributes.team2Name)
                    
                    VStack(spacing: 8) {
                        HStack{
                            VStack(spacing: 4) { // Left Team
                                Image(team1.logo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                Text(context.attributes.team1Name)
                                    .font(.system(size: 12,weight: .bold))
                                    .foregroundColor(team1.color)
                            }
                            .frame(maxWidth: .infinity)
                            HStack(spacing: 8) { // Center Score
                                Text("\(context.state.team1Score)").font(.system(size: 38, weight: .black, design: .rounded))
                                Text("-").font(.title2)
                                Text("\(context.state.team2Score)").font(.system(size: 38, weight: .black, design: .rounded))
                            }
                            VStack(spacing: 4) { // Right Team
                                Image(team2.logo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                Text(context.attributes.team2Name)
                                    .font(.system(size: 12,weight: .bold))
                                    .foregroundColor(team2.color)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        Text(context.state.mapName)
                            .font(.system(size: 10, weight: .heavy))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.15)))
                            .padding(.bottom, 5)
                    }
                 }
            } compactLeading: {
                HStack(spacing: 10) {
                    Image(TeamTheme.theme(for: context.attributes.team1Name).logo).resizable().frame(width: 15, height: 15)
                    Text("\(context.state.team1Score)")
                }
            } compactTrailing: {
                HStack(spacing: 10) {
                    Text("\(context.state.team2Score)")
                    Image(TeamTheme.theme(for: context.attributes.team2Name).logo).resizable().frame(width: 15, height: 15)
                }
            } minimal: {
                Image(TeamTheme.theme(for: context.attributes.team1Name).logo).resizable()
            }
        }
    }
}

#Preview(
    "Dynamic Island Compact",
    as: .content,
    using: CDLAttributes(
        team1Name: "Cloud9 New York",
        team2Name: "Toronto KOI"
    )
) {
    CDLWidgetsLiveActivity()
} contentStates: {
    CDLAttributes.ContentState(
        team1Score: 2,
        team2Score: 1,
        mapName: "Hardpoint - Exposure"
    )
}

