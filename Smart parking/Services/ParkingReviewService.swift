//
//  ParkingReviewService.swift
//  Smart parking
//
//  Created by Smart Parking on 20/02/26.
//

import Foundation
import Supabase

enum ReviewEligibility: Equatable {
    case eligible(UUID)
    case needsBooking
    case alreadyReviewed
}

enum ParkingReviewError: LocalizedError {
    case noEligibleReservation
    case alreadyReviewed
    case emptyComment

    var errorDescription: String? {
        switch self {
        case .noEligibleReservation:
            return "Only users with completed bookings can submit a review."
        case .alreadyReviewed:
            return "You have already submitted reviews for all eligible bookings."
        case .emptyComment:
            return "Please enter your review comment."
        }
    }
}

private struct ReservationCandidate: Codable {
    let id: UUID
    let end_time: Date?
}

private struct ExistingReview: Codable {
    let id: UUID
}

private struct CreateParkingReviewPayload: Encodable {
    let parking_id: UUID
    let user_id: UUID
    let reservation_id: UUID
    let rating: Int
    let comment: String
}

final class ParkingReviewService {
    private let client = SB.shared.client

    func fetchReviews(parkingId: UUID) async throws -> [ParkingReview] {
        try await client
            .from("parking_reviews")
            .select(
                """
                id,
                parking_id,
                user_id,
                reservation_id,
                rating,
                comment,
                created_at,
                updated_at,
                users:users(username,profile_image_url)
                """
            )
            .eq("parking_id", value: parkingId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func reviewEligibility(parkingId: UUID) async throws -> ReviewEligibility {
        let userID = try await client.auth.session.user.id.uuidString

        let completedRows: [ReservationCandidate] = try await client
            .from("reservations")
            .select("id,end_time")
            .eq("user_id", value: userID)
            .eq("parking_id", value: parkingId.uuidString)
            .eq("status", value: "completed")
            .order("end_time", ascending: false)
            .limit(20)
            .execute()
            .value

        let expiredRows: [ReservationCandidate] = try await client
            .from("reservations")
            .select("id,end_time")
            .eq("user_id", value: userID)
            .eq("parking_id", value: parkingId.uuidString)
            .eq("status", value: "expired")
            .order("end_time", ascending: false)
            .limit(20)
            .execute()
            .value

        let candidates = (completedRows + expiredRows).sorted {
            ($0.end_time ?? .distantPast) > ($1.end_time ?? .distantPast)
        }

        guard !candidates.isEmpty else {
            return .needsBooking
        }

        for candidate in candidates {
            let existing: [ExistingReview] = try await client
                .from("parking_reviews")
                .select("id")
                .eq("reservation_id", value: candidate.id.uuidString)
                .limit(1)
                .execute()
                .value

            if existing.isEmpty {
                return .eligible(candidate.id)
            }
        }

        return .alreadyReviewed
    }

    func submitReview(parkingId: UUID, rating: Int, comment: String) async throws {
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty else { throw ParkingReviewError.emptyComment }

        let eligibility = try await reviewEligibility(parkingId: parkingId)
        guard case .eligible(let reservationID) = eligibility else {
            if case .alreadyReviewed = eligibility {
                throw ParkingReviewError.alreadyReviewed
            }
            throw ParkingReviewError.noEligibleReservation
        }

        let userID = try await client.auth.session.user.id
        let payload = CreateParkingReviewPayload(
            parking_id: parkingId,
            user_id: userID,
            reservation_id: reservationID,
            rating: max(1, min(5, rating)),
            comment: trimmedComment
        )

        do {
            _ = try await client
                .from("parking_reviews")
                .insert(payload)
                .execute()
        } catch {
            let message = error.localizedDescription.lowercased()
            if message.contains("unique") || message.contains("23505") || message.contains("duplicate") {
                throw ParkingReviewError.alreadyReviewed
            }
            throw error
        }
    }
}
