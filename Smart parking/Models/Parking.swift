//
//  Parking.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//
import Foundation

struct Parking: Identifiable, Codable {
    let id: UUID
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let price_per_hour: Double
    let thumbnail_url: String?
    let total_spots: Int
    var live_occupancy: Int?
    var description: String?
}
