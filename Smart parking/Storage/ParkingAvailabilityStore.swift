//
//  ParkingAvailabilityStore.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 24/01/26.
//

internal import Combine
import Foundation
import Supabase

@MainActor
final class ParkingAvailabilityStore: ObservableObject, Sendable {

    @Published private(set) var byParkingId: [UUID: ParkingAvailability] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var available: [UUID: Int] = [:]
    @Published private(set) var isRealtimeConnected = false

    private let client: SupabaseClient
    private var channel: RealtimeChannelV2?
    private var updatesTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var hasLoadedOnce = false
    private var reconnectAttempt = 0
    private var isConnectingRealtime = false
    private var shouldMaintainRealtime = false

    init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - Read helper (UI dan qulay)
    func availability(for parkingId: UUID) -> ParkingAvailability? {
        byParkingId[parkingId]
    }

    // MARK: - Initial load / Refresh
    func initialLoad(force: Bool = false) {
        Task { [weak self] in
            await self?.refreshNow(force: force)
        }
    }

    func refreshNow(force: Bool = false) async {
        if hasLoadedOnce && !force { return }

        do {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            let rows: [ParkingAvailability] =
                try await client
                .from("parking_availability")
                .select()
                .execute()
                .value

            var map: [UUID: ParkingAvailability] = [:]
            var avail: [UUID: Int] = [:]
            rows.forEach {
                map[$0.parkingId] = $0
                avail[$0.parkingId] = $0.availableSpots
            }
            byParkingId = map
            available = avail
            hasLoadedOnce = true
        } catch {
            errorMessage = "Availability yuklanmadi"
        }
    }

    // MARK: - Realtime
    func startRealtime() {
        shouldMaintainRealtime = true
        connectRealtimeIfNeeded()
    }

    func stopRealtime() {
        shouldMaintainRealtime = false
        reconnectAttempt = 0
        isRealtimeConnected = false
        isConnectingRealtime = false

        retryTask?.cancel()
        retryTask = nil

        updatesTask?.cancel()
        updatesTask = nil

        let existingChannel = channel
        channel = nil

        Task {
            if let existingChannel {
                await existingChannel.unsubscribe()
            }
        }
    }

    private func connectRealtimeIfNeeded() {
        guard shouldMaintainRealtime else { return }
        guard channel == nil else { return }
        guard !isConnectingRealtime else { return }

        isConnectingRealtime = true
        retryTask?.cancel()
        retryTask = nil

        Task { [weak self] in
            guard let self else { return }
            defer { self.isConnectingRealtime = false }

            do {
                let realtimeChannel = client.realtimeV2.channel("realtime:parking_availability")
                let updates = realtimeChannel.postgresChange(
                    UpdateAction.self,
                    schema: "public",
                    table: "parking_availability"
                )
                let inserts = realtimeChannel.postgresChange(
                    InsertAction.self,
                    schema: "public",
                    table: "parking_availability"
                )

                try await realtimeChannel.subscribeWithError()
                guard shouldMaintainRealtime else {
                    await realtimeChannel.unsubscribe()
                    return
                }
                channel = realtimeChannel
                isRealtimeConnected = true
                reconnectAttempt = 0
                errorMessage = nil

                updatesTask?.cancel()
                updatesTask = Task { [weak self] in
                    guard let self else { return }
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { [weak self] in
                            guard let self else { return }
                            for await update in updates {
                                await self.applyRealtimeRecord(update.record)
                            }
                        }
                        group.addTask { [weak self] in
                            guard let self else { return }
                            for await insert in inserts {
                                await self.applyRealtimeRecord(insert.record)
                            }
                        }
                    }
                    await self.handleRealtimeDisconnected()
                }
            } catch is CancellationError {
                isRealtimeConnected = false
                channel = nil
            } catch {
                isRealtimeConnected = false
                channel = nil
                errorMessage = "Realtime ishlamadi"
                scheduleReconnectIfNeeded()
            }
        }
    }

    private func applyRealtimeRecord(_ record: JSONObject) {
        if let decoded = decodeAvailability(from: record) {
            byParkingId[decoded.parkingId] = decoded
            available[decoded.parkingId] = decoded.availableSpots
        }
    }

    private func handleRealtimeDisconnected() async {
        guard shouldMaintainRealtime else { return }

        isRealtimeConnected = false

        if let channel {
            await channel.unsubscribe()
        }
        self.channel = nil
        scheduleReconnectIfNeeded()
    }

    private func scheduleReconnectIfNeeded() {
        guard shouldMaintainRealtime else { return }
        retryTask?.cancel()

        reconnectAttempt += 1
        let delaySeconds = min(pow(2.0, Double(reconnectAttempt)), 30.0)

        retryTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            connectRealtimeIfNeeded()
        }
    }

    // MARK: - Decode
    private func decodeAvailability(from record: JSONObject) -> ParkingAvailability? {
        do {
            return try record.decode(
                as: ParkingAvailability.self, decoder: JSONDecoder.supabaseDecoder)
        } catch {

            return nil
        }
    }

}
