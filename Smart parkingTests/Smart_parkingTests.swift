//
//  Smart_parkingTests.swift
//  Smart parkingTests
//
//  Created by Kenjaboy Xajiyev on 30/11/25.
//

import Testing
@testable import Smart_parking
import Foundation

struct Smart_parkingTests {
    @Test func bookingItemComputesDurationAndAmount() {
        let now = Date()
        let start = now
        let end = now.addingTimeInterval(90 * 60)
        let parking = BookingParking(
            id: UUID(),
            name: "Central",
            address: "Main St",
            thumbnail_url: nil,
            price_per_hour: 4.0,
            rating: 4.6
        )
        let item = BookingItem(
            id: UUID(),
            status: "active",
            start_time: start,
            end_time: end,
            actual_start_time: nil,
            actual_end_time: nil,
            parking: parking
        )

        #expect(item.durationMinutes == 90)
        #expect(item.totalAmount == 6.0)
        #expect(item.canCancel)
        #expect(!item.isCompleted)
    }

    @Test func bookingItemTreatsPastActiveAsCompleted() {
        let now = Date()
        let start = now.addingTimeInterval(-2 * 3600)
        let end = now.addingTimeInterval(-3600)
        let parking = BookingParking(
            id: UUID(),
            name: "A",
            address: nil,
            thumbnail_url: nil,
            price_per_hour: 3.0,
            rating: nil
        )
        let item = BookingItem(
            id: UUID(),
            status: "active",
            start_time: start,
            end_time: end,
            actual_start_time: start,
            actual_end_time: nil,
            parking: parking
        )

        #expect(item.isCompleted)
        #expect(!item.canCancel)
    }

    @Test @MainActor func favoritesAreIsolatedPerUser() {
        clearUserDefaults(prefix: "favorite_parking_ids_v2_")
        UserDefaults.standard.removeObject(forKey: "favorite_parking_ids_v1")

        let store = FavoritesStore()
        let first = UUID()
        let second = UUID()

        store.setCurrentUserID("user-a")
        store.toggle(first)
        #expect(store.isFavorite(first))

        store.setCurrentUserID("user-b")
        #expect(!store.isFavorite(first))
        store.toggle(second)
        #expect(store.isFavorite(second))

        store.setCurrentUserID("user-a")
        #expect(store.isFavorite(first))
        #expect(!store.isFavorite(second))
    }

    @Test @MainActor func vehiclesAreIsolatedPerUser() {
        clearUserDefaults(prefix: "user_vehicles_v2_")
        UserDefaults.standard.removeObject(forKey: "user_vehicles")

        let store = VehiclesStore.shared
        let first = Vehicle(name: "Car A", type: .sedan, plateNumber: "AA 111")
        let second = Vehicle(name: "Car B", type: .suv, plateNumber: "BB 222")

        store.setCurrentUserID("user-a")
        store.add(first)
        #expect(store.vehicles.count == 1)

        store.setCurrentUserID("user-b")
        #expect(store.vehicles.isEmpty)
        store.add(second)
        #expect(store.vehicles.count == 1)
        #expect(store.vehicles[0].plateNumber == "BB 222")

        store.setCurrentUserID("user-a")
        #expect(store.vehicles.count == 1)
        #expect(store.vehicles[0].plateNumber == "AA 111")
    }

    @MainActor
    private func clearUserDefaults(prefix: String) {
        for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

}
