//
//  JSONFinder.swift
//  CDL App
//
//  Finds every value stored under a given key ANYWHERE in a JSON document,
//  however deeply it's nested.
//
//  Why: the CDL schedule page is tabs inside tabs inside tabs
//  (season → Major → tournament → "Match Schedule" → match list). Following one
//  exact path is what broke our old scraper when the site changed. Searching for
//  the key instead keeps working even if they move the tabs around.
//

import Foundation

enum JSONFinder {

    /// Returns each value found under `key`, re-packed as JSON Data so it can be
    /// handed straight to JSONDecoder.
    static func findAll(key: String, in json: Data) throws -> [Data] {
        let root = try JSONSerialization.jsonObject(with: json)
        var found: [Any] = []
        walk(root, key: key, into: &found)
        return try found.map { try JSONSerialization.data(withJSONObject: $0) }
    }

    /// Visits every dictionary and array in the tree (this function calls itself —
    /// that's called "recursion").
    private static func walk(_ node: Any, key: String, into found: inout [Any]) {
        if let dictionary = node as? [String: Any] {
            for (name, value) in dictionary {
                if name == key, value is [String: Any] || value is [Any] {
                    found.append(value)
                }
                walk(value, key: key, into: &found)
            }
        } else if let array = node as? [Any] {
            for item in array {
                walk(item, key: key, into: &found)
            }
        }
    }
}
