import Foundation
import Supabase

@MainActor
final class ParkingAvailabilityRealtimeService {
    private let client: SupabaseClient
    private var channel: RealtimeChannelV2?

    init(client: SupabaseClient) {
        self.client = client
    }

    func subscribeAvailabilityUpdates(
        onUpdate: @escaping (ParkingAvailability) -> Void
    ) async throws {
        let channel = client.realtimeV2.channel("parking-availability-updates")
        self.channel = channel

        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "parking_availability"
        )

        try await channel.subscribeWithError()

        Task {
            for await update in updates {
                // ✅ update.record bor
                if let decoded = decodeAvailability(from: update.record) {
                    onUpdate(decoded)
                }
            }
        }
    }

    func unsubscribe() async {
        guard let channel else { return }
        await channel.unsubscribe()
        self.channel = nil
    }

    private func decodeAvailability(from json: JSONObject) -> ParkingAvailability? {
        do {
            return try json.decode(as: ParkingAvailability.self)
        } catch {
            print("decode error:", error)
            return nil
        }
    }
}
