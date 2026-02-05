//
//  ReservationManager.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//

import Foundation
internal import PostgREST
import Supabase

struct CreateReservationParams: Sendable {
    let p_parking_id: UUID
    let p_duration_minutes: Int
}

nonisolated extension CreateReservationParams: Encodable {}

final class ReservationManager {
    static let shared = ReservationManager()
    init() {}

    func createReservation(parkingId: UUID, durationMinutes: Int) async throws -> UUID {
        let params = CreateReservationParams(
            p_parking_id: parkingId,
            p_duration_minutes: durationMinutes
        )

        let res: UUID = try await SB.shared.client
            .rpc("create_reservation", params: params)
            .execute()
            .value

        return res
    }

    func cancelReservation(reservationId: UUID) async throws {
        let userID = try await SB.shared.client.auth.session.user.id.uuidString

        // Note: Supabase constraint "canceled" (bir 'l' bilan) kutadi
        try await SB.shared.client
            .from("reservations")
            .update(["status": "canceled"])
            .eq("id", value: reservationId.uuidString)
            .eq("user_id", value: userID)
            .execute()
    }
}
