//
//  Color+Hex.swift
//  CDL App
//
//  Lets us write Color(hex: "#782CF2").
//  Lives in Shared/ so both the app and the Live Activity widget can use it.
//

import SwiftUI

// Simple helper to use Hex codes for colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 1)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

extension Color {
    /// Black or white — whichever is easier to read on top of this hex color.
    /// Examples: M80's neon yellow (#D6FF01) → black text; KOI purple (#782CF2) → white text.
    static func readableText(onHex hex: String) -> Color {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        guard cleaned.count == 6, Scanner(string: cleaned).scanHexInt64(&value) else { return .white }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        // How bright the color looks to a human eye (green looks brightest, blue darkest).
        let brightness = 0.299 * red + 0.587 * green + 0.114 * blue
        return brightness > 0.6 ? .black : .white
    }
}
