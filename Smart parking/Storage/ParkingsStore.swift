//
//  ParkingsStore.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 24/01/26.
//

internal import Combine
import CoreLocation
import Foundation

@MainActor
final class ParkingsStore: ObservableObject {

    @Published private(set) var all: [Parking] = []
    @Published private(set) var popular: [Parking] = []
    @Published private(set) var nearby: [Parking] = []
    @Published private(set) var availableCities: [String] = []
    @Published private(set) var selectedCity: String = "Tashkent"
    @Published private(set) var resolvedInitialCity = false

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var reloadToken = UUID()

    private let service = ParkingService()
    private var sourceAll: [Parking] = []
    private var loadTask: Task<Void, Never>?
    private var hasLoadedOnce = false
    private var lastUserLocation: CLLocation?
    private var activeRequestID = UUID()

    func load(userLocation: CLLocation?, force: Bool = false) {
        if hasLoadedOnce && !force {
            recomputeNearby(userLocation: userLocation)
            return
        }

        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.loadAsync(userLocation: userLocation, force: force)
        }
    }

    func loadAndWait(userLocation: CLLocation?, force: Bool = false) async throws {
        if hasLoadedOnce && !force {
            recomputeNearby(userLocation: userLocation)
            return
        }

        loadTask?.cancel()
        try await loadAsyncOrThrow(userLocation: userLocation, force: force)
    }

    private func loadAsync(userLocation: CLLocation?, force: Bool) async {
        if hasLoadedOnce && !force { return }

        let requestID = UUID()
        activeRequestID = requestID

        isLoading = true
        errorMessage = nil

        // 1) Avval cache dan yuklaymiz (tezkor UI)
        if !force, let cached = ParkingCache.shared.load() {
            guard activeRequestID == requestID else { return }
            updateParkings(cached, userLocation: userLocation)
            // Darhol UI ko'rsatamiz, lekin network dan ham yangilaymiz
        }

        defer {
            if activeRequestID == requestID {
                isLoading = false
            }
        }

        // 2) Har doim network dan yuklaymiz (yangi parkinglar ko'rinishi uchun)
        do {
            let items = try await service.fetchParkings()
            guard !Task.isCancelled, activeRequestID == requestID else { return }

            // Cache ga saqlaymiz
            ParkingCache.shared.save(items)

            updateParkings(items, userLocation: userLocation)
            self.hasLoadedOnce = true
            self.reloadToken = UUID()

        } catch {
            guard !Task.isCancelled, activeRequestID == requestID else { return }
            if let urlError = error as? URLError, urlError.code == .cancelled { return }
            // Agar cache dan yuklangan bo'lsa, xato ko'rsatmaymiz
            if all.isEmpty {
                errorMessage = "Ma'lumotlar yuklanmadi"
            }
            // Cache dan yuklagan bo'lsak, hasLoadedOnce ni belgilaymiz
            if !all.isEmpty {
                hasLoadedOnce = true
            }
        }
    }

    private func loadAsyncOrThrow(userLocation: CLLocation?, force: Bool) async throws {
        if hasLoadedOnce && !force { return }

        let requestID = UUID()
        activeRequestID = requestID

        isLoading = true
        errorMessage = nil

        defer {
            if activeRequestID == requestID {
                isLoading = false
            }
        }

        do {
            let items = try await service.fetchParkings()
            guard !Task.isCancelled, activeRequestID == requestID else { return }

            ParkingCache.shared.save(items)
            updateParkings(items, userLocation: userLocation)
            hasLoadedOnce = true
            reloadToken = UUID()
        } catch {
            guard !Task.isCancelled, activeRequestID == requestID else { return }
            if let urlError = error as? URLError, urlError.code == .cancelled {
                throw CancellationError()
            }
            if all.isEmpty {
                errorMessage = "Ma'lumotlar yuklanmadi"
            }
            throw error
        }
    }

    private func updateParkings(_ items: [Parking], userLocation: CLLocation?) {
        sourceAll = items
        availableCities = collectCities(from: items)
        if !availableCities.contains(where: { cityMatches($0, selectedCity) }) {
            selectedCity = availableCities.first ?? "Tashkent"
        }
        applyFilters(userLocation: userLocation)
    }
    func refresh(userLocation: CLLocation?) async {
        loadTask?.cancel()
        await loadAsync(userLocation: userLocation, force: true)
    }

    func recomputeNearby(userLocation: CLLocation?) {
        lastUserLocation = userLocation ?? lastUserLocation

        let cityItems = filteredBySelectedCity()
        all = cityItems
        popular = Array(cityItems.filter { ($0.is_popular ?? false) }.prefix(10))

        guard let userLocation = lastUserLocation else {
            nearby = Array(cityItems.prefix(20))
            return
        }

        let sorted = cityItems.sorted { a, b in
            CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: userLocation)
                < CLLocation(latitude: b.latitude, longitude: b.longitude).distance(
                    from: userLocation)
        }
        nearby = Array(sorted.prefix(20))
    }

    func setSelectedCity(_ city: String) {
        let normalized = normalizeCity(city)
        guard normalized != selectedCity else { return }
        selectedCity = normalized
        applyFilters(userLocation: lastUserLocation)
    }

    func bootstrapCity(using placeName: String?, fallback: String = "Tashkent") {
        guard !resolvedInitialCity else { return }

        let requested = cityFrom(placeName: placeName) ?? normalizeCity(fallback)
        let availableRequested = availableCities.first(where: { cityMatches($0, requested) })
        let availableFallback = availableCities.first(where: { cityMatches($0, fallback) })

        selectedCity =
            availableRequested
            ?? availableFallback
            ?? availableCities.first
            ?? normalizeCity(fallback)

        resolvedInitialCity = true
        applyFilters(userLocation: lastUserLocation)
    }

    func applyFilters(userLocation: CLLocation?) {
        recomputeNearby(userLocation: userLocation)
    }

    private func filteredBySelectedCity() -> [Parking] {
        sourceAll.filter { cityMatches($0.city, selectedCity) }
    }

    private func collectCities(from items: [Parking]) -> [String] {
        let set = Set(items.map { normalizeCity($0.city) }.filter { !$0.isEmpty })
        return set.sorted()
    }

    private func normalizeCity(_ city: String) -> String {
        city.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cityMatches(_ lhs: String, _ rhs: String) -> Bool {
        lhs.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare(
            rhs.trimmingCharacters(in: .whitespacesAndNewlines)
        ) == .orderedSame
    }

    private func cityFrom(placeName: String?) -> String? {
        guard let placeName else { return nil }
        let source = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return nil }
        let city = source.split(separator: ",").first.map(String.init)?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return city.flatMap { $0.isEmpty ? nil : $0 }
    }
}
