//
//  ParkingStatus.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//


import Foundation

struct ParkingStatus: Identifiable, Codable {
    let id: UUID
    let name: String
    let address: String?
    let total_spots: Int
    let thumbnail_url: String?

    let live_occupancy: Int
    let reserved_spots: Int
    let available_spots: Int
}
