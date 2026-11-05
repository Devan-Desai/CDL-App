//
//  TeamLogo.swift
//  CDL App
//
//  Shows a team's mark, found by CDL team ID. Three possibilities, in order:
//    1. the logo image from Assets (if TeamLogos has one and logos are switched on)
//    2. otherwise a colored badge with the team's abbreviation (scraped data)
//    3. otherwise (TBD team, or teams not loaded yet) a plain gray circle
//

import SwiftUI
import UIKit

struct TeamLogo: View {
    let teamId: Int?
    var size: CGFloat = 24
    @EnvironmentObject var teams: TeamsScraperService

    var body: some View {
        // UIImage(named:) quietly returns nil when the image is missing — no console warning.
        if let asset = TeamLogos.assetName(forTeamId: teamId), UIImage(named: asset) != nil {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else if let team = teams.team(withId: teamId) {
            TeamBadge(team: team, size: size)
        } else {
            Circle()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: size, height: size)
        }
    }
}
