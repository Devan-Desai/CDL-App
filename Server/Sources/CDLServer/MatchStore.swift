//
//  MatchStore.swift
//  CDLServer
//
//  Keeps the latest copy of each match the server has been asked about, and decides
//  when to download it again from the CDL site.
//
//  Rules (be gentle with the site — CLAUDE.md rule 7):
//   • A live or upcoming match is downloaded at most once a minute. The site's own copies
//     can be up to 3 minutes old anyway (cache-control: max-age=180, see ROADMAP §2).
//   • A finished match: at most once an hour (only the VOD link might still appear).
//   • The poller only refreshes matches someone asked about in the last 10 minutes.
//
//  It's an `actor`: a class that handles one caller at a time. Many phones can ask at
//  the same moment, and this stops them from tripping over the shared `entries`.
//

import Vapor

actor MatchStore {

    struct Entry {
        let detail: MatchDetail          // the app's own model
        let page: CDLPageLoader.Page     // the raw download + how fresh it was
        var lastAsked: Date              // when a phone last asked for this match
    }

    static let liveRefresh: TimeInterval = 60
    static let finalRefresh: TimeInterval = 60 * 60
    static let watchFor: TimeInterval = 10 * 60

    private var entries: [Int: Entry] = [:]
    /// Downloads in progress. If 50 phones ask at once, they all wait for ONE download.
    private var downloading: [Int: Task<Entry, Error>] = [:]
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    // MARK: Asked by a phone

    func entry(for id: Int) async throws -> Entry {
        if var saved = entries[id] {
            saved.lastAsked = Date()
            entries[id] = saved
            if !isDue(saved) { return saved }
        }
        do {
            return try await download(id)
        } catch MatchDetailService.DetailError.notAvailableYet {
            throw Abort(.notFound, reason: "The CDL hasn't published this match yet (teams not decided?).")
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.badGateway, reason: "Couldn't read the CDL page: \(error.localizedDescription)")
        }
    }

    private func isDue(_ entry: Entry) -> Bool {
        let maxAge = entry.detail.isFinal ? Self.finalRefresh : Self.liveRefresh
        return Date().timeIntervalSince(entry.page.downloadedAt) >= maxAge
    }

    // MARK: Downloading

    private func download(_ id: Int) async throws -> Entry {
        if let running = downloading[id] {
            return try await running.value
        }
        let task = Task { () async throws -> Entry in
            let page = try await CDLPageLoader.page(path: "match/\(id)")
            let detail = try MatchDetailService.detail(from: page.json)   // the app's own reader
            return Entry(detail: detail, page: page, lastAsked: Date())
        }
        downloading[id] = task
        defer { downloading[id] = nil }

        var fresh = try await task.value
        let previous = entries[id]
        fresh.lastAsked = previous?.lastAsked ?? fresh.lastAsked
        entries[id] = fresh
        reportChange(id: id, from: previous, to: fresh)
        return fresh
    }

    /// Compares the scoreboard before and after. A change is the moment a push update
    /// would be sent in Phase 4 — for now we just write it in the server's log.
    private func reportChange(id: Int, from old: Entry?, to new: Entry) {
        let before = old.map { CDLAttributes.ContentState(detail: $0.detail) }
        let after = CDLAttributes.ContentState(detail: new.detail)
        let age = new.page.ageSeconds.map { ", CDN copy \($0) s old" } ?? ""
        guard before != after else {
            logger.info("match \(id): no change\(age)")
            return
        }
        let d = new.detail
        let scoreboard = ["\(d.team1.abbreviation) \(after.team1Maps)–\(after.team2Maps) \(d.team2.abbreviation)",
                          after.statusLine, after.detailLine]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        logger.notice("\(before == nil ? "👀 first look at" : "📣") match \(id): \(scoreboard)\(age)")
        // TODO: Phase 4 — send `after` to the phones following match `id` (APNs Live Activity push).
    }

    // MARK: The poller

    /// Every 15 seconds: refresh the watched matches that are due. Runs until the server stops.
    func runPoller() async {
        while !Task.isCancelled {
            let now = Date()
            // Forget matches nobody has asked about for a while.
            entries = entries.filter { now.timeIntervalSince($0.value.lastAsked) < Self.watchFor || !$0.value.detail.isFinal }
            let due = entries.filter { !$0.value.detail.isFinal
                                       && now.timeIntervalSince($0.value.lastAsked) < Self.watchFor
                                       && isDue($0.value) }
            for id in due.keys {
                do { _ = try await download(id) }
                catch { logger.warning("match \(id): couldn't refresh — \(error.localizedDescription)") }
            }
            try? await Task.sleep(for: .seconds(15))
        }
    }
}
