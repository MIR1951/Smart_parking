//
//  FavoritesStore.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 24/01/26.
//


import Foundation
internal import Combine

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var ids: Set<UUID> = []

    private let key = "favorite_parking_ids_v1"

    init() {
        load()
    }

    func isFavorite(_ id: UUID) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: UUID) {
        if ids.contains(id) { ids.remove(id) }
        else { ids.insert(id) }
        save()
    }

    func remove(_ id: UUID) {
        ids.remove(id)
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let arr = UserDefaults.standard.array(forKey: key) as? [String] else { return }
        ids = Set(arr.compactMap { UUID(uuidString: $0) })
    }

    private func save() {
        let arr = ids.map { $0.uuidString }
        UserDefaults.standard.set(arr, forKey: key)
    }
}
