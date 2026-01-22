//
//  ScheduleScraperService.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-15.
//

import Foundation
import SwiftSoup
import Combine
import SwiftUI

class ScheduleScraperService: ObservableObject {
    @Published var matches: [Match] = []
    
    func fetchSchedule() {
        guard let url = URL(string: "https://callofdutyleague.com/en-us/schedule") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let html = String(data: data, encoding: .utf8) else { return }

            do {
                let doc: Document = try SwiftSoup.parse(html)
                guard let scriptTag = try doc.select("script#__NEXT_DATA__").first() else { return }
                
                let jsonData = scriptTag.data().data(using: .utf8)!
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let decoded = try decoder.decode(CDLScheduleResponse.self, from: jsonData)
                
                var allMatches: [Match] = []
                var seenMatchIds = Set<String>()
                
                // First, get ALL matches from the detailed schedule data (both completed and upcoming)
                if let containerBlock = decoded.props.pageProps.blocks.first(where: { $0.cdlContainerBlockList != nil }),
                   let items = containerBlock.cdlContainerBlockList?.items.first(where: { $0.default == true }),
                   let tabBlocks = items.blocks,
                   let tabsBlock = tabBlocks.first(where: { $0.tabs != nil }),
                   let tabs = tabsBlock.tabs?.tabs.first(where: { $0.openDefault == true }),
                   let scheduleBlocks = tabs.blocks,
                   let entireSeasonBlock = scheduleBlocks.first(where: { $0.cdlEntireSeasonMatchCards != nil }) {
                    
                    let matchCards = entireSeasonBlock.cdlEntireSeasonMatchCards
                    
                    // Process completed matches
                    if let completedData = matchCards?.completedMatches {
                        for section in completedData {
                            for matchEntry in section.matches {
                                let matchId = "\(matchEntry.match.id)"
                                
                                if !seenMatchIds.contains(matchId) {
                                    seenMatchIds.insert(matchId)
                                    
                                    let team1Name = matchEntry.homeTeamCard.name
                                    let team2Name = matchEntry.awayTeamCard.name
                                    let team1Score = matchEntry.result?.homeTeamGamesWon
                                    let team2Score = matchEntry.result?.awayTeamGamesWon
                                    
                                    allMatches.append(Match(
                                        id: matchId,
                                        team1Name: team1Name,
                                        team2Name: team2Name,
                                        team1Logo: TeamTheme.theme(for: team1Name).logo,
                                        team2Logo: TeamTheme.theme(for: team2Name).logo,
                                        team1Score: team1Score,
                                        team2Score: team2Score,
                                        date: Date(timeIntervalSince1970: TimeInterval(matchEntry.match.playTime)),
                                        isCompleted: matchEntry.match.status == "COMPLETED",
                                        matchTitle: nil
                                    ))
                                }
                            }
                        }
                    }
                    
                    // Process upcoming matches
                    if let upcomingData = matchCards?.upcomingMatches {
                        for section in upcomingData {
                            for matchEntry in section.matches {
                                let matchId = "\(matchEntry.match.id)"
                                
                                if !seenMatchIds.contains(matchId) {
                                    seenMatchIds.insert(matchId)
                                    
                                    let team1Name = matchEntry.homeTeamCard.name
                                    let team2Name = matchEntry.awayTeamCard.name
                                    
                                    allMatches.append(Match(
                                        id: matchId,
                                        team1Name: team1Name,
                                        team2Name: team2Name,
                                        team1Logo: TeamTheme.theme(for: team1Name).logo,
                                        team2Logo: TeamTheme.theme(for: team2Name).logo,
                                        team1Score: nil,
                                        team2Score: nil,
                                        date: Date(timeIntervalSince1970: TimeInterval(matchEntry.match.playTime)),
                                        isCompleted: false,
                                        matchTitle: nil
                                    ))
                                }
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.matches = allMatches.sorted { $0.date > $1.date }
                    print("✅ Loaded \(self.matches.count) total matches (\(self.matches.filter { $0.isCompleted }.count) completed, \(self.matches.filter { !$0.isCompleted }.count) upcoming)")
                }
            } catch {
                print("❌ Schedule decoding error: \(error)")
            }
        }.resume()
    }
    
    // Get matches for a specific team
    func matchesForTeam(_ teamName: String) -> [Match] {
        matches.filter { match in
            match.team1Name == teamName || match.team2Name == teamName
        }
    }
    
    // Get completed matches for a team (sorted newest first)
    func completedMatchesForTeam(_ teamName: String) -> [Match] {
        matchesForTeam(teamName)
            .filter { $0.isCompleted }
            .sorted { $0.date > $1.date }
    }
    
    // Get upcoming matches for a team (sorted soonest first)
    func upcomingMatchesForTeam(_ teamName: String) -> [Match] {
        matchesForTeam(teamName)
            .filter { !$0.isCompleted }
            .sorted { $0.date < $1.date }
    }
}

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

// MARK: - Schedule Response Models
struct CDLScheduleResponse: Codable {
    let props: CDLScheduleProps
}

struct CDLScheduleProps: Codable {
    let pageProps: CDLSchedulePageProps
}

struct CDLSchedulePageProps: Codable {
    let blocks: [CDLScheduleBlock]
}

struct CDLScheduleBlock: Codable {
    let cdlHeader: CDLScheduleHeader?
    let cdlContainerBlockList: CDLScheduleContainerBlockList?
    let tabs: CDLScheduleTabs?
    let cdlEntireSeasonMatchCards: CDLEntireSeasonMatchCards?
}

struct CDLScheduleContainerBlockList: Codable {
    let items: [CDLScheduleContainerItem]
}

struct CDLScheduleContainerItem: Codable {
    let `default`: Bool
    let blocks: [CDLScheduleBlock]?
}

struct CDLScheduleTabs: Codable {
    let tabs: [CDLScheduleTab]
}

struct CDLScheduleTab: Codable {
    let openDefault: Bool
    let blocks: [CDLScheduleBlock]?
}

struct CDLEntireSeasonMatchCards: Codable {
    let upcomingMatches: [CDLMatchSection]?
    let completedMatches: [CDLMatchSection]?
}

struct CDLMatchSection: Codable {
    let matches: [CDLDetailedMatch]
}

struct CDLDetailedMatch: Codable {
    let homeTeamCard: CDLTeamCard
    let awayTeamCard: CDLTeamCard
    let match: CDLMatchInfo
    let result: CDLMatchResult?
}

struct CDLMatchResult: Codable {
    let homeTeamGamesWon: Int?
    let awayTeamGamesWon: Int?
}

struct CDLTeamCard: Codable {
    let name: String
}

struct CDLMatchInfo: Codable {
    let id: Int
    let playTime: Int
    let status: String
}

struct CDLScheduleHeader: Codable {
    let scoreStripList: CDLScoreStripList?
}

struct CDLScoreStripList: Codable {
    let scoreStrip: CDLScoreStrip?
}

struct CDLScoreStrip: Codable {
    let matches: [CDLMatchData]?
}

struct CDLMatchData: Codable {
    let status: String
    let link: String
    let date: CDLMatchDate
    let competitors: [CDLCompetitor]
}

struct CDLMatchDate: Codable {
    let startTime: Int
}

struct CDLCompetitor: Codable {
    let longName: String
    let score: Int?
}

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
                    .background(selectedTab == .upcoming ? Color.orange : Color.clear)
                    
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
                    .background(selectedTab == .completed ? Color.orange : Color.clear)
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
