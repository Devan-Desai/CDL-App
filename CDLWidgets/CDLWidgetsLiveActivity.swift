//
//  CDLWidgetsLiveActivity.swift
//  CDLWidgets
//
//  The Live Activity for one match: the Lock Screen banner and the Dynamic Island.
//  This file is compiled into BOTH the widget (which draws it) and the app (which
//  starts and updates it — see LiveActivity/LiveActivityController.swift).
//
//  A widget can't download anything or look things up, so the app hands it
//  everything it needs: abbreviations, colors, logo names, records and the scores.
//
//  Layout (Lock Screen), three columns:
//
//     [logo]        ● LIVE · MAP 4          [logo]
//      LAT            140 – 121              MIA
//      3–1       HARDPOINT · COLOSSUS        2–2
//                    ●●○ | ○○●
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
        var mapNumber: Int          // the map this is about (1, 2, …): live, up next, or the last one when final
        var mapName: String         // "Colossus" ("" if not known yet)
        var modeName: String        // "Hardpoint"
        var shortMode: String       // "HP"
        var team1MapScore: Int?     // score on that map, e.g. 140 — nil = no score yet (map not started)
        var team2MapScore: Int?
        var mapsToWin: Int          // first to 3 (Bo5), 4 (Bo7) or 5 (Bo9)
        var isFinal: Bool
    }

    /// One team — fixed for the whole match.
    struct Side: Codable, Hashable {
        var abbreviation: String    // "LAT"
        var colorHex: String        // "#ED2224"
        var logoAsset: String?      // logo image in Assets, or nil → colored badge
        var record: String?         // "3–1" this Major (or this season); nil = don't show
    }

    var matchId: Int
    var team1: Side                 // home team (left)
    var team2: Side                 // away team (right)
}

extension CDLAttributes.ContentState {

    /// A map is live when it has a score and the match isn't over.
    /// A map without a score (yet) counts as "up next".
    var isMapLive: Bool {
        !isFinal && team1MapScore != nil && team2MapScore != nil
    }

    /// The small line at the top: "LIVE · MAP 4", "UP NEXT · MAP 5" or "FINAL".
    var statusLine: String {
        if isFinal { return "FINAL" }
        let map = "MAP \(max(mapNumber, 1))"
        return isMapLive ? "LIVE · \(map)" : "UP NEXT · \(map)"
    }

    /// The big numbers: the live map's score; the series score between maps and at the end.
    var bigScore: (Int, Int) {
        if isMapLive, let a = team1MapScore, let b = team2MapScore {
            return (a, b)
        }
        return (team1Maps, team2Maps)
    }

    /// The line under the score: "HARDPOINT · COLOSSUS", or "MAP 4 · HARDPOINT · 250–197" when final.
    var detailLine: String {
        if isFinal {
            var parts = ["MAP \(mapNumber)"]
            if !modeName.isEmpty { parts.append(modeName.uppercased()) }
            if let a = team1MapScore, let b = team2MapScore { parts.append("\(a)–\(b)") }
            return parts.joined(separator: " · ")
        }
        return [modeName, mapName]
            .filter { !$0.isEmpty }
            .map { $0.uppercased() }
            .joined(separator: " · ")
    }
}

// MARK: - Look

/// The three background designs. Change `current` to try another one everywhere.
enum LiveBackgroundStyle: CaseIterable {
    case blend    // gradient from team 1's color to team 2's
    case split    // hard diagonal edge between the two colors
    case accent   // dark card with a thin two-color bar on top

    static let current: LiveBackgroundStyle = .blend
}

/// Our fonts (bundled in Shared/Fonts). If a font is missing for some reason, the
/// system font in its condensed width stands in, so the layout still looks right.
enum LiveFont {
    /// Big numbers: Saira Condensed Bold.
    static func number(_ size: CGFloat) -> Font {
        saira("SairaCondensed-Bold", size, fallbackWeight: .bold)
    }
    /// Small numbers, e.g. the Dynamic Island's compact score: Saira Condensed SemiBold.
    static func smallNumber(_ size: CGFloat) -> Font {
        saira("SairaCondensed-SemiBold", size, fallbackWeight: .semibold)
    }
    /// Labels: Saira Semi Condensed, SemiBold or Bold.
    static func label(_ size: CGFloat, bold: Bool = false) -> Font {
        bold ? saira("SairaSemiCondensed-Bold", size, fallbackWeight: .bold)
             : saira("SairaSemiCondensed-SemiBold", size, fallbackWeight: .semibold)
    }

