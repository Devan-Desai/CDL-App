//
//  DataCache.swift
//  CDL App
//
//  Saves the last good copy of our data on the phone, so the app opens instantly,
//  works offline, and keeps showing something if the CDL site has a bad moment.
//
//  Each kind of data gets one small JSON file:  teams.json, standings.json, schedule.json
//

import Foundation

enum DataCache {

    /// Where the files live: the app's Caches folder. iOS may empty it if the phone
    /// runs very low on space — that's fine, we'd just download again.
    private static func fileURL(for name: String) -> URL {
        URL.cachesDirectory.appending(path: "\(name).json")
    }

    /// Save anything that can be turned into JSON — [Team], [TeamStanding], [Match], …
    ///
    /// The `<T: Encodable>` part makes this a "generic" function: instead of writing
    /// saveTeams(), saveStandings() and saveMatches(), one function works for ANY type T,
    /// as long as T is Encodable (knows how to turn itself into JSON).
    static func save<T: Encodable>(_ value: T, as name: String) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: fileURL(for: name), options: .atomic)   // .atomic = never leave a half-written file
        } catch {
            print("⚠️ [Cache] Couldn't save \(name): \(error)")
        }
    }

    /// Load what was saved last time. Returns nil if nothing's been saved yet (first launch),
    /// or if the file no longer matches our model (e.g. we added a property since).
    ///
    /// Usage:  DataCache.load([Team].self, from: "teams")
    ///         `[Team].self` means "the type [Team] itself" — it tells the function what to rebuild.
    static func load<T: Decodable>(_ type: T.Type, from name: String) -> T? {
        guard let data = try? Data(contentsOf: fileURL(for: name)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// When a file was last saved — handy for "last updated" labels.
    static func savedDate(of name: String) -> Date? {
        let path = fileURL(for: name).path(percentEncoded: false)
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        return attributes?[.modificationDate] as? Date
    }
}
