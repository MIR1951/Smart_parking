//
//  AdminParkingService.swift
//  Smart parking
//
//  Parking owner uchun CRUD operatsiyalari
//

import Foundation
import os
import Supabase
import Combine

private struct OwnerReservationsParams: Sendable {
    let p_limit: Int
}

nonisolated extension OwnerReservationsParams: Encodable {}

struct AdminParkingService {

    // MARK: - Fetch owned parkings

    func fetchOwnedParkings() async throws -> [Parking] {
        let userId = try await SB.shared.client.auth.session.user.id

        let parkings: [Parking] = try await SB.shared.client
            .from("parkings")
            .select()
            .eq("owner_id", value: userId)
            .order("name")
            .execute()
            .value

        return parkings
    }

    // MARK: - Create parking

    struct CreateParkingParams: Encodable {
        let name: String
        let city: String
        let address: String?
        let latitude: Double
        let longitude: Double
        let price_per_hour: Double
        let total_spots: Int
        let description: String?
        let is_popular: Bool
        let features: [String]?
        let images: [String]?
        let owner_id: UUID
    }

    func createParking(_ params: CreateParkingParams) async throws -> Parking {
        let parking: Parking = try await SB.shared.client
            .from("parkings")
            .insert(params)
            .select()
            .single()
            .execute()
            .value

        Logger.admin.info("Created parking: \(parking.name)")
        return parking
    }

    // MARK: - Update parking

    struct UpdateParkingParams: Encodable {
        let name: String?
        let city: String?
        let address: String?
        let latitude: Double?
        let longitude: Double?
        let price_per_hour: Double?
        let total_spots: Int?
        let description: String?
        let is_popular: Bool?
        let features: [String]?
        let images: [String]?
    }

    func updateParking(id: UUID, params: UpdateParkingParams) async throws -> Parking {
        let parking: Parking = try await SB.shared.client
            .from("parkings")
            .update(params)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value

        Logger.admin.info("Updated parking: \(id)")
        return parking
    }

    // MARK: - Delete parking

    func deleteParking(id: UUID) async throws {
        try await SB.shared.client
            .from("parkings")
            .delete()
            .eq("id", value: id)
            .execute()

        Logger.admin.info("Deleted parking: \(id)")
    }

    // MARK: - Fetch reservations for owned parkings

    func fetchReservationsForParking(_ parkingId: UUID) async throws -> [Reservation] {
        let reservations: [Reservation] = try await SB.shared.client
            .from("reservations")
            .select()
            .eq("parking_id", value: parkingId)
            .order("start_time", ascending: false)
            .limit(100)
            .execute()
            .value

        return reservations
    }

    // MARK: - Fetch available cities

    func fetchAvailableCities() async throws -> [String] {
        struct CityRow: Codable { let city: String }
        let rows: [CityRow] = try await SB.shared.client
            .rpc("get_distinct_cities")
            .execute()
            .value

        return rows.map(\.city)
    }

    func fetchAllOwnerReservations(limit: Int = 200) async throws -> [Reservation] {
        let reservations: [Reservation] = try await SB.shared.client
            .rpc("get_owner_reservations", params: OwnerReservationsParams(p_limit: limit))
            .execute()
            .value

        return reservations
    }

    // MARK: - Dashboard stats via RPC

    struct DashboardStats: Codable {
        let total_parkings: Int
        let total_spots: Int
        let active_reservations: Int
        let today_reservations: Int
        let total_completed: Int
    }

    func fetchDashboardStats() async throws -> DashboardStats {
        let stats: DashboardStats = try await SB.shared.client
            .rpc("get_owner_dashboard_stats")
            .execute()
            .value

        return stats
    }
}
