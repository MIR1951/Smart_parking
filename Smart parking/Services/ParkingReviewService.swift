//
//  ParkingReviewService.swift
//  Smart parking
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

private struct ReviewedID: Codable {
    let reservation_id: UUID
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

    func fetchReviews(parkingId: UUID, limit: Int = 50) async throws -> [ParkingReview] {
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
            .limit(limit)
            .execute()
            .value
    }

    // N+1 yo'q: bitta status query + bitta batch review check
    func reviewEligibility(parkingId: UUID) async throws -> ReviewEligibility {
        let userID = try await client.auth.session.user.id.uuidString

        // 1. completed + expired — bitta query
        let candidates: [ReservationCandidate] = try await client
            .from("reservations")
            .select("id,end_time")
            .eq("user_id", value: userID)
            .eq("parking_id", value: parkingId.uuidString)
            .in("status", values: ["completed", "expired"])
            .order("end_time", ascending: false)
            .limit(40)
            .execute()
            .value

        guard !candidates.isEmpty else { return .needsBooking }

        // 2. Batch review check — bitta query (N+1 yo'q)
        let candidateIds = candidates.map(\.id.uuidString)
        let reviewed: [ReviewedID] = try await client
            .from("parking_reviews")
            .select("reservation_id")
            .in("reservation_id", values: candidateIds)
            .execute()
            .value

        let reviewedSet = Set(reviewed.map(\.reservation_id))
        let sortedCandidates = candidates.sorted {
            ($0.end_time ?? .distantPast) > ($1.end_time ?? .distantPast)
        }

        if let first = sortedCandidates.first(where: { !reviewedSet.contains($0.id) }) {
            return .eligible(first.id)
        }
        return .alreadyReviewed
    }

    func submitReview(reservationId: UUID, parkingId: UUID, rating: Int, comment: String) async throws {
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty else { throw ParkingReviewError.emptyComment }

        let userID = try await client.auth.session.user.id
        let payload = CreateParkingReviewPayload(
            parking_id: parkingId,
            user_id: userID,
            reservation_id: reservationId,
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
