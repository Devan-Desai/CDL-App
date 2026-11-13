//
//  ContentState+MatchDetail.swift
//  CDL App (also compiled into the server in Server/)
//
//  Match page → Live Activity data. The app uses it while following a match; the
//  server uses the SAME code, so the phone and the server can never disagree about
//  what the scoreboard says. (Was `LiveActivityController.state(from:)` until Nov 12.)
//
//  The file name "A+B.swift" is a Swift habit for "an extension of A about B".
//

import Foundation

extension CDLAttributes.ContentState {

    /// Three situations:
    ///  • final       → the last map played (for the "MAP 4 · HARDPOINT · 250–197" line)
    ///  • a map slot without a winner → that map: LIVE if it has a score, UP NEXT if not
    ///  • nothing listed yet → UP NEXT for the map after the ones played (name unknown)
    ///
    /// Written as an `init` in an extension, so Swift still keeps the automatic
    /// "fill in every field" init too (the replay uses that one).
    init(detail: MatchDetail) {
        let map = detail.isFinal ? detail.playedMaps.last : detail.currentMap
        self.init(
            team1Maps: detail.team1MapsWon,
            team2Maps: detail.team2MapsWon,
            mapNumber: map?.number ?? detail.playedMaps.count + 1,
            mapName: map?.mapName ?? "",
            modeName: map?.mode ?? "",
            shortMode: map?.shortMode ?? "",
            team1MapScore: map?.team1Score,
            team2MapScore: map?.team2Score,
            mapsToWin: detail.mapsToWin,
            isFinal: detail.isFinal)
    }
}
