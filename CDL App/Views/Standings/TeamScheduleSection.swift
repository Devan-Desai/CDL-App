//
//  TeamScheduleSection.swift
//  CDL App
//
//  The Upcoming / Completed match list shown inside TeamDetailView.
//  (Moved out of ScheduleScraperService.swift — views live in Views/.)
//

import SwiftUI

// MARK: - Team Detail Schedule Section
struct TeamScheduleSection: View {
    let team: TeamStanding
    @StateObject var scheduleScraper = ScheduleScraperService()
    @State private var selectedTab: ScheduleTab = .upcoming
    
    enum ScheduleTab {
        case upcoming, completed
    }
    
    var displayedMatches: [Match] {
        switch selectedTab {
        case .upcoming:
            return scheduleScraper.upcomingMatchesForTeam(team.name)
        case .completed:
            return scheduleScraper.completedMatchesForTeam(team.name)
        }
    }
    
    var body: some View {
        Section(header: Text("Team Schedule")) {
            VStack(spacing: 0) {
                // Tab Selector
                HStack(spacing: 0) {
                    Button(action: {
                        withAnimation {
                            selectedTab = .upcoming
                        }
                    }) {
                        Text("Upcoming")
                            .fontWeight(selectedTab == .upcoming ? .bold : .regular)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(selectedTab == .upcoming ? .white : .primary)
                    }
                    .background(selectedTab == .upcoming ? team.color : Color.clear)
                    
                    Divider()
                    
                    Button(action: {
                        withAnimation {
                            selectedTab = .completed
                        }
                    }) {
                        Text("Completed")
                            .fontWeight(selectedTab == .completed ? .bold : .regular)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(selectedTab == .completed ? .white : .primary)
                    }
                    .background(selectedTab == .completed ? team.color : Color.clear)
                }
                
                Divider()
                
                // Matches List
                if scheduleScraper.matches.isEmpty {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                        Text("Loading schedule...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else if displayedMatches.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No \(selectedTab == .upcoming ? "upcoming" : "completed") matches")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(displayedMatches) { match in
                        MatchRowView(match: match, teamName: team.name)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .onAppear {
            scheduleScraper.fetchSchedule()
        }
    }
}

struct MatchRowView: View {
    let match: Match
    let teamName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Team 1
                HStack(spacing: 8) {
                    Image(match.team1Logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(TeamTheme.theme(for: match.team1Name).shortName)
                            .font(.subheadline)
                            .fontWeight(match.team1Name == teamName ? .bold : .regular)
                            .foregroundColor(TeamTheme.theme(for: match.team1Name).color)
                        
                        if let score = match.team1Score {
                            Text("\(score)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(winnerColor(team: match.team1Name))
                        }
                    }
                }
                
                Spacer()
                
                // VS or Score Separator
                Text(match.isCompleted ? "-" : "VS")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Team 2
                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(TeamTheme.theme(for: match.team2Name).shortName)
                            .font(.subheadline)
                            .fontWeight(match.team2Name == teamName ? .bold : .regular)
                            .foregroundColor(TeamTheme.theme(for: match.team2Name).color)
                        
                        if let score = match.team2Score {
                            Text("\(score)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(winnerColor(team: match.team2Name))
                        }
                    }
                    
                    Image(match.team2Logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(match.shortDisplayDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func winnerColor(team: String) -> Color {
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
}
