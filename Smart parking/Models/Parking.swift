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
    let city: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let price_per_hour: Double
    let rating: Double?
    let thumbnail_url: String?
    let total_spots: Int
    var live_occupancy: Int?
    var description: String?
    let is_popular: Bool?
    let images: [String]?
    let features: [String]?
    let owner_id: UUID?
    let working_hours: String?
    let phone: String?
    let covered: Bool?
    let max_height_cm: Int?

    init(
        id: UUID,
        name: String,
        city: String,
        address: String?,
        latitude: Double,
        longitude: Double,
        price_per_hour: Double,
        rating: Double?,
        thumbnail_url: String?,
        total_spots: Int,
        live_occupancy: Int?,
        description: String?,
        is_popular: Bool?,
        images: [String]?,
        features: [String]?,
        owner_id: UUID? = nil,
        working_hours: String? = nil,
        phone: String? = nil,
        covered: Bool? = nil,
        max_height_cm: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.price_per_hour = price_per_hour
        self.rating = rating
        self.thumbnail_url = thumbnail_url
        self.total_spots = total_spots
        self.live_occupancy = live_occupancy
        self.description = description
        self.is_popular = is_popular
        self.images = images
        self.features = features
        self.owner_id = owner_id
        self.working_hours = working_hours
        self.phone = phone
        self.covered = covered
        self.max_height_cm = max_height_cm
    }

    enum CodingKeys: String, CodingKey {
        case id, name, city, address, latitude, longitude
        case price_per_hour, rating, thumbnail_url, total_spots
        case live_occupancy, description, is_popular, images, features
        case owner_id, working_hours, phone, covered, max_height_cm
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        city = try container.decode(String.self, forKey: .city)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        price_per_hour = try container.decode(Double.self, forKey: .price_per_hour)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        thumbnail_url = try container.decodeIfPresent(String.self, forKey: .thumbnail_url)
        total_spots = try container.decode(Int.self, forKey: .total_spots)
        live_occupancy = try container.decodeIfPresent(Int.self, forKey: .live_occupancy)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        is_popular = try container.decodeIfPresent(Bool.self, forKey: .is_popular)
        images = try container.decodeIfPresent([String].self, forKey: .images)
        features = try container.decodeIfPresent([String].self, forKey: .features)
        owner_id = try container.decodeIfPresent(UUID.self, forKey: .owner_id)
        working_hours = try container.decodeIfPresent(String.self, forKey: .working_hours)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        covered = try container.decodeIfPresent(Bool.self, forKey: .covered)
        max_height_cm = try container.decodeIfPresent(Int.self, forKey: .max_height_cm)
    }
}
