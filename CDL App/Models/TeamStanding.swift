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
    let logo: String
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
    /// The team's color: the scraped one when we have it, otherwise the old hard-coded one.
    var color: Color {
        if let hex = colorHex {
            return Color(hex: hex)
        }
        return TeamTheme.theme(for: name).color
    }
}
