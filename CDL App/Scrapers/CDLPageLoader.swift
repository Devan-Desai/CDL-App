//
//  CDLPageLoader.swift
//  CDL App
//
//  Every page on callofdutyleague.com is built with Next.js, which tucks ALL of
//  the page's data into one big JSON blob: <script id="__NEXT_DATA__">…</script>.
//  This helper downloads a page and hands back just that JSON, so each scraper
//  only has to worry about decoding.
//

import Foundation
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

    /// path: the part after /en-us/, e.g. "teams", "standings", "schedule", "match/13100"
    static func nextData(path: String) async throws -> Data {
        let url = URL(string: "https://www.callofdutyleague.com/en-us/\(path)")!

        // `await` = "pause here until the download finishes, without freezing the app".
        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw LoadError.badStatus(http.statusCode)
        }

        let html = String(decoding: data, as: UTF8.self)
        let doc = try SwiftSoup.parse(html)
        guard let script = try doc.select("script#__NEXT_DATA__").first() else {
            throw LoadError.noNextData
        }
        return Data(script.data().utf8)
    }
}
