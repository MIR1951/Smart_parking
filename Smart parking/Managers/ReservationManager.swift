import Foundation
import Supabase

struct CreateReservationParams: Sendable {
    let p_parking_id: String
    let p_duration_minutes: Int
}

nonisolated extension CreateReservationParams: Encodable {}

struct ReservationManager {
    private let client = SB.client
    
    func createReservation(parkingId: UUID, durationMinutes: Int) async throws -> UUID {
        let params = CreateReservationParams(
            p_parking_id: parkingId.uuidString,
            p_duration_minutes: durationMinutes
        )
        
        let response = try await client
            .rpc("create_reservation", params: params)
            .execute()

        // RPC return value handling:
        if let idString = response.value as? String,
           let uuid = UUID(uuidString: idString) {
            return uuid
        }

        throw URLError(.badServerResponse)
    }
}

