//
//  TeamStanding.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-06.
//


import SwiftUI

struct TeamStanding: Identifiable, Codable {
    let id = UUID()
    let rank: Int
    let name: String
    let points: Int
    let matchWins: Int
    let matchLosses: Int
    let mapWins: Int
    let mapLosses: Int
    let roster: [String]
    let teamId: Int          // the CDL's numeric team ID — how we match this row to a Team
    let colorHex: String?    // e.g. "#782CF2"; nil until the teams page has loaded
}

extension TeamStanding {
    /// The team's color (scraped), or gray until the teams page has loaded.
    var color: Color {
        Color(hex: colorHex ?? "#8E8E93")
    }

    /// Black or white — whichever reads best on top of `color`.
    var textOnColor: Color {
        Color.readableText(onHex: colorHex ?? "#8E8E93")
    }
}
