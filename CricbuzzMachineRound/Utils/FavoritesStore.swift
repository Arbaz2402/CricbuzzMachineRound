//
//  FavoritesStore.swift
//  CricbuzzMachineRound
//
//  Simple favorites persisting to UserDefaults
//

import Foundation
import Combine

protocol FavoritesStoring {
    func isFavorite(id: Int) -> Bool
    func toggleFavorite(id: Int)
    func all() -> Set<Int>
}

extension Notification.Name {
    static let favoritesChanged = Notification.Name("favoritesChanged")
}

final class FavoritesStore: FavoritesStoring {
    static let shared = FavoritesStore()

    private let key = "favorite_movie_ids"
    private let defaults: UserDefaults
    private var ids: Set<Int>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            self.ids = decoded
        } else {
            self.ids = []
        }
    }

    func isFavorite(id: Int) -> Bool { ids.contains(id) }

    func toggleFavorite(id: Int) {
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        persist()
        NotificationCenter.default.post(name: .favoritesChanged, object: nil)
    }

    func all() -> Set<Int> { ids }

    private func persist() {
        if let data = try? JSONEncoder().encode(ids) {
            defaults.set(data, forKey: key)
        }
    }
}
