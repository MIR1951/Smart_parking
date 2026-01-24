//
//  ParkingAvailability.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 24/01/26.
//


import Foundation

struct ParkingAvailability: Codable, Identifiable, Equatable {
    let parkingId: UUID
    let liveOccupancy: Int
    let reservedSpots: Int
    let availableSpots: Int
    let updatedAt: Date

    var id: UUID { parkingId }

    enum CodingKeys: String, CodingKey {
        case parkingId = "parking_id"
        case liveOccupancy = "live_occupancy"
        case reservedSpots = "reserved_spots"
        case availableSpots = "available_spots"
        case updatedAt = "updated_at"
    }
}
