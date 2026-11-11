//
//  SnapshotRecorder.swift
//  CDL App
//
//  The Kickoff weekend recorder (Dec 4–6). Three things about LIVE matches are still
//  unknown (docs/ROADMAP.md §2): the status word, whether the current map shows a score
//  while it's played, and how fresh the pages are. This saves exactly what the site
//  sends while you follow a match, so we can study it afterwards.
//
//  How it works: when the switch is on, the follow loop (LiveActivityController) hands
//  every match page it ALREADY downloads every 30 s to `saveMatchPage`. No extra
//  requests for the match. Every 4th time (~2 min) it also saves the schedule page.
//
//  Where the files go — Files app → On My iPhone → CDL App → Snapshots:
//
//    Snapshots/
//      match-13100/
//        log.csv                       one line per save (read this first)
//        2026-12-04_15-03-30.json      the page's raw JSON, exactly as sent
//        …
//      schedule/
//        log.csv
//        2026-12-04_15-04-30.json
//

import Foundation

enum SnapshotRecorder {

    /// The on/off switch, stored in the phone's settings (UserDefaults).
    /// The Live tab's toggle uses the same key with @AppStorage.
    static let settingKey = "recordSnapshots"
    static var isOn: Bool { UserDefaults.standard.bool(forKey: settingKey) }

    /// The app's Documents folder is what the Files app shows (Info.plist: UIFileSharingEnabled).
    static var folder: URL { URL.documentsDirectory.appending(path: "Snapshots") }

    // MARK: Saving

    /// One match page. `result` is what our decoder made of it: a MatchDetail, or the error
    /// (pages we can't read are the most interesting ones to keep!).
    static func saveMatchPage(_ page: CDLPageLoader.Page, matchId: Int, result: Result<MatchDetail, Error>) {
        let summary: [String]
        switch result {
        case .success(let detail):
            summary = [detail.status,
                       "\(detail.team1MapsWon)-\(detail.team2MapsWon)",
                       detail.currentMap.map { "\($0.number)" } ?? "",
                       mapsColumn(detail),
                       ""]
        case .failure(let error):
            summary = ["", "", "", "", error.localizedDescription]
        }
        save(page, in: "match-\(matchId)",
             header: ["status", "series", "current_map", "maps", "error"],
             columns: summary)
    }

    /// The schedule page. Only the raw copy and its freshness; we'll read it afterwards.
    static func saveSchedulePage(_ page: CDLPageLoader.Page) {
        save(page, in: "schedule", header: [], columns: [])
    }

    /// "1:250-137* 2:3-6* 3:41-38" — every map slot with a score; * = has a winner.
    /// A score WITHOUT a * is the thing we're hoping to see: a live map score.
    private static func mapsColumn(_ detail: MatchDetail) -> String {
        detail.maps
            .filter { $0.team1Score != nil || $0.team2Score != nil }
            .map { map in
                let s1 = map.team1Score.map(String.init) ?? "?"
                let s2 = map.team2Score.map(String.init) ?? "?"
                return "\(map.number):\(s1)-\(s2)\(map.winnerTeamId != nil ? "*" : "")"
            }
            .joined(separator: " ")
    }

    /// Writes the raw JSON file and adds a line to that folder's log.csv.
    private static func save(_ page: CDLPageLoader.Page, in subfolder: String, header: [String], columns: [String]) {
        let dir = folder.appending(path: subfolder)
        let fileName = fileNameFormatter.string(from: page.downloadedAt) + ".json"
        let log = dir.appending(path: "log.csv")

        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try page.json.write(to: dir.appending(path: fileName), options: .atomic)

            // First save in this folder → start the CSV with column names.
            if !FileManager.default.fileExists(atPath: log.path(percentEncoded: false)) {
                let names = ["saved_at", "file", "cdn_cache", "cdn_age_s"] + header
                try (names.joined(separator: ",") + "\n").write(to: log, atomically: true, encoding: .utf8)
            }
            let line = [timeFormatter.string(from: page.downloadedAt),   // phone's time + UTC offset, e.g. 2026-12-04T15:03:30-05:00
                        fileName,
                        page.cacheStatus ?? "",
                        page.ageSeconds.map(String.init) ?? ""] + columns
            try appendLine(line.map(csvField).joined(separator: ","), to: log)
        } catch {
            print("⚠️ [Recorder] Couldn't save a snapshot: \(error)")
        }
    }

    private static func appendLine(_ line: String, to file: URL) throws {
        let handle = try FileHandle(forWritingTo: file)
        defer { try? handle.close() }        // `defer` = run this when the function exits, whatever happens
        try handle.seekToEnd()
        try handle.write(contentsOf: Data((line + "\n").utf8))
    }

    /// CSV fields with commas or quotes must be wrapped in quotes ("a, b" → "\"a, b\"").
    private static func csvField(_ text: String) -> String {
        guard text.contains(",") || text.contains("\"") || text.contains("\n") else { return text }
        return "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")   // fixed format, whatever the phone's language
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()

    private static let timeFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        return formatter
    }()

    // MARK: For the Live tab

    /// How many pages are saved, and how much space they take.
    static func totals() -> (files: Int, bytes: Int) {
        guard let items = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [.fileSizeKey]) else {
            return (0, 0)
        }
        var files = 0
        var bytes = 0
        for case let url as URL in items where url.pathExtension == "json" {
            files += 1
            bytes += (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        }
        return (files, bytes)
    }

    static func deleteAll() {
        try? FileManager.default.removeItem(at: folder)
    }
}
