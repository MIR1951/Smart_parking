//
//  ParkingService.swift
//  Smart parking
//

import Foundation
import Supabase

private struct FetchByCityParams: Sendable {
    let p_city: String
    let p_limit: Int
    let p_offset: Int
}
nonisolated extension FetchByCityParams: Encodable {}

private struct FetchNearbyParams: Sendable {
    let p_lat: Double
    let p_lng: Double
    let p_radius_km: Double
    let p_limit: Int
}
nonisolated extension FetchNearbyParams: Encodable {}

final class ParkingService {
    private let client = SB.shared.client

    // Shahar bo'yicha — yangi get_parkings_by_city RPC
    func fetchByCity(_ city: String, limit: Int = 100, offset: Int = 0) async throws -> [Parking] {
        let params = FetchByCityParams(p_city: city, p_limit: limit, p_offset: offset)
        let rows: [Parking] = try await client
            .rpc("get_parkings_by_city", params: params)
            .execute()
            .value
        return rows
    }

    // Yaqin parkinglar — earthdistance RPC
    func fetchNearby(lat: Double, lng: Double, radiusKm: Double = 5, limit: Int = 20) async throws -> [NearbyParking] {
        let params = FetchNearbyParams(p_lat: lat, p_lng: lng, p_radius_km: radiusKm, p_limit: limit)
        return try await client
            .rpc("get_nearby_parkings", params: params)
            .execute()
            .value
    }

    func fetchDistinctCities() async throws -> [String] {
        struct Row: Decodable { let city: String }
        let rows: [Row] = try await client
            .from("parkings")
            .select("city")
            .execute()
            .value
        let unique = Set(rows.map { $0.city.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter { !$0.isEmpty }
        return unique.sorted()
    }

    // Barcha shaharlar — cache-first UX uchun (ParkingsStore ishlatadi)
    func fetchParkings() async throws -> [Parking] {
        let response = try await client
            .from("parkings")
            .select(
                """
                id, name, city, address, latitude, longitude,
                price_per_hour, rating, thumbnail_url, total_spots,
                description, is_popular, images, features, owner_id,
                working_hours, phone, covered, max_height_cm,
                parking_live_stats ( live_occupancy )
                """
            )
            .execute()

        let decoded = try JSONDecoder.supabaseDecoder.decode([RawParking].self, from: response.data)

        return decoded.map { item in
            Parking(
                id: item.id,
                name: item.name,
                city: item.city,
                address: item.address,
                latitude: item.latitude,
                longitude: item.longitude,
                price_per_hour: item.price_per_hour,
                rating: item.rating,
                thumbnail_url: item.thumbnail_url,
                total_spots: item.total_spots,
                live_occupancy: item.parking_live_stats?.live_occupancy,
                description: item.description,
                is_popular: item.is_popular,
                images: item.images,
                features: item.features,
                owner_id: item.owner_id,
                working_hours: item.working_hours,
                phone: item.phone,
                covered: item.covered,
                max_height_cm: item.max_height_cm
            )
        }
    }
}

private struct RawParking: Codable {
    let id: UUID
    let name: String
    let city: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let price_per_hour: Double
    let rating: Double?
    let thumbnail_url: String?
    let total_spots: Int
    let parking_live_stats: LiveStats?
    var description: String?
    let is_popular: Bool?
    let images: [String]?
    let features: [String]?
    let owner_id: UUID?
    let working_hours: String?
    let phone: String?
    let covered: Bool?
    let max_height_cm: Int?
}

private struct LiveStats: Codable {
    let live_occupancy: Int?
}

// Yaqin parking — distance_km qo'shimcha maydon
struct NearbyParking: Identifiable, Codable {
    let id: UUID
    let name: String
    let city: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let price_per_hour: Double
    let rating: Double?
    let thumbnail_url: String?
    let total_spots: Int
    let description: String?
    let is_popular: Bool?
    let images: [String]?
    let features: [String]?
    let owner_id: UUID?
    let working_hours: String?
    let phone: String?
    let covered: Bool?
    let max_height_cm: Int?
    let live_occupancy: Int?
    let distance_km: Double

    var asParking: Parking {
        Parking(
            id: id, name: name, city: city, address: address,
            latitude: latitude, longitude: longitude,
            price_per_hour: price_per_hour, rating: rating,
            thumbnail_url: thumbnail_url, total_spots: total_spots,
            live_occupancy: live_occupancy, description: description,
            is_popular: is_popular, images: images, features: features,
            owner_id: owner_id, working_hours: working_hours,
            phone: phone, covered: covered, max_height_cm: max_height_cm
        )
    }
}
