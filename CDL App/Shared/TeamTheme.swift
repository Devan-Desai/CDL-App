//
//  TeamTheme.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-08.
//

import SwiftUI

// ⚠️ Hard-coded, matched by NAME. Being replaced by scraped data matched by team ID
// (TeamsScraperService). Still used by the Live Activity until Phase 2.


// MARK: - Team Theme Engine
struct TeamTheme {
    let logo: String
    let color: Color
    let shortName: String
    
    static func theme(for name: String) -> TeamTheme {
        switch name {
        case "OpTic Texas":
            return TeamTheme(logo: "optic", color: Color(hex: "#92c951"), shortName: "OPTIC")
        case "FaZe Vegas":
            return TeamTheme(logo: "faze", color: Color(hex: "#ff00ff"), shortName: "FAZE")
        case "Los Angeles Thieves":
            return TeamTheme(logo: "thieves", color: Color(hex: "#ff0000"), shortName: "LAT")
        case "Toronto KOI":
            return TeamTheme(logo: "koi", color: Color(hex: "#782cf2"), shortName: "KOI")
        case "Cloud9 New York":
            return TeamTheme(logo: "cloud9", color: Color(hex: "#00aeef"), shortName: "C9")
        case "Miami Heretics":
            return TeamTheme(logo: "heretics", color: Color(hex: "#dd6d17"), shortName: "MIA")
        case "Carolina Royal Ravens":
            return TeamTheme(logo: "ravens", color: Color(hex: "#0083c1"), shortName: "CAR")
        case "Vancouver Surge":
            return TeamTheme(logo: "surge", color: Color(hex: "#00667d"), shortName: "VAN")
        case "G2 Minnesota":
            return TeamTheme(logo: "g2", color: Color(hex: "#342565"), shortName: "G2")
        case "Boston Breach":
            return TeamTheme(logo: "breach", color: Color(hex: "#02ff5b"), shortName: "BOS")
        case "Riyadh Falcons":
            return TeamTheme(logo: "falcons", color: Color(hex: "#1a825a"), shortName: "FLCN")
        case "Paris Gentle Mates":
            return TeamTheme(logo: "mates", color: Color(hex: "##ed89e5"), shortName: "M8")
        default:
            return TeamTheme(logo: "default", color: .white, shortName: "CDL")
        }
    }
}
