//
//  ParkingAvailabilityStore.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 24/01/26.
//


import Foundation
import Supabase
internal import Combine

@MainActor
final class ParkingAvailabilityStore: ObservableObject,Sendable {

    @Published private(set) var byParkingId: [UUID: ParkingAvailability] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var available: [UUID: Int] = [:]


    private let client: SupabaseClient
    private var channel: RealtimeChannelV2?
    private var hasLoadedOnce = false
    private static let realtimeDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            let formatterWithFractional = ISO8601DateFormatter()
            formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsed = formatterWithFractional.date(from: raw) {
                return parsed
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            if let parsed = formatter.date(from: raw) {
                return parsed
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported date format: \(raw)"
            )
        }
        return decoder
    }()

    init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - Read helper (UI dan qulay)
    func availability(for parkingId: UUID) -> ParkingAvailability? {
        byParkingId[parkingId]
    }

    // MARK: - Initial load (select)
    func initialLoad(force: Bool = false) {
        if hasLoadedOnce && !force { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                self.isLoading = true
                self.errorMessage = nil
                defer { self.isLoading = false }

                let rows: [ParkingAvailability] = try await client
                    .from("parking_availability")
                    .select()
                    .execute()
                    .value

                var map: [UUID: ParkingAvailability] = [:]
                var avail: [UUID: Int] = [:]
                rows.forEach { map[$0.parkingId] = $0
                    avail[$0.parkingId] = $0.availableSpots}
                self.byParkingId = map
                self.available = avail
                self.hasLoadedOnce = true
            } catch {
                self.errorMessage = "Availability yuklanmadi"
                print("availability initialLoad error:", error)
            }
        }
    }

    // MARK: - Realtime subscribe (UPDATE)
    func startRealtime() {
        // ikki marta subscribe bo'lib ketmasin
        if channel != nil { return }

        Task { [weak self] in
            guard let self else { return }

            do {
                let channel = client.realtimeV2.channel("realtime:parking_availability")
                self.channel = channel

                // ✅ Muhim: UpdateAction ishlatamiz, shunda update.record bor.
                let updates = channel.postgresChange(
                    UpdateAction.self,
                    schema: "public",
                    table: "parking_availability"
                )

                try await channel.subscribeWithError()

                // stream listener
                Task { [weak self] in
                    guard let self else { return }
                    for await update in updates {
                        if let decoded = self.decodeAvailability(from: update.record) {
                            self.byParkingId[decoded.parkingId] = decoded
                            self.available[decoded.parkingId] = decoded.availableSpots
                        }
                    }
                }

            } catch {
                self.errorMessage = "Realtime ishlamadi"
                print("availability realtime error:", error)
            }
        }
    }

    func stopRealtime() {
        Task { [weak self] in
            guard let self, let ch = self.channel else { return }
            await ch.unsubscribe()
            self.channel = nil
        }
    }

    // MARK: - Decode
    private func decodeAvailability(from record: JSONObject) -> ParkingAvailability? {
        do {
            return try record.decode(as: ParkingAvailability.self, decoder: Self.realtimeDecoder)
        } catch {
            print("availability decode error:", error)
            return nil
        }
    }


}