    private static func saira(_ name: String, _ size: CGFloat, fallbackWeight: Font.Weight) -> Font {
        if UIFont(name: name, size: size) != nil {
            return .custom(name, fixedSize: size)
        }
        return .system(size: size, weight: fallbackWeight).width(.condensed)
    }
}

// MARK: - The widget

struct CDLWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CDLAttributes.self) { context in
            // Lock Screen (and the banner on iPhones without a Dynamic Island)
            LiveScoreboard(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color.black)
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            let attributes = context.attributes
            let state = context.state
            return DynamicIsland {
                // Expanded: the Lock Screen layout, on the Island's black.
                DynamicIslandExpandedRegion(.leading) {
                    LiveTeamColumn(side: attributes.team1, size: 38)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveTeamColumn(side: attributes.team2, size: 38)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 0) {
                        LiveStatusLine(state: state, size: 11)
                        LiveBigScore(state: state, size: 38)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 5) {
                        LiveDetailLine(state: state, size: 11)
                        LiveSeriesDots(attributes: attributes, state: state, dotSize: 9)
                    }
                }
            } compactLeading: {
                // Compact: badge + current map score on each side (series score if no map score).
                HStack(spacing: 5) {
                    LiveTeamMark(side: attributes.team1, size: 18)
                    Text("\(state.bigScore.0)")
                        .font(LiveFont.smallNumber(16))
                        .monospacedDigit()
                }
            } compactTrailing: {
                HStack(spacing: 5) {
                    Text("\(state.bigScore.1)")
                        .font(LiveFont.smallNumber(16))
                        .monospacedDigit()
                    LiveTeamMark(side: attributes.team2, size: 18)
                }
            } minimal: {
                // Minimal: the series score, e.g. "2-1".
                Text("\(state.team1Maps)-\(state.team2Maps)")
                    .font(LiveFont.smallNumber(13))
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Lock Screen

/// The Lock Screen banner: team · center · team, on one of the three backgrounds.
struct LiveScoreboard: View {
    let attributes: CDLAttributes
    let state: CDLAttributes.ContentState
    var style: LiveBackgroundStyle = .current

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            LiveTeamColumn(side: attributes.team1, size: 50)
                .frame(width: 78)

            VStack(spacing: 2) {
                LiveStatusLine(state: state, size: 12)
                LiveBigScore(state: state, size: 50)
                LiveDetailLine(state: state, size: 12)
                LiveSeriesDots(attributes: attributes, state: state, dotSize: 11)
                    .padding(.top, 5)
            }
            .frame(maxWidth: .infinity)

            LiveTeamColumn(side: attributes.team2, size: 50)
                .frame(width: 78)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .foregroundColor(.white)
        .background(LiveBackground(style: style,
                                   color1: Color(hex: attributes.team1.colorHex),
                                   color2: Color(hex: attributes.team2.colorHex)))
    }
}

/// The colored background behind the Lock Screen banner.
struct LiveBackground: View {
    let style: LiveBackgroundStyle
    let color1: Color
    let color2: Color

    var body: some View {
        switch style {
        case .blend:
            ZStack {
                // "Perceptual" mixing keeps the middle of e.g. red → green from turning muddy brown.
                Rectangle().fill(.linearGradient(Gradient(colors: [color1, color2]).colorSpace(.perceptual),
                                                 startPoint: .leading, endPoint: .trailing))
                DarkOverlay()
            }
        case .split:
            ZStack {
                color1
                DiagonalRightPart().fill(color2)
                DarkOverlay()
            }
        case .accent:
            ZStack(alignment: .top) {
                Color(hex: "#141519")
                HStack(spacing: 0) {
                    color1
                    color2
                }
                .frame(height: 5)
            }
        }
    }
}

/// Darker in the middle (58% black), lighter at the edges (30%), so white text
/// stays readable on any two team colors — even two bright ones like TX vs BOS.
struct DarkOverlay: View {
    var body: some View {
        EllipticalGradient(colors: [.black.opacity(0.58), .black.opacity(0.30)],
                           center: .center,
                           startRadiusFraction: 0,
                           endRadiusFraction: 0.75)
    }
}

