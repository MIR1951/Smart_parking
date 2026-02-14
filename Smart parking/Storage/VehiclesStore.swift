//
//  VehiclesStore.swift
//  Smart parking
//
//  Foydalanuvchi mashinalarini boshqarish (UserDefaults)
//

import Foundation
internal import Combine
import SwiftUI


@MainActor
final class VehiclesStore: ObservableObject {
    static let shared = VehiclesStore()

    private let legacyKey = "user_vehicles"
    private let keyPrefix = "user_vehicles_v2"
    private var currentUserID: String?
    private var scopedKey: String?

    @Published private(set) var vehicles: [Vehicle] = []

    private init() {
        vehicles = []
    }

    // MARK: - CRUD Operations

    func add(_ vehicle: Vehicle) {
        guard scopedKey != nil else { return }
        vehicles.append(vehicle)
        save()
    }

    func update(_ vehicle: Vehicle) {
        guard scopedKey != nil else { return }
        if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            vehicles[index] = vehicle
            save()
        }
    }

    func delete(_ vehicle: Vehicle) {
        guard scopedKey != nil else { return }
        vehicles.removeAll { $0.id == vehicle.id }
        save()
    }

    func deleteAt(offsets: IndexSet) {
        guard scopedKey != nil else { return }
        vehicles.remove(atOffsets: offsets)
        save()
    }

    func setCurrentUserID(_ userID: String?) {
        guard currentUserID != userID else { return }
        currentUserID = userID

        guard let userID else {
            scopedKey = nil
            vehicles = []
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
            vehicles = []
            return
        }
        guard let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([Vehicle].self, from: data)
        else {
            vehicles = []
            return
        }
        vehicles = decoded
    }

    private func save() {
        guard let key = scopedKey else { return }
        if let encoded = try? JSONEncoder().encode(vehicles) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    private func migrateLegacyDataIfNeeded(to key: String) {
        guard UserDefaults.standard.data(forKey: key) == nil else { return }
        guard let legacy = UserDefaults.standard.data(forKey: legacyKey) else { return }
        UserDefaults.standard.set(legacy, forKey: key)
    }
}
