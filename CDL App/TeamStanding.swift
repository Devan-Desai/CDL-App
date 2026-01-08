//
//  TeamStanding.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-06.
//


import Foundation

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
