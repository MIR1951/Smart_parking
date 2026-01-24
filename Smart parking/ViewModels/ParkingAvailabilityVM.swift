//
//  ParkingAvailabilityVM.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 24/01/26.
//


import Foundation
import Supabase
internal import Combine

@MainActor
final class ParkingAvailabilityVM: ObservableObject {
    @Published var items: [UUID: ParkingAvailability] = [:]  // parkingId -> availability

    private let service: ParkingAvailabilityRealtimeService
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
        self.service = ParkingAvailabilityRealtimeService(client: client)
    }

    func startRealtimeAll() async {
        do {
            // Avval initial fetch (shart emas, lekin yaxshi)
            try await fetchInitial()

            // Keyin realtime
            try await service.subscribeAvailabilityUpdates() { [weak self] availability in
                self?.items[availability.parkingId] = availability
            }
        } catch {
            print("Realtime start error:", error)
        }
    }

    func stop() async {
        await service.unsubscribe()
    }

    private func fetchInitial() async throws {
        let response: [ParkingAvailability] = try await client
            .from("parking_availability")
            .select()
            .execute()
            .value

        var map: [UUID: ParkingAvailability] = [:]
        for a in response { map[a.parkingId] = a }
        self.items = map
    }
}
