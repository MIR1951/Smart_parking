//
//  ParkingReview.swift
//  Smart parking
//
//  Created by Smart Parking on 20/02/26.
//

import Foundation

struct ParkingReviewAuthor: Codable {
    let username: String?
    let profile_image_url: String?

    var displayName: String {
        let trimmed = username?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "User" : trimmed
    }

    var profileImageURL: String? {
        profile_image_url
    }
}

struct ParkingReview: Codable, Identifiable {
    let id: UUID
    let parking_id: UUID
    let user_id: UUID
    let reservation_id: UUID
    let rating: Int
    let comment: String
    let created_at: Date
    let updated_at: Date?
    let users: ParkingReviewAuthor?

    var parkingId: UUID { parking_id }
    var userId: UUID { user_id }
    var reservationId: UUID { reservation_id }
    var createdAt: Date { created_at }
    var updatedAt: Date? { updated_at }
    var author: ParkingReviewAuthor? { users }
}
