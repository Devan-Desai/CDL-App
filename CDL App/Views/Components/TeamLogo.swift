//
//  TeamLogo.swift
//  CDL App
//
//  A team's logo from Assets — if we have one.
//  If we don't (a "TBD" team, or a team newer than our logo files, like M80 Boston),
//  it shows a plain gray circle instead of asking SwiftUI for an image that doesn't
//  exist. Asking for a missing image is what printed:
//      "No image named 'default' found in asset catalog"
//

import SwiftUI
import UIKit

struct TeamLogo: View {
    let assetName: String     // e.g. "koi" (from TeamTheme)
    var size: CGFloat = 24

    var body: some View {
        // UIImage(named:) quietly returns nil when the image is missing — no warning.
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Circle()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: size, height: size)
        }
    }
}
