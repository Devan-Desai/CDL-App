//
//  TeamLogos.swift
//  CDL App
//
//  Which logo image in Assets belongs to which team — matched by CDL team ID
//  (replaces the old name-based TeamTheme lookup).
//

import Foundation

enum TeamLogos {

    /// ONE switch for the whole app.
    /// • true  — personal builds: show the logo images we keep in Assets.
    /// • false — logo-free: every screen (and the Live Activity) shows colored badges instead.
    ///   Use this for anything published unless we get permission (see the roadmap's legal notes).
    static let useBundledLogos = true

    /// CDL team ID → image name in Assets.xcassets
    private static let assetByTeamId: [Int: String] = [
        6: "optic",       // OpTic Texas
        7: "faze",        // FaZe Vegas
        9: "heretics",    // Miami Heretics
        10: "ravens",     // Carolina Royal Ravens
        11: "mates",      // Paris Gentle Mates
        12: "g2",         // G2 Minnesota
        13: "cloud9",     // Cloud9 New York
        15: "falcons",    // Riyadh Falcons
        16: "surge",      // Vancouver Surge
        17: "koi",        // Toronto KOI
        69: "thieves",    // Los Angeles Thieves
        // 138 M80 Boston: no image yet (the "breach" image is the old Boston team) → badge
    ]

    /// The logo image name for a team, or nil → show a colored badge instead.
    static func assetName(forTeamId id: Int?) -> String? {
        guard useBundledLogos, let id else { return nil }
        return assetByTeamId[id]
    }
}
