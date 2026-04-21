//
//  VehiclesStore.swift
//  Smart parking
//
//  Foydalanuvchi mashinalarini boshqarish — Supabase + UserDefaults fallback
//

 import Combine
import Foundation
import os
import Supabase
import SwiftUI

// MARK: - Supabase DTO

struct VehicleDTO: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let name: String
    let type: String
    let plate_number: String
    let color: String
    let created_at: Date?
}

@MainActor
final class VehiclesStore: ObservableObject {
    static let shared = VehiclesStore()

    private let legacyKey = "user_vehicles"
    private let keyPrefix = "user_vehicles_v2"
    private var currentUserID: String?
    private var scopedKey: String?

    @Published private(set) var vehicles: [Vehicle] = []
    @Published private(set) var isLoading = false

    private init() {
        vehicles = []
    }

    // MARK: - CRUD Operations (Supabase + local fallback)

    func add(_ vehicle: Vehicle) {
        guard let userID = currentUserID else { return }
        let snapshot = vehicles
        vehicles.append(vehicle)
        saveLocal()

        guard let userId = UUID(uuidString: userID) else {
            vehicles = snapshot; saveLocal(); return
        }

        Task {
            do {
                let dto: [String: AnyEncodable] = [
                    "id": AnyEncodable(vehicle.id),
                    "user_id": AnyEncodable(userId),
                    "name": AnyEncodable(vehicle.name),
                    "type": AnyEncodable(vehicle.type.rawValue),
                    "plate_number": AnyEncodable(vehicle.plateNumber),
                    "color": AnyEncodable(vehicle.color.rawValue),
                ]
                try await SB.shared.client
                    .from("user_vehicles")
                    .insert(dto)
                    .execute()
            } catch {
                vehicles = snapshot
                saveLocal()
                Logger.vehicles.error("Add error — rolled back: \(error.localizedDescription)")
            }
        }
    }

    func update(_ vehicle: Vehicle) {
        guard let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) else { return }
        let snapshot = vehicles
        vehicles[index] = vehicle
        saveLocal()

        Task {
            do {
                let updates: [String: AnyEncodable] = [
                    "name": AnyEncodable(vehicle.name),
                    "type": AnyEncodable(vehicle.type.rawValue),
                    "plate_number": AnyEncodable(vehicle.plateNumber),
                    "color": AnyEncodable(vehicle.color.rawValue),
                ]
                try await SB.shared.client
                    .from("user_vehicles")
                    .update(updates)
                    .eq("id", value: vehicle.id)
                    .execute()
            } catch {
                vehicles = snapshot
                saveLocal()
                Logger.vehicles.error("Update error — rolled back: \(error.localizedDescription)")
            }
        }
    }

    func delete(_ vehicle: Vehicle) {
        let snapshot = vehicles
        vehicles.removeAll { $0.id == vehicle.id }
        saveLocal()

        Task {
            do {
                try await SB.shared.client
                    .from("user_vehicles")
                    .delete()
                    .eq("id", value: vehicle.id)
                    .execute()
            } catch {
                vehicles = snapshot
                saveLocal()
                Logger.vehicles.error("Delete error — rolled back: \(error.localizedDescription)")
            }
        }
    }

    func deleteAt(offsets: IndexSet) {
        let snapshot = vehicles
        let toDelete = offsets.map { vehicles[$0] }
        vehicles.remove(atOffsets: offsets)
        saveLocal()

        Task {
            do {
                for vehicle in toDelete {
                    try await SB.shared.client
                        .from("user_vehicles")
                        .delete()
                        .eq("id", value: vehicle.id)
                        .execute()
                }
            } catch {
                vehicles = snapshot
                saveLocal()
                Logger.vehicles.error("DeleteAt error — rolled back: \(error.localizedDescription)")
            }
        }
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
        loadLocal()

        // Supabase'dan sync
        Task {
            await syncFromSupabase()
        }
    }

    // MARK: - Supabase Sync

    func syncFromSupabase() async {
        guard let userID = currentUserID, let userId = UUID(uuidString: userID) else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let dtos: [VehicleDTO] = try await SB.shared.client
                .from("user_vehicles")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            vehicles = dtos.map { dto in
                Vehicle(
                    id: dto.id,
                    name: dto.name,
                    type: VehicleType(rawValue: dto.type) ?? .sedan,
                    plateNumber: dto.plate_number,
                    color: VehicleColor(rawValue: dto.color) ?? .gray
                )
            }
            saveLocal()
        } catch {
            // Supabase xatolik — local ma'lumotlar qoladi
            Logger.vehicles.error("Sync error: \(error.localizedDescription)")
        }
    }

    // MARK: - Local Persistence (offline fallback)

    private func loadLocal() {
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

    private func saveLocal() {
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

// MARK: - Type-erased Encodable wrapper

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = { encoder in try value.encode(to: encoder) }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
