//
//  CDLPageLoader.swift
//  CDL App
//
//  Every page on callofdutyleague.com is built with Next.js, which tucks ALL of
//  the page's data into one big JSON blob: <script id="__NEXT_DATA__">…</script>.
//  This helper downloads a page and hands back just that JSON, so each scraper
//  only has to worry about decoding.
//
//  About freshness (checked Nov 11): the site answers with `cache-control: max-age=180`.
//  • Its delivery network (CloudFront) may hand out a copy up to 3 minutes old. The
//    `age` header says how old (e.g. "age: 9" = 9 s), `x-cache` says "Hit" or "Miss".
//    We can't skip that politely, so we just note it (see `Page`).
//  • The phone would ALSO keep its own copy for 3 minutes and not even ask the site.
//    That's why every request below says `.reloadIgnoringLocalCacheData`.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking   // on Linux (where the server may run one day) URLSession lives here
#endif
import SwiftSoup

enum CDLPageLoader {

    enum LoadError: LocalizedError {
        case badStatus(Int)
        case noNextData

        var errorDescription: String? {
            switch self {
            case .badStatus(let code): return "The CDL site answered with HTTP \(code)."
            case .noNextData:          return "The page didn't contain the __NEXT_DATA__ block we read."
            }
        }
    }

    /// One downloaded page: its JSON plus a few facts about how fresh it is.
    struct Page {
        let json: Data
        let downloadedAt: Date
        let ageSeconds: Int?      // how long the delivery network had kept this copy (nil = straight from the site)
        let cacheStatus: String?  // "Hit from cloudfront" / "Miss from cloudfront"
    }

    /// path: the part after /en-us/, e.g. "teams", "standings", "schedule", "match/13100"
    static func nextData(path: String) async throws -> Data {
        try await page(path: path).json
    }

    /// Same as `nextData`, but keeps the freshness facts (used by the Kickoff recorder).
    static func page(path: String) async throws -> Page {
        let url = URL(string: "https://www.callofdutyleague.com/en-us/\(path)")!
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData   // always ask the site, never the phone's copy

        // `await` = "pause here until the download finishes, without freezing the app".
        let (data, response) = try await URLSession.shared.data(for: request)

        let http = response as? HTTPURLResponse
        if let http, http.statusCode != 200 {
            throw LoadError.badStatus(http.statusCode)
        }

        let html = String(decoding: data, as: UTF8.self)
        let doc = try SwiftSoup.parse(html)
        guard let script = try doc.select("script#__NEXT_DATA__").first() else {
            throw LoadError.noNextData
        }
        return Page(json: Data(script.data().utf8),
                    downloadedAt: Date(),
                    ageSeconds: (http?.value(forHTTPHeaderField: "age")).flatMap { Int($0) },
                    cacheStatus: http?.value(forHTTPHeaderField: "x-cache"))
    }
}
