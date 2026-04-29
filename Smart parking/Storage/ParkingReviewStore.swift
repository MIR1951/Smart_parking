//
//  ParkingReviewStore.swift
//  Smart parking
//
//  Created by Smart Parking on 20/02/26.
//

 import Combine
import Foundation

@MainActor
final class ParkingReviewStore: ObservableObject {
    @Published private(set) var reviewsByParking: [UUID: [ParkingReview]] = [:]
    @Published private(set) var loadingParkingIDs: Set<UUID> = []
    @Published private(set) var submittingParkingIDs: Set<UUID> = []
    @Published private(set) var eligibilityByParking: [UUID: ReviewEligibility] = [:]
    @Published var errorMessage: String?

    private let service = ParkingReviewService()

    func reviews(for parkingId: UUID) -> [ParkingReview] {
        reviewsByParking[parkingId] ?? []
    }

    func isLoading(parkingId: UUID) -> Bool {
        loadingParkingIDs.contains(parkingId)
    }

    func isSubmitting(parkingId: UUID) -> Bool {
        submittingParkingIDs.contains(parkingId)
    }

    func eligibility(for parkingId: UUID) -> ReviewEligibility {
        eligibilityByParking[parkingId] ?? .needsBooking
    }

    func hasEligibility(parkingId: UUID) -> Bool {
        eligibilityByParking[parkingId] != nil
    }

    func summary(for parkingId: UUID, fallbackRating: Double?) -> (average: Double, count: Int) {
        let reviews = reviewsByParking[parkingId] ?? []
        if reviews.isEmpty {
            return (fallbackRating ?? 5.0, 0)
        }

        let total = reviews.reduce(0.0) { partial, review in
            partial + Double(review.rating)
        }
        return (total / Double(reviews.count), reviews.count)
    }

    func load(parkingId: UUID) async {
        loadingParkingIDs.insert(parkingId)
        defer { loadingParkingIDs.remove(parkingId) }

        do {
            let reviews = try await service.fetchReviews(parkingId: parkingId)
            let eligibility = try await service.reviewEligibility(parkingId: parkingId)

            reviewsByParking[parkingId] = reviews
            eligibilityByParking[parkingId] = eligibility
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submit(parkingId: UUID, rating: Int, comment: String) async throws {
        guard case .eligible(let reservationId) = eligibilityByParking[parkingId] else {
            throw ParkingReviewError.noEligibleReservation
        }

        submittingParkingIDs.insert(parkingId)
        defer { submittingParkingIDs.remove(parkingId) }

        try await service.submitReview(
            reservationId: reservationId,
            parkingId: parkingId,
            rating: rating,
            comment: comment
        )
        await load(parkingId: parkingId)
    }
}