/// The right-hand part of the "split" background: everything right of a slanted line.
struct DiagonalRightPart: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.width * 0.56, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.width * 0.46, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

// MARK: - Pieces (shared by the Lock Screen and the expanded Dynamic Island)

/// "● LIVE · MAP 4" — the red dot only while a map is live.
struct LiveStatusLine: View {
    let state: CDLAttributes.ContentState
    var size: CGFloat

    var body: some View {
        HStack(spacing: size * 0.4) {
            if state.isMapLive {
                Circle()
                    .fill(Color.red)
                    .frame(width: size * 0.55, height: size * 0.55)
            }
            Text(state.statusLine)
                .font(LiveFont.label(size, bold: true))
                .tracking(0.6)
        }
        .foregroundColor(.white)
        .opacity(0.9)
    }
}

/// "140 – 121": the map score while live, otherwise the series score.
struct LiveBigScore: View {
    let state: CDLAttributes.ContentState
    var size: CGFloat

    var body: some View {
        HStack(spacing: size * 0.2) {
            Text("\(state.bigScore.0)")
            Text("–")
                .font(LiveFont.number(size * 0.6))
                .opacity(0.7)
            Text("\(state.bigScore.1)")
        }
        .font(LiveFont.number(size))
        .monospacedDigit()
        .foregroundColor(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

/// "HARDPOINT · COLOSSUS", or "MAP 4 · HARDPOINT · 250–197" at the end.
struct LiveDetailLine: View {
    let state: CDLAttributes.ContentState
    var size: CGFloat

    var body: some View {
        Text(state.detailLine)
            .font(LiveFont.label(size))
            .tracking(0.5)
            .foregroundColor(.white)
            .opacity(0.8)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

/// One circle per map a team needs. Team 1's fill from the left, team 2's from the
/// right (outside in), so a 2–1 in a Bo5 looks like ●●○ | ○○●.
struct LiveSeriesDots: View {
    let attributes: CDLAttributes
    let state: CDLAttributes.ContentState
    var dotSize: CGFloat

    var body: some View {
        let toWin = max(state.mapsToWin, 1)
        let won1 = min(state.team1Maps, toWin)
        let won2 = min(state.team2Maps, toWin)
        HStack(spacing: dotSize * 0.5) {
            ForEach(0..<toWin, id: \.self) { index in
                dot(filled: index < won1, color: Color(hex: attributes.team1.colorHex))
            }
            Rectangle()   // the thin divider between the two teams
                .fill(Color.white.opacity(0.5))
                .frame(width: 1, height: dotSize * 1.3)
                .padding(.horizontal, dotSize * 0.2)
            ForEach(0..<toWin, id: \.self) { index in
                dot(filled: index >= toWin - won2, color: Color(hex: attributes.team2.colorHex))
            }
        }
    }

    /// Empty = a 2.5pt white ring at 70%. Won = filled with the team color (ring kept so
    /// a team color close to the background still shows).
    private func dot(filled: Bool, color: Color) -> some View {
        Circle()
            .fill(filled ? color : .clear)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.7), lineWidth: filled ? 1 : 2.5))
            .frame(width: dotSize, height: dotSize)
    }
}

/// A team's logo (or badge), its abbreviation, and its record if we know it.
struct LiveTeamColumn: View {
    let side: CDLAttributes.Side
    var size: CGFloat

    var body: some View {
        VStack(spacing: 3) {
            LiveTeamMark(side: side, size: size)
            Text(side.abbreviation)
                .font(LiveFont.label(size * 0.3, bold: true))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let record = side.record {
                Text(record)
                    .font(LiveFont.label(size * 0.24))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .opacity(0.75)
            }
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
                .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: max(size * 0.03, 1)))
                .frame(width: size, height: size)
                .overlay {
                    Text(side.abbreviation)
                        .font(LiveFont.label(size * 0.32, bold: true))
                        .foregroundColor(Color.readableText(onHex: side.colorHex))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(size * 0.08)
                }
        }
    }
}

// MARK: - Previews (LAT 3–1 MIA from last season, plus made-up Bo7/Bo9 and a bright pair)

