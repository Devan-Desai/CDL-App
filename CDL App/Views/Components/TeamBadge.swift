//
//  TeamBadge.swift
//  CDL App
//
//  Reusable little circle with a team's color + abbreviation.
//

import SwiftUI

/// A logo-free team badge: the team's color plus its abbreviation.
/// Uses no team artwork, so it's safe in a published app (see the roadmap's licensing notes).
struct TeamBadge: View {
    let team: Team
    var size: CGFloat = 32

    var body: some View {
        Circle()
            .fill(team.primaryColor.gradient)
            .frame(width: size, height: size)
            .overlay {
                Text(team.abbreviation)
                    .font(.system(size: size * 0.32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 1)   // keeps white text readable on bright colors like M80's
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(4)
            }
    }
}
