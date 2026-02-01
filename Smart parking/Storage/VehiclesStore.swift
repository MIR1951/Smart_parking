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

    private let key = "user_vehicles"

    @Published private(set) var vehicles: [Vehicle] = []

    private init() {
        load()
    }

    // MARK: - CRUD Operations

    func add(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
        save()
    }

    func update(_ vehicle: Vehicle) {
        if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            vehicles[index] = vehicle
            save()
        }
    }

    func delete(_ vehicle: Vehicle) {
        vehicles.removeAll { $0.id == vehicle.id }
        save()
    }

    func deleteAt(offsets: IndexSet) {
        vehicles.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([Vehicle].self, from: data)
        else {
            // Demo mashinalar
            vehicles = [
                Vehicle(
                    name: "Toyota Fortuner", type: .suv, plateNumber: "GR 123-ABCD", color: .orange),
                Vehicle(name: "Audi", type: .sedan, plateNumber: "GR 123-ABCD", color: .red),
                Vehicle(
                    name: "Hyundai Verna", type: .sedan, plateNumber: "GR A12-BCDE", color: .blue),
                Vehicle(
                    name: "Toyota Innova", type: .mpv, plateNumber: "GR B34-CDEF", color: .green),
            ]
            return
        }
        vehicles = decoded
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(vehicles) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
