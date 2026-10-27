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
}

extension TeamStanding {
    /// The team's color. For now we look it up by name in TeamTheme.
    /// In step 1.2 we'll swap this to the scraped color (looked up by team ID).
    var color: Color {
        TeamTheme.theme(for: name).color
    }
}
