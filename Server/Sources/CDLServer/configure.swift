//
//  configure.swift
//  CDLServer
//
//  The server's addresses ("routes") — what you get when you open each URL:
//
//    GET /                      a hello line, to check it's running
//    GET /matches/13100         the match, as our own clean JSON (MatchJSON.swift)
//    GET /matches/13100/live    exactly the Live Activity's ContentState —
//                               the same JSON a push update will carry in Phase 4
//

import Vapor

func configure(_ app: Application) async throws {
    // Dates as text ("2026-12-04T20:00:00Z") instead of Apple's seconds-since-2001.
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    ContentConfiguration.global.use(encoder: encoder, for: .json)

    // One store for the whole server: every phone asking about match 13100 gets the
    // same copy, so the CDL site is asked once a minute, not once per phone.
    let store = MatchStore(logger: app.logger)

    // The poller: keeps matches that phones are watching up to date on its own.
    // (A Task is work that runs alongside everything else — like the app's follow loop.)
    Task { await store.runPoller() }

    app.get { _ in
        "CDL server is running. Try /matches/13100 or /matches/13100/live\n"
    }

    app.get("matches", ":id") { req async throws -> MatchJSON in
        let entry = try await store.entry(for: try matchId(req))
        return MatchJSON(entry: entry)
    }

    app.get("matches", ":id", "live") { req async throws -> CDLAttributes.ContentState in
        let entry = try await store.entry(for: try matchId(req))
        return CDLAttributes.ContentState(detail: entry.detail)   // the app's own code
    }
}

/// The ":id" part of the URL as a number, or a "400 Bad Request" answer.
private func matchId(_ req: Request) throws -> Int {
    guard let id = req.parameters.get("id", as: Int.self) else {
        throw Abort(.badRequest, reason: "The match ID must be a number, e.g. /matches/13100")
    }
    return id
}

/// Lets Vapor send a ContentState as JSON. (`Content` = Vapor's "can be a request or answer body".)
extension CDLAttributes.ContentState: Content {}
