//
//  AdminStore.swift
//  Smart parking
//
//  Admin panel uchun markaziy state management + realtime
//

import Foundation
import os
import Supabase

@MainActor
@Observable
final class AdminStore {
    private let service = AdminParkingService()
    private let client = SB.shared.client

    var ownedParkings: [Parking] = []
    var dashboardStats: AdminParkingService.DashboardStats?
    var reservations: [UUID: [Reservation]] = [:]
    var availableCities: [String] = []
    var isLoading = false
    var error: String?

    // Realtime
    private var parkingsChannel: RealtimeChannelV2?
    private var reservationsChannel: RealtimeChannelV2?
    private var realtimeTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var reconnectAttempt = 0
    private var shouldMaintainRealtime = false
    private(set) var isRealtimeConnected = false

    // MARK: - Load all data

    func loadAll() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            async let parkingsTask = service.fetchOwnedParkings()
            async let statsTask = service.fetchDashboardStats()
            async let citiesTask = service.fetchAvailableCities()

            ownedParkings = try await parkingsTask
            dashboardStats = try await statsTask
            let dbCities = try await citiesTask
            // DB dan kelgan va static ro'yxatni birlashtirish
            let merged = Set(dbCities + UzbekistanCities.all)
            availableCities = merged.sorted()
        } catch {
            Logger.admin.error("Load error: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }

    // MARK: - Refresh parkings

    func refreshParkings() async {
        do {
            ownedParkings = try await service.fetchOwnedParkings()
        } catch {
            Logger.admin.error("Refresh parkings error: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }

    // MARK: - Refresh reservations for all parkings

    func refreshAllReservations() async {
        do {
            let all = try await service.fetchAllOwnerReservations()
            var grouped: [UUID: [Reservation]] = [:]
            for r in all { grouped[r.parking_id, default: []].append(r) }
            reservations = grouped
        } catch {
            Logger.admin.error("Refresh reservations error: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }

    // MARK: - Create parking

    func createParking(
        name: String,
        city: String,
        address: String?,
        latitude: Double,
        longitude: Double,
        pricePerHour: Double,
        totalSpots: Int,
        description: String?,
        features: [String]?,
        images: [String]?
    ) async throws {
        let userId = try await client.auth.session.user.id

        let params = AdminParkingService.CreateParkingParams(
            name: name,
            city: city,
            address: address,
            latitude: latitude,
            longitude: longitude,
            price_per_hour: pricePerHour,
            total_spots: totalSpots,
            description: description,
            is_popular: false,
            features: features,
            images: images,
            owner_id: userId
        )

        let newParking = try await service.createParking(params)
        ownedParkings.append(newParking)
        ParkingCache.shared.clear()
    }

    // MARK: - Update parking

    func updateParking(
        id: UUID,
        name: String?,
        city: String?,
        address: String?,
        latitude: Double?,
        longitude: Double?,
        pricePerHour: Double?,
        totalSpots: Int?,
        description: String?,
        features: [String]?,
        images: [String]?
    ) async throws {
        let params = AdminParkingService.UpdateParkingParams(
            name: name,
            city: city,
            address: address,
            latitude: latitude,
            longitude: longitude,
            price_per_hour: pricePerHour,
            total_spots: totalSpots,
            description: description,
            is_popular: nil,
            features: features,
            images: images
        )

        let updated = try await service.updateParking(id: id, params: params)

        if let index = ownedParkings.firstIndex(where: { $0.id == id }) {
            ownedParkings[index] = updated
        }
        ParkingCache.shared.clear()
    }

    // MARK: - Delete parking

    func deleteParking(id: UUID) async throws {
        try await service.deleteParking(id: id)
        ownedParkings.removeAll { $0.id == id }
        ParkingCache.shared.clear()
    }

    // MARK: - Cancel reservation

    func cancelReservation(id: UUID, parkingId: UUID) async throws {
        let params = CancelReservationParams(p_reservation_id: id)
        try await client
            .rpc("cancel_reservation", params: params)
            .execute()
        await loadReservations(for: parkingId)
    }

    // MARK: - Load reservations for a parking

    func loadReservations(for parkingId: UUID) async {
        do {
            reservations[parkingId] = try await service.fetchReservationsForParking(parkingId)
        } catch {
            Logger.admin.error("Load reservations error: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }

    // MARK: - Realtime

    func startRealtime() {
        shouldMaintainRealtime = true
        connectRealtimeIfNeeded()
    }

    private func connectRealtimeIfNeeded() {
        guard shouldMaintainRealtime, realtimeTask == nil else { return }
        retryTask?.cancel()
        retryTask = nil

        realtimeTask = Task { [weak self] in
            guard let self else { return }

            do {
                let userId = try await client.auth.session.user.id.uuidString

                // owner_id filter ile faqat o'z parkinglari (xavfsizlik + bandwidth)
                let pChannel = client.realtimeV2.channel("admin:parkings:\(userId)")
                let parkingChanges = pChannel.postgresChange(
                    AnyAction.self, schema: "public", table: "parkings",
                    filter: .eq("owner_id", value: userId)
                )

                let rChannel = client.realtimeV2.channel("admin:reservations:\(userId)")
                let reservationChanges = rChannel.postgresChange(
                    AnyAction.self, schema: "public", table: "reservations"
                )

                try await pChannel.subscribeWithError()
                try await rChannel.subscribeWithError()

                self.parkingsChannel = pChannel
                self.reservationsChannel = rChannel
                self.isRealtimeConnected = true
                self.reconnectAttempt = 0

                Logger.admin.info("Admin realtime connected (owner: \(userId))")

                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        for await _ in parkingChanges {
                            // parking o'zgarganda faqat parkings + stats yangilanadi
                            async let p = self.refreshParkings()
                            async let s = self.refreshStats()
                            _ = await (p, s)
                        }
                    }
                    group.addTask {
                        for await _ in reservationChanges {
                            // reservation o'zgarganda faqat reservations + stats
                            async let r = self.refreshAllReservations()
                            async let s = self.refreshStats()
                            _ = await (r, s)
                        }
                    }
                }
            } catch is CancellationError {
                self.isRealtimeConnected = false
            } catch {
                Logger.admin.error("Admin realtime failed: \(error.localizedDescription)")
                self.isRealtimeConnected = false
                self.realtimeTask = nil
                self.scheduleReconnect()
            }

            self.realtimeTask = nil
        }
    }

    private func scheduleReconnect() {
        guard shouldMaintainRealtime else { return }
        reconnectAttempt += 1
        let delay = min(pow(2.0, Double(reconnectAttempt)), 30.0)
        retryTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.connectRealtimeIfNeeded()
        }
    }

    private func refreshStats() async {
        do {
            dashboardStats = try await service.fetchDashboardStats()
        } catch {
            Logger.admin.error("Stats refresh error: \(error.localizedDescription)")
        }
    }

    func stopRealtime() {
        shouldMaintainRealtime = false
        reconnectAttempt = 0

        retryTask?.cancel()
        retryTask = nil
        realtimeTask?.cancel()
        realtimeTask = nil
        isRealtimeConnected = false

        let pChannel = parkingsChannel
        let rChannel = reservationsChannel
        parkingsChannel = nil
        reservationsChannel = nil

        Task {
            if let pChannel { await pChannel.unsubscribe() }
            if let rChannel { await rChannel.unsubscribe() }
        }

        Logger.admin.info("Admin realtime stopped")
    }
}