extension CDLAttributes {
    static let preview = CDLAttributes(
        matchId: 13100,
        team1: Side(abbreviation: "LAT", colorHex: "#ED2224", logoAsset: "thieves", record: "3–1"),
        team2: Side(abbreviation: "MIA", colorHex: "#216D6B", logoAsset: "heretics", record: "2–2")
    )
    /// Two bright colors with badges: the hardest case for readable text.
    static let previewBright = CDLAttributes(
        matchId: 1,
        team1: Side(abbreviation: "TX", colorHex: "#92C951", logoAsset: nil, record: "2–2"),
        team2: Side(abbreviation: "BOS", colorHex: "#D6FF01", logoAsset: nil, record: "3–1")
    )
}

extension CDLAttributes.ContentState {
    static let previewLive = CDLAttributes.ContentState(
        team1Maps: 2, team2Maps: 1, mapNumber: 4, mapName: "Colossus", modeName: "Hardpoint",
        shortMode: "HP", team1MapScore: 140, team2MapScore: 121, mapsToWin: 3, isFinal: false)
    static let previewUpNext = CDLAttributes.ContentState(
        team1Maps: 2, team2Maps: 2, mapNumber: 5, mapName: "Sake", modeName: "Search & Destroy",
        shortMode: "SND", team1MapScore: nil, team2MapScore: nil, mapsToWin: 3, isFinal: false)
    static let previewFinal = CDLAttributes.ContentState(
        team1Maps: 3, team2Maps: 1, mapNumber: 4, mapName: "Colossus", modeName: "Hardpoint",
        shortMode: "HP", team1MapScore: 250, team2MapScore: 197, mapsToWin: 3, isFinal: true)
    static let previewBo7 = CDLAttributes.ContentState(
        team1Maps: 3, team2Maps: 2, mapNumber: 6, mapName: "Fringe", modeName: "Search & Destroy",
        shortMode: "SND", team1MapScore: 4, team2MapScore: 3, mapsToWin: 4, isFinal: false)
    static let previewBo9 = CDLAttributes.ContentState(
        team1Maps: 4, team2Maps: 3, mapNumber: 8, mapName: "Lotus", modeName: "Hijack",
        shortMode: "HJK", team1MapScore: 112, team2MapScore: 98, mapsToWin: 5, isFinal: false)
    static let previewBright = CDLAttributes.ContentState(
        team1Maps: 1, team2Maps: 0, mapNumber: 2, mapName: "Fringe", modeName: "Search & Destroy",
        shortMode: "SND", team1MapScore: 4, team2MapScore: 3, mapsToWin: 3, isFinal: false)
}

#Preview("Lock Screen", as: .content, using: CDLAttributes.preview) {
    CDLWidgetsLiveActivity()
} contentStates: {
    CDLAttributes.ContentState.previewLive
    CDLAttributes.ContentState.previewUpNext
    CDLAttributes.ContentState.previewFinal
    CDLAttributes.ContentState.previewBo7
    CDLAttributes.ContentState.previewBo9
}

#Preview("Lock Screen · TX vs BOS", as: .content, using: CDLAttributes.previewBright) {
    CDLWidgetsLiveActivity()
} contentStates: {
    CDLAttributes.ContentState.previewBright
    CDLAttributes.ContentState.previewFinal
}

#Preview("Dynamic Island", as: .dynamicIsland(.expanded), using: CDLAttributes.preview) {
    CDLWidgetsLiveActivity()
} contentStates: {
    CDLAttributes.ContentState.previewLive
    CDLAttributes.ContentState.previewUpNext
}

#Preview("Island · compact", as: .dynamicIsland(.compact), using: CDLAttributes.preview) {
    CDLWidgetsLiveActivity()
} contentStates: {
    CDLAttributes.ContentState.previewLive
    CDLAttributes.ContentState.previewUpNext
}

#Preview("Island · minimal", as: .dynamicIsland(.minimal), using: CDLAttributes.preview) {
    CDLWidgetsLiveActivity()
} contentStates: {
    CDLAttributes.ContentState.previewLive
}

/// All three backgrounds side by side, for both color pairs.
#Preview("Backgrounds") {
    ScrollView {
        VStack(spacing: 14) {
            ForEach(LiveBackgroundStyle.allCases, id: \.self) { style in
                LiveScoreboard(attributes: .preview, state: .previewLive, style: style)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                LiveScoreboard(attributes: .previewBright, state: .previewBright, style: style)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }
        }
        .padding()
    }
    .background(Color(white: 0.12))
}
