//
//  ScheduleView.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-15.
//

import SwiftUI

struct ScheduleView: View {
    @StateObject var scheduleScraper = ScheduleScraperService()
    @StateObject var standingsScraper = StandingsScraperService()
    @State private var selectedFilter: ScheduleFilter = .upcoming
    
    enum ScheduleFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case completed = "Completed"
    }
    
    var filteredMatches: [Match] {
        switch selectedFilter {
        case .upcoming:
            return scheduleScraper.matches.filter { !$0.isCompleted }
        case .completed:
            return scheduleScraper.matches.filter { $0.isCompleted }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ScheduleFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if scheduleScraper.matches.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                            .scaleEffect(1.5)
                        Text("Loading CDL Schedule...")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if filteredMatches.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No \(selectedFilter.rawValue)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(groupedMatchesByDate(), id: \.key) { dateGroup in
                            Section(header: Text(dateGroup.key)) {
                                ForEach(dateGroup.value) { match in
                                    FullScheduleMatchRow(
                                        match: match,
                                        standings: standingsScraper.standings
                                    )
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .refreshable {
                        scheduleScraper.fetchSchedule()
                        standingsScraper.fetchStandings()
                    }
                }
            }
            .navigationTitle("CDL Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                scheduleScraper.fetchSchedule()
                standingsScraper.fetchStandings()
            }
        }
    }
    
    // Group matches by date for section headers
    private func groupedMatchesByDate() -> [(key: String, value: [Match])] {
        let grouped = Dictionary(grouping: filteredMatches) { match -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: match.date)
        }
        
        return grouped.sorted { first, second in
            guard let firstMatch = first.value.first,
                  let secondMatch = second.value.first else {
                return false
            }
            
            if selectedFilter == .upcoming {
                return firstMatch.date < secondMatch.date // Soonest first
            } else {
                return firstMatch.date > secondMatch.date // Most recent first
            }
        }
    }
}

struct FullScheduleMatchRow: View {
    let match: Match
    let standings: [TeamStanding]
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            VStack(spacing: 2) {
                Text(timeString)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if match.isCompleted {
                    Text("Final")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Upcoming")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 60)
            
            Divider()
            
            // Match Info
            VStack(spacing: 8) {
                HStack {
                    Image(match.team1Logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    
                    Text(match.team1Name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if let score = match.team1Score {
                        // Show score for completed matches
                        Text("\(score)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(for: match.team1Name))
                    } else if let record = getTeamRecord(teamName: match.team1Name) {
                        // Show record for upcoming matches
                        Text(record)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Image(match.team2Logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    
                    Text(match.team2Name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if let score = match.team2Score {
                        // Show score for completed matches
                        Text("\(score)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(for: match.team2Name))
                    } else if let record = getTeamRecord(teamName: match.team2Name) {
                        // Show record for upcoming matches
                        Text(record)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: match.date)
    }
    
    private func scoreColor(for team: String) -> Color {
        guard match.isCompleted,
              let score1 = match.team1Score,
              let score2 = match.team2Score else {
            return .primary
        }
        
        if team == match.team1Name {
            return score1 > score2 ? .green : .red
        } else {
            return score2 > score1 ? .green : .red
        }
    }
    
    private func getTeamRecord(teamName: String) -> String? {
        guard let team = standings.first(where: { $0.name == teamName }) else {
            return nil
        }
        return "\(team.matchWins) - \(team.matchLosses)"
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
            .preferredColorScheme(.dark)
    }
}
