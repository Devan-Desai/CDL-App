//
//  Match.swift
//  CDL App
//
//  One match between two teams (moved out of ScheduleScraperService.swift).
//

import Foundation

// MARK: - Match Model
struct Match: Identifiable, Codable {
    let id: String
    let team1Name: String
    let team2Name: String
    let team1Logo: String
    let team2Logo: String
    let team1Score: Int?
    let team2Score: Int?
    let date: Date
    let isCompleted: Bool
    let matchTitle: String?
    
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
