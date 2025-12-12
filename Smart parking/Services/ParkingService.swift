//
//  ParkingService.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//


import Supabase
import Foundation

final class ParkingService {
    private let client = SB.client

    func fetchParkings() async throws -> [Parking] {

        let response = try await client
            .from("parkings")
            .select("""
                id,
                name,
                address,
                latitude,
                longitude,
                price_per_hour,
                thumbnail_url,
                total_spots,
                parking_live_stats ( live_occupancy )
                description
            """)
            .execute()

        struct RawParking: Codable {
            let id: String
            let name: String
            let address: String?
            let latitude: Double
            let longitude: Double
            let price_per_hour: Double
            let thumbnail_url: String?
            let total_spots: Int
            let parking_live_stats: LiveStats?
            var description: String?
        }

        struct LiveStats: Codable {
            let live_occupancy: Int?
        }

        let decoded = try JSONDecoder().decode([RawParking].self, from: response.data)

        return decoded.compactMap { item in
            guard let uuid = UUID(uuidString: item.id) else {
                print("Invalid UUID: \(item.id)")
                return nil
            }

            return Parking(
                id: uuid,
                name: item.name,
                address: item.address,
                latitude: item.latitude,
                longitude: item.longitude,
                price_per_hour: item.price_per_hour,
                thumbnail_url: item.thumbnail_url,
                total_spots: item.total_spots,
                live_occupancy: item.parking_live_stats?.live_occupancy,
                description: item.description
            )
        }

    }
}

