//
//  Match.swift
//  CDL App
//
//  One match between two teams.
//

import Foundation

/// Where a match is in its life, from "on the calendar" to "final".
enum MatchStatus: String, Codable {
    case preScheduled   // on the calendar, but the teams aren't decided yet (TBD vs TBD)
    case upcoming       // teams known, not started
    case live
    case final

    /// Short text for the schedule rows.
    /// (A `switch` must handle every case — Xcode errors if you forget one.)
    var label: String {
        switch self {
        case .preScheduled, .upcoming: return "Upcoming"
        case .live:                    return "Live"
        case .final:                   return "Final"
        }
    }
}

struct Match: Identifiable, Codable {
    let id: Int               // the CDL match ID — also its page: callofdutyleague.com/en-us/match/{id}
    let date: Date
    let status: MatchStatus

    let team1Id: Int?         // CDL team ID; nil while the team is TBD
    let team1Name: String     // "TBD" until decided
    let team1Logo: String
    let team1Score: Int?      // maps won; nil until there's a score

    let team2Id: Int?
    let team2Name: String
    let team2Logo: String
    let team2Score: Int?

    var isCompleted: Bool { status == .final }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var shortDisplayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
