//
//  TeamsScraperService.swift
//  CDL App
//
//  Scrapes https://www.callofdutyleague.com/en-us/teams and turns it into [Team].
//  Replaces the hard-coded list in TeamTheme.swift (which still says "Boston Breach").
//

import Foundation
import Combine

class TeamsScraperService: ObservableObject {
    @Published var teams: [Team] = []
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?

    /// Quick lookup by CDL team ID: teamsByID[17] → Toronto KOI
    var teamsByID: [Int: Team] {
        Dictionary(teams.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// The team with this ID — or nil for a TBD team (no ID yet) or an ID we don't know.
    /// Example:  team(withId: 17)?.abbreviation  →  "TOR"
    func team(withId id: Int?) -> Team? {
        guard let id else { return nil }
        return teamsByID[id]
    }

    func fetchTeams() async {
        // 1️⃣ Show the copy saved last time straight away, so the screen isn't empty
        //    while we download (and still has teams if we're offline).
        //    Only when nothing is on screen yet — no point replacing fresher data.
        if teams.isEmpty, let saved = DataCache.load([Team].self, from: "teams") {
            teams = saved
            lastUpdated = DataCache.savedDate(of: "teams")
            print("📦 [Teams] Showing \(saved.count) saved teams while downloading fresh ones")
        }

        do {
            let json = try await CDLPageLoader.nextData(path: "teams")
            let page = try JSONDecoder().decode(CDLTeamsPage.self, from: json)

            // Find the team-list block wherever it sits on the page,
            // instead of assuming it is always block number 1.
            guard let teamList = page.props.pageProps.blocks.compactMap({ $0.cdlTeamListV3 }).first else {
                errorMessage = "Couldn't find the team list on the CDL page (the site may have changed)."
                print("❌ [Teams] no cdlTeamListV3 block found")
                return
            }

            teams = teamList.teams
                .map { $0.toTeam() }
                .sorted { $0.fullName < $1.fullName }
            lastUpdated = Date()
            errorMessage = nil

            // 2️⃣ Save the fresh copy for next time.
            DataCache.save(teams, as: "teams")

            print("✅ [Teams] Loaded \(teams.count) teams")
            for team in teams {
                let roster = team.roster.map(\.alias).joined(separator: ", ")
                print("   #\(team.id) \(team.abbreviation) \(team.fullName) \(team.primaryColorHex) — \(roster)")
            }
        } catch {
            // 3️⃣ If saved teams are already on screen, a failed refresh isn't a disaster —
            //    say so gently instead of showing a scary error.
            errorMessage = teams.isEmpty
                ? "Couldn't load teams: \(error.localizedDescription)"
                : "Couldn't refresh — showing saved teams."
            print("❌ [Teams] \(error)")
        }
    }
}

// MARK: - Raw JSON from the CDL teams page
// These structs mirror the website's JSON exactly. We only list the fields we use;
// JSONDecoder silently ignores everything else.
// Path:  props → pageProps → blocks[] → cdlTeamListV3 → teams[]

struct CDLTeamsPage: Decodable {
    let props: Props

    struct Props: Decodable { let pageProps: PageProps }
    struct PageProps: Decodable { let blocks: [Block] }
    struct Block: Decodable { let cdlTeamListV3: TeamList? }   // nil for every other kind of block
    struct TeamList: Decodable { let teams: [CDLRawTeam] }
}

struct CDLRawTeam: Decodable {
    let teamId: Int                  // 17
    let fullTeamName: String         // "Toronto KOI"
    let teamLocation: String         // "Toronto"
    let teamName: String             // "KOI"
    let teamAbbreviatedName: String  // "TOR"
    let teamColors: [RawColor]
    let teamIcons: [RawIcon]
    let roster: [RawPlayer]
    // (There is also a `primaryColor` field like "rgba(120,44,242,1)", but it's wrong
    //  for at least one team — FaZe's says white. teamColors is more reliable.)

    struct RawColor: Decodable {
        let teamColorUsage: String   // "Primary", "Secondary", "Home Color Primary"
        let teamColorValue: String   // "#782CF2"
    }
    struct RawIcon: Decodable {
        let teamIconUsage: String    // "Default", "Alternate", "Match Page", ...
        let teamIconSvg: RawImage?
    }
    struct RawImage: Decodable {
        let src: String
    }
    struct RawPlayer: Decodable {
        let id: Int
        let alias: String
        let firstName: String
        let lastName: String
        let role: String?            // optional: some people have no role listed
        let headshotPhotoUrl: String?
    }
}

// MARK: - Raw → clean conversion

extension CDLRawTeam {
    func toTeam() -> Team {
        
        // Team Color:
        let colorHex = teamColors.first (where: { $0.teamColorUsage == "Primary"})?.teamColorValue ?? "#FFFFFF"
        let players: [Player] = roster
            .filter { $0.role == "Player" || $0.role == "Substitute" || $0.role == nil}
            .map { raw in
                Player(id: raw.id,
                       alias: raw.alias,
                       firstName: raw.firstName,
                       lastName: raw.lastName,
                       role: raw.role,
                       headshotURL: raw.headshotPhotoUrl.flatMap { URL(string: $0) })
            }

        // Logo:
        let logo = teamIcons.first(where: { $0.teamIconUsage == "Default" })?.teamIconSvg?.src

        return Team(
            id: teamId,
            fullName: fullTeamName,
            location: teamLocation,
            name: teamName,
            abbreviation: teamAbbreviatedName,
            primaryColorHex: colorHex,
            logoURL: logo.flatMap { URL(string: $0) },
            roster: players
        )
    }
}
