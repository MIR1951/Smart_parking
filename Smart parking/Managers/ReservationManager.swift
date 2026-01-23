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

        let res: UUID = try await SB.client
            .rpc("create_reservation", params: params)
            .execute()
            .value

        return res
    }
}

