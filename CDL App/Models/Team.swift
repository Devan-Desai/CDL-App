//
//  Team.swift
//  CDL App
//
//  The app's OWN description of a team. Every screen should use this instead of
//  the raw website JSON. If the CDL redesigns its website, we only fix the
//  scraper — none of the views have to change.
//

import SwiftUI

struct Team: Identifiable, Codable, Hashable {
    /// The CDL's numeric team ID (e.g. Toronto KOI = 17, M80 Boston = 138).
    /// This is the ONE thing we match teams on across pages. Names are not safe:
    /// the teams page says "New York Cloud9" while the standings page says "Cloud9 New York".
    let id: Int
    let fullName: String        // "Toronto KOI"
    let location: String        // "Toronto"
    let name: String            // "KOI"
    let abbreviation: String    // "TOR"
    let primaryColorHex: String // "#782CF2"
    let logoURL: URL?           // official logo (an SVG file) — see the roadmap's logo/licensing notes
    let roster: [Player]

    var primaryColor: Color { Color(hex: primaryColorHex) }   // Color(hex:) lives in TeamTheme.swift
}

struct Player: Identifiable, Codable, Hashable {
    let id: Int             // the CDL's player ID
    let alias: String       // gamertag, e.g. "Insight"
    let firstName: String
    let lastName: String
    let role: String?       // "Player", "Substitute", "Head Coach", "Coach", "Founder" — or missing
    let headshotURL: URL?
}
