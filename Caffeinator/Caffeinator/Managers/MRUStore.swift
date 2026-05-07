//
//  MRUStore.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/7/26.
//

import Foundation

@MainActor
class MRUStore {

    let maxEntries = 3
    private(set) var entries: [MRUEntry]
    private let persistence: SettingsPersistenceManager

    init(persistence: SettingsPersistenceManager) {
        self.persistence = persistence
        entries = persistence.mruEntries
    }

    func record(_ entry: MRUEntry) {
        entries.removeAll {
            $0 == entry
        }
        entries.insert(entry, at: 0)

        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }

        persistence.mruEntries = entries
    }
}
