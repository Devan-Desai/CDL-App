//
//  CDLWidgetsLiveActivity.swift
//  CDLWidgets
//
//  The Live Activity for one match: the Lock Screen banner and the Dynamic Island.
//  This file is compiled into BOTH the widget (which draws it) and the app (which
//  starts and updates it — see LiveActivity/LiveActivityController.swift).
//
//  A widget can't download anything or look things up, so the app hands it
//  everything it needs: abbreviations, colors, logo names and the scores.
//

import ActivityKit
import WidgetKit
import SwiftUI
import UIKit

// MARK: - The data

struct CDLAttributes: ActivityAttributes {

    /// The part that changes during the match — the app sends a new one on every update.
    public struct ContentState: Codable, Hashable {
        var team1Maps: Int          // series score: maps won
        var team2Maps: Int
        var mapNumber: Int          // map being played (1–5); 0 = not started yet
        var mapName: String         // "Sake"
        var modeName: String        // "Hardpoint"
        var shortMode: String       // "HP"
        var team1MapScore: Int?     // score on that map, e.g. 187 (nil before it starts)
        var team2MapScore: Int?
        var isFinal: Bool
    }

    /// One team — fixed for the whole match.
    struct Side: Codable, Hashable {
        var abbreviation: String    // "LAT"
        var colorHex: String        // "#ED2224"
        var logoAsset: String?      // logo image in Assets, or nil → colored badge
    }

    var matchId: Int
    var team1: Side                 // home team (left)
    var team2: Side                 // away team (right)
}

extension CDLAttributes.ContentState {
    /// Small line above the score.
    var headline: String {
        if isFinal { return "FINAL" }
        if mapNumber == 0 { return "UP NEXT" }
        return "LIVE"
    }

    /// The pill under the score, e.g. "MAP 4 · HARDPOINT · COLOSSUS   140–121"
    var mapLine: String {
        guard mapNumber > 0 else { return "STARTING SOON" }
        var line = "MAP \(mapNumber) · \(modeName.uppercased()) · \(mapName.uppercased())"
        if let a = team1MapScore, let b = team2MapScore {
            line += "   \(a)–\(b)"
        }
        return line
    }
}

// MARK: - The widget

struct CDLWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CDLAttributes.self) { context in
            // Lock Screen (and the banner on iPhones without a Dynamic Island)
            LiveScoreboard(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveTeamColumn(side: context.attributes.team1, size: 36)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveTeamColumn(side: context.attributes.team2, size: 36)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.headline)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        LiveSeriesScore(state: context.state, size: 34)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveMapPill(state: context.state)
                }
            } compactLeading: {
                HStack(spacing: 6) {
                    LiveTeamMark(side: context.attributes.team1, size: 16)
                    Text("\(context.state.team1Maps)").bold()
                }
            } compactTrailing: {
                HStack(spacing: 6) {
                    Text("\(context.state.team2Maps)").bold()
                    LiveTeamMark(side: context.attributes.team2, size: 16)
                }
            } minimal: {
                Text("\(context.state.team1Maps)-\(context.state.team2Maps)")
                    .font(.caption2.bold())
            }
        }
    }
}

// MARK: - Pieces

/// The Lock Screen banner: team colors fading into black, logos, big series score, map pill.
struct LiveScoreboard: View {
    let attributes: CDLAttributes
    let state: CDLAttributes.ContentState

    var body: some View {
        ZStack {
            LinearGradient(stops: [.init(color: Color(hex: attributes.team1.colorHex), location: -0.5),
                                   .init(color: .black, location: 0.49),
                                   .init(color: .black, location: 0.51),
                                   .init(color: Color(hex: attributes.team2.colorHex), location: 1.5)],
                           startPoint: .leading,
                           endPoint: .trailing)

            VStack(spacing: 6) {
                Text(state.headline)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(0.7)

                HStack {
                    LiveTeamColumn(side: attributes.team1, size: 44)
                        .frame(maxWidth: .infinity)
                    LiveSeriesScore(state: state, size: 48)
                    LiveTeamColumn(side: attributes.team2, size: 44)
                        .frame(maxWidth: .infinity)
                }

                LiveMapPill(state: state)
            }
            .padding(.vertical, 10)
        }
    }
}

/// "2 - 1" — maps won.
struct LiveSeriesScore: View {
    let state: CDLAttributes.ContentState
    var size: CGFloat

    var body: some View {
        HStack(spacing: size * 0.25) {
            Text("\(state.team1Maps)")
            Text("-")
                .font(.system(size: size * 0.5, weight: .bold))
                .opacity(0.8)
            Text("\(state.team2Maps)")
        }
        .font(.system(size: size, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundColor(.white)
    }
}

/// The capsule with the current map, mode and map score.
struct LiveMapPill: View {
    let state: CDLAttributes.ContentState

    var body: some View {
        Text(state.mapLine)
            .font(.system(size: 10, weight: .heavy))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.white.opacity(0.15)))
    }
}

/// A team's logo with its abbreviation underneath.
struct LiveTeamColumn: View {
    let side: CDLAttributes.Side
    var size: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            LiveTeamMark(side: side, size: size)
            Text(side.abbreviation)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .opacity(0.8)
        }
    }
}

/// The logo image if we have one; otherwise a circle in the team color with its abbreviation.
struct LiveTeamMark: View {
    let side: CDLAttributes.Side
    var size: CGFloat

    var body: some View {
        if let asset = side.logoAsset, UIImage(named: asset) != nil {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Circle()
                .fill(Color(hex: side.colorHex))
                .frame(width: size, height: size)
                .overlay {
                    Text(side.abbreviation)
                        .font(.system(size: size * 0.3, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.readableText(onHex: side.colorHex))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(2)
                }
        }
    }
}

// MARK: - Previews (real numbers from LAT 3–1 MIA, last season)

extension CDLAttributes {
    static let preview = CDLAttributes(
        matchId: 13100,
        team1: Side(abbreviation: "LAT", colorHex: "#ED2224", logoAsset: "thieves"),
        team2: Side(abbreviation: "MIA", colorHex: "#216D6B", logoAsset: "heretics")
    )
}

extension CDLAttributes.ContentState {
    static let previewLive = CDLAttributes.ContentState(
        team1Maps: 2, team2Maps: 1, mapNumber: 4, mapName: "Colossus", modeName: "Hardpoint",
        shortMode: "HP", team1MapScore: 140, team2MapScore: 121, isFinal: false)
    static let previewFinal = CDLAttributes.ContentState(
        team1Maps: 3, team2Maps: 1, mapNumber: 4, mapName: "Colossus", modeName: "Hardpoint",
        shortMode: "HP", team1MapScore: 250, team2MapScore: 197, isFinal: true)
}

#Preview("Lock Screen", as: .content, using: CDLAttributes.preview) {
    CDLWidgetsLiveActivity()
} contentStates: {
    CDLAttributes.ContentState.previewLive
    CDLAttributes.ContentState.previewFinal
}

#Preview("Dynamic Island", as: .dynamicIsland(.expanded), using: CDLAttributes.preview) {
    CDLWidgetsLiveActivity()
} contentStates: {
    CDLAttributes.ContentState.previewLive
}
