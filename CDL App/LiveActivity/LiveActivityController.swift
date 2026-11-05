//
//  LiveActivityController.swift
//  CDL App
//
//  Starts, updates and ends the match Live Activity (the Lock Screen scoreboard).
//
//  Two ways to drive it:
//   • follow(matchId:) — a REAL match: re-reads the CDL match page every 30 seconds and
//     pushes the new score to the Lock Screen. Ends by itself when the match is final.
//   • replay(matchId:) — a FINISHED match played back map by map, so we can test the
//     Live Activity with real data before the season starts.
//
//  Limitation (on purpose, for now): following only works while the app is open.
//  iOS pauses apps shortly after you leave them, so the app can't keep checking the
//  CDL site in the background. Updates with the app closed need a server that sends
//  push notifications — that's Phase 4 of the roadmap.
//

import Foundation
import ActivityKit
import Combine

class LiveActivityController: ObservableObject {
    @Published private(set) var followedMatchId: Int?   // the match being followed, if any
    @Published private(set) var isReplaying = false
    @Published private(set) var status: String?         // a line of text for the screen

    private var work: Task<Void, Never>?                // the running follow/replay loop

    // MARK: Follow a real match

    func follow(matchId: Int, teams: TeamsScraperService) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            status = "Live Activities are turned off for this app in Settings."
            return
        }
        startFresh()
        followedMatchId = matchId
        status = "Starting…"

        work = Task {
            var activity: Activity<CDLAttributes>?
            while !Task.isCancelled {
                do {
                    let detail = try await MatchDetailService.fetch(matchId: matchId)
                    let state = Self.state(from: detail)
                    // If no new update arrives within 2 minutes (e.g. the app was closed),
                    // iOS marks the scoreboard as out of date.
                    let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(120))

                    if let activity {
                        await activity.update(content)
                    } else {
                        activity = try Activity<CDLAttributes>.request(
                            attributes: Self.attributes(for: detail, teams: teams),
                            content: content)
                    }

                    if detail.isFinal {
                        status = "Final: \(detail.team1.abbreviation) \(state.team1Maps)–\(state.team2Maps) \(detail.team2.abbreviation)"
                        await activity?.end(content, dismissalPolicy: .default)
                        break
                    }
                    status = "Following — last update \(Date().formatted(date: .omitted, time: .shortened))"
                } catch is CancellationError {
                    break
                } catch {
                    status = "Couldn't update: \(error.localizedDescription)"
                }
                try? await Task.sleep(for: .seconds(30))
            }
            if followedMatchId == matchId { followedMatchId = nil }
        }
    }

    // MARK: Replay a finished match (testing)

    func replay(matchId: Int, teams: TeamsScraperService) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            status = "Live Activities are turned off for this app in Settings."
            return
        }
        startFresh()
        isReplaying = true
        status = "Loading the match…"

        work = Task {
            do {
                let detail = try await MatchDetailService.fetch(matchId: matchId)
                let frames = Self.replayFrames(for: detail)
                guard let first = frames.first, let last = frames.last else {
                    status = "That match has no map results to replay."
                    isReplaying = false
                    return
                }
                let activity = try Activity<CDLAttributes>.request(
                    attributes: Self.attributes(for: detail, teams: teams),
                    content: ActivityContent(state: first, staleDate: nil))
                status = "Replaying \(detail.team1.abbreviation) vs \(detail.team2.abbreviation) — lock the phone to watch."

                for frame in frames.dropFirst() {
                    try await Task.sleep(for: .seconds(4))
                    await activity.update(ActivityContent(state: frame, staleDate: nil))
                }
                await activity.end(ActivityContent(state: last, staleDate: nil), dismissalPolicy: .default)
                status = "Replay finished."
            } catch is CancellationError {
                // stopped on purpose — nothing to report
            } catch {
                status = "Couldn't replay: \(error.localizedDescription)"
            }
            isReplaying = false
        }
    }

    // MARK: Stop

    func stop() {
        startFresh()
        status = nil
    }

    /// Cancels whatever was running and removes our scoreboards from the Lock Screen.
    private func startFresh() {
        work?.cancel()
        work = nil
        followedMatchId = nil
        isReplaying = false
        let running = Activity<CDLAttributes>.activities
        Task {
            for activity in running {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    // MARK: Match page → Live Activity data

    /// The fixed part: each team's abbreviation, color and logo.
    static func attributes(for detail: MatchDetail, teams: TeamsScraperService) -> CDLAttributes {
        CDLAttributes(matchId: detail.id,
                      team1: side(for: detail.team1, teams: teams),
                      team2: side(for: detail.team2, teams: teams))
    }

    private static func side(for side: MatchDetail.Side, teams: TeamsScraperService) -> CDLAttributes.Side {
        // Prefer the teams page (same abbreviations/colors as the rest of the app), else the match page.
        let team = teams.team(withId: side.id)
        return CDLAttributes.Side(
            abbreviation: team?.abbreviation ?? side.abbreviation,
            colorHex: team?.primaryColorHex ?? side.colorHex ?? "#8E8E93",
            logoAsset: TeamLogos.assetName(forTeamId: side.id))
    }

    /// The changing part: series score + the map being played (or the last one, once it's over).
    static func state(from detail: MatchDetail) -> CDLAttributes.ContentState {
        let map = detail.currentMap ?? detail.playedMaps.last
        return CDLAttributes.ContentState(
            team1Maps: detail.team1MapsWon,
            team2Maps: detail.team2MapsWon,
            mapNumber: map?.number ?? 0,
            mapName: map?.mapName ?? "",
            modeName: map?.mode ?? "",
            shortMode: map?.shortMode ?? "",
            team1MapScore: map?.team1Score,
            team2MapScore: map?.team2Score,
            isFinal: detail.isFinal)
    }

    /// A finished match as a little "film": for every map — kick-off, halfway, final score.
    /// LAT 3–1 MIA (4 maps) becomes 13 frames, about 50 seconds at 4 seconds each.
    static func replayFrames(for detail: MatchDetail) -> [CDLAttributes.ContentState] {
        var frames: [CDLAttributes.ContentState] = []
        var won1 = 0
        var won2 = 0
        for map in detail.playedMaps {
            let final1 = map.team1Score ?? 0
            let final2 = map.team2Score ?? 0
            let steps = [(0, 0), (final1 / 2, final2 / 2), (final1, final2)]   // kick-off, halfway, final
            for (step, scores) in steps.enumerated() {
                if step == 2 {   // the map just ended → count it in the series score
                    if map.winnerTeamId == detail.team1.id { won1 += 1 }
                    if map.winnerTeamId == detail.team2.id { won2 += 1 }
                }
                frames.append(CDLAttributes.ContentState(
                    team1Maps: won1,
                    team2Maps: won2,
                    mapNumber: map.number,
                    mapName: map.mapName ?? "",
                    modeName: map.mode ?? "",
                    shortMode: map.shortMode,
                    team1MapScore: scores.0,
                    team2MapScore: scores.1,
                    isFinal: false))
            }
        }
        if var ending = frames.last {
            ending.isFinal = true
            frames.append(ending)
        }
        return frames
    }
}
