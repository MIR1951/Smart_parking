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

    private let legacyKey = "favorite_parking_ids_v1"
    private let keyPrefix = "favorite_parking_ids_v2"
    private var currentUserID: String?
    private var scopedKey: String?

    init() {
        ids = []
    }

    func isFavorite(_ id: UUID) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: UUID) {
        guard scopedKey != nil else { return }
        if ids.contains(id) { ids.remove(id) }
        else { ids.insert(id) }
        save()
    }

    func remove(_ id: UUID) {
        guard scopedKey != nil else { return }
        ids.remove(id)
        save()
    }

    func setCurrentUserID(_ userID: String?) {
        guard currentUserID != userID else { return }
        currentUserID = userID

        guard let userID else {
            scopedKey = nil
            ids = []
            return
        }

        let newKey = "\(keyPrefix)_\(userID)"
        scopedKey = newKey
        migrateLegacyDataIfNeeded(to: newKey)
        load()
    }

    // MARK: - Persistence

    private func load() {
        guard let key = scopedKey else {
            ids = []
            return
        }
        guard let arr = UserDefaults.standard.array(forKey: key) as? [String] else {
            ids = []
            return
        }
        ids = Set(arr.compactMap { UUID(uuidString: $0) })
    }

    private func save() {
        guard let key = scopedKey else { return }
        let arr = ids.map { $0.uuidString }
        UserDefaults.standard.set(arr, forKey: key)
    }

    private func migrateLegacyDataIfNeeded(to key: String) {
        guard UserDefaults.standard.array(forKey: key) == nil else { return }
        guard let legacy = UserDefaults.standard.array(forKey: legacyKey) as? [String] else { return }
        UserDefaults.standard.set(legacy, forKey: key)
    }
}
