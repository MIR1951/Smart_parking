//
//  ParkingsStore.swift
//  Smart parking
//

import Combine
import CoreLocation
import Foundation
import os
import Supabase

@MainActor
final class ParkingsStore: ObservableObject {

    @Published private(set) var all: [Parking] = []
    @Published private(set) var popular: [Parking] = []
    @Published private(set) var nearby: [Parking] = []
    @Published private(set) var nearbyRemote: [NearbyParking] = []
    @Published private(set) var availableCities: [String] = []
    @Published private(set) var selectedCity: String = "Tashkent"
    @Published private(set) var resolvedInitialCity = false

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var reloadToken = UUID()

    private let service = ParkingService()
    private var cityCache: [String: [Parking]] = [:]
    private var loadTask: Task<Void, Never>?
    private var nearbyTask: Task<Void, Never>?
    private var hasLoadedOnce = false
    private var lastUserLocation: CLLocation?
    private var activeRequestID = UUID()

    // Realtime
    private var realtimeTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var parkingsChannel: RealtimeChannelV2?
    private var shouldMaintainRealtime = false
    private var reconnectAttempt = 0

    func load(userLocation: CLLocation?, force: Bool = false) {
        if hasLoadedOnce && !force {
            recomputeNearby(userLocation: userLocation)
            return
        }
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            try? await self.performLoad(userLocation: userLocation, force: force, cacheFirst: true)
        }
    }

    func loadAndWait(userLocation: CLLocation?, force: Bool = false) async throws {
        if hasLoadedOnce && !force {
            recomputeNearby(userLocation: userLocation)
            return
        }
        loadTask?.cancel()
        try await performLoad(userLocation: userLocation, force: force, cacheFirst: false)
    }

    private func performLoad(userLocation: CLLocation?, force: Bool, cacheFirst: Bool) async throws {
        if hasLoadedOnce && !force { return }

        let requestID = UUID()
        activeRequestID = requestID
        isLoading = true
        errorMessage = nil

        defer {
            if activeRequestID == requestID { isLoading = false }
        }

        let city = selectedCity

        // Cache-first: city cache hit → instant UI
        if cacheFirst, !force, let cached = cityCache[city] {
            guard activeRequestID == requestID else { return }
            updateParkings(cached, userLocation: userLocation)
        } else if cacheFirst, !force, let cached = ParkingCache.shared.load() {
            guard activeRequestID == requestID else { return }
            let cityItems = cached.filter { cityMatches($0.city, city) }
            if !cityItems.isEmpty { updateParkings(cityItems, userLocation: userLocation) }
        }

        do {
            let items = try await service.fetchByCity(city)
            guard !Task.isCancelled, activeRequestID == requestID else { return }
            cityCache[city] = items
            ParkingCache.shared.save(items)
            updateParkings(items, userLocation: userLocation)
            hasLoadedOnce = true
            reloadToken = UUID()
        } catch {
            guard !Task.isCancelled, activeRequestID == requestID else { return }
            if let urlError = error as? URLError, urlError.code == .cancelled {
                if !cacheFirst { throw CancellationError() }
                return
            }
            Logger.parking.error("Load failed: \(error.localizedDescription)")
            if all.isEmpty { errorMessage = "Ma'lumotlar yuklanmadi" }
            if !all.isEmpty { hasLoadedOnce = true }
            if !cacheFirst { throw error }
        }
    }

    private func updateParkings(_ items: [Parking], userLocation: CLLocation?) {
        applyFilters(items: items, userLocation: userLocation)
    }

    func refresh(userLocation: CLLocation?) async {
        loadTask?.cancel()
        do {
            try await performLoad(userLocation: userLocation, force: true, cacheFirst: false)
        } catch {
            Logger.parking.error("Refresh failed: \(error.localizedDescription)")
        }
    }

    func loadAvailableCities() async {
        do {
            let cities = try await service.fetchDistinctCities()
            availableCities = cities
        } catch {
            Logger.parking.error("Cities fetch failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Yaqin parkinglar (earthdistance RPC)
    func refreshNearbyRemote(location: CLLocation, radiusKm: Double = 5, limit: Int = 20) {
        nearbyTask?.cancel()
        nearbyTask = Task { [weak self] in
            guard let self else { return }
            do {
                let items = try await self.service.fetchNearby(
                    lat: location.coordinate.latitude,
                    lng: location.coordinate.longitude,
                    radiusKm: radiusKm,
                    limit: limit
                )
                guard !Task.isCancelled else { return }
                self.nearbyRemote = items
            } catch {
                guard !Task.isCancelled else { return }
                Logger.parking.error("fetchNearby failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Realtime

    func startRealtime(userLocation: CLLocation? = nil) {
        shouldMaintainRealtime = true
        connectRealtimeIfNeeded(userLocation: userLocation)
    }

    private func connectRealtimeIfNeeded(userLocation: CLLocation? = nil) {
        guard shouldMaintainRealtime, realtimeTask == nil else { return }
        retryTask?.cancel()
        retryTask = nil

        let client = SB.shared.client

        realtimeTask = Task { [weak self] in
            guard let self else { return }

            let channel = client.realtimeV2.channel("parkings:public")
            let inserts = channel.postgresChange(
                InsertAction.self, schema: "public", table: "parkings"
            )
            let updates = channel.postgresChange(
                UpdateAction.self, schema: "public", table: "parkings"
            )
            let deletes = channel.postgresChange(
                DeleteAction.self, schema: "public", table: "parkings"
            )

            do {
                try await channel.subscribeWithError()
                self.parkingsChannel = channel
                self.reconnectAttempt = 0

                Logger.parking.info("Parkings realtime connected")

                await withTaskGroup(of: Void.self) { group in
                    group.addTask { [weak self] in
                        for await action in inserts {
                            await self?.handleRealtimeUpsert(action.record)
                        }
                    }
                    group.addTask { [weak self] in
                        for await action in updates {
                            await self?.handleRealtimeUpsert(action.record)
                        }
                    }
                    group.addTask { [weak self] in
                        for await action in deletes {
                            await self?.handleRealtimeDelete(action.oldRecord)
                        }
                    }
                }
            } catch is CancellationError {
                // intentional stop
            } catch {
                Logger.parking.error("Parkings realtime failed: \(error.localizedDescription)")
            }

            self.parkingsChannel = nil
            self.realtimeTask = nil
            self.scheduleReconnectIfNeeded(userLocation: userLocation)
        }
    }

    private func handleRealtimeUpsert(_ record: JSONObject) {
        guard let parking = try? record.decode(as: Parking.self, decoder: JSONDecoder.supabaseDecoder)
        else { return }

        let city = normalizeCity(parking.city)
        var cityItems = cityCache[city] ?? []
        if let idx = cityItems.firstIndex(where: { $0.id == parking.id }) {
            cityItems[idx] = parking
        } else {
            cityItems.append(parking)
        }
        cityCache[city] = cityItems

        if cityMatches(city, selectedCity) {
            applyFilters(items: cityItems, userLocation: lastUserLocation)
        }
    }

    private func handleRealtimeDelete(_ record: JSONObject) {
        guard case .string(let idStr) = record["id"], let id = UUID(uuidString: idStr) else {
            return
        }
        for (city, items) in cityCache {
            let filtered = items.filter { $0.id != id }
            if filtered.count != items.count {
                cityCache[city] = filtered
                if cityMatches(city, selectedCity) {
                    applyFilters(items: filtered, userLocation: lastUserLocation)
                }
            }
        }
    }

    private func scheduleReconnectIfNeeded(userLocation: CLLocation?) {
        guard shouldMaintainRealtime else { return }
        reconnectAttempt += 1
        let delay = min(pow(2.0, Double(reconnectAttempt)), 30.0)

        retryTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.connectRealtimeIfNeeded(userLocation: userLocation)
        }
    }

    func stopRealtime() {
        shouldMaintainRealtime = false
        reconnectAttempt = 0
        retryTask?.cancel()
        retryTask = nil
        realtimeTask?.cancel()
        realtimeTask = nil
        let ch = parkingsChannel
        parkingsChannel = nil
        Task { await ch?.unsubscribe() }
    }

    func recomputeNearby(userLocation: CLLocation?) {
        lastUserLocation = userLocation ?? lastUserLocation
        applyFilters(items: nil, userLocation: userLocation)
    }

    func setSelectedCity(_ city: String) {
        let normalized = normalizeCity(city)
        guard normalized != selectedCity else { return }
        selectedCity = normalized
        hasLoadedOnce = false

        // Instant update from city cache if available
        if let cached = cityCache[normalized] {
            applyFilters(items: cached, userLocation: lastUserLocation)
            hasLoadedOnce = true
        }
        load(userLocation: lastUserLocation, force: true)
    }

    func bootstrapCity(using placeName: String?, fallback: String = "Tashkent") {
        guard !resolvedInitialCity else { return }

        let requested = cityFrom(placeName: placeName) ?? normalizeCity(fallback)
        let allCities = availableCities

        let match = allCities.first(where: { cityMatches($0, requested) })
            ?? allCities.first(where: { cityMatches($0, fallback) })
            ?? allCities.first
            ?? normalizeCity(fallback)

        selectedCity = match
        resolvedInitialCity = true
        applyFilters(items: nil, userLocation: lastUserLocation)
    }

    func applyFilters(userLocation: CLLocation?) {
        applyFilters(items: nil, userLocation: userLocation)
    }

    private func applyFilters(items: [Parking]?, userLocation: CLLocation?) {
        let location = userLocation ?? lastUserLocation
        lastUserLocation = location ?? lastUserLocation

        let source = items ?? cityCache[selectedCity] ?? []
        all = source
        popular = Array(source.filter { $0.is_popular == true }.prefix(10))

        guard let loc = location else {
            nearby = Array(source.prefix(20))
            return
        }
        let sorted = source.sorted { a, b in
            CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: loc)
                < CLLocation(latitude: b.latitude, longitude: b.longitude).distance(from: loc)
        }
        nearby = Array(sorted.prefix(20))
    }

    // MARK: - Helpers

    private func normalizeCity(_ city: String) -> String {
        city.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cityMatches(_ lhs: String, _ rhs: String) -> Bool {
        lhs.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare(
            rhs.trimmingCharacters(in: .whitespacesAndNewlines)
        ) == .orderedSame
    }

    private func cityFrom(placeName: String?) -> String? {
        guard let placeName, !placeName.isEmpty else { return nil }
        return placeName.split(separator: ",").first
            .map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty()
    }
}

private extension String {
    func nilIfEmpty() -> String? { isEmpty ? nil : self }
}
