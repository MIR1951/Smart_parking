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

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var reloadToken = UUID()

    private let service = ParkingService()
    private var loadTask: Task<Void, Never>?
    private var hasLoadedOnce = false
    private var lastUserLocation: CLLocation?

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

    private func loadAsync(userLocation: CLLocation?, force: Bool) async {
        if hasLoadedOnce && !force { return }

        isLoading = true
        errorMessage = nil

        // 1) Avval cache dan yuklaymiz (tezkor UI)
        if !force, let cached = ParkingCache.shared.load() {
            updateParkings(cached, userLocation: userLocation)
            hasLoadedOnce = true
            isLoading = false

            // Agar cache fresh bo'lsa, network ga bormaymiz
            if ParkingCache.shared.isFresh() {
                return
            }
            // Cache stale - background da yangilaymiz
        }

        defer { isLoading = false }

        // 2) Network dan yuklaymiz
        do {
            let items = try await service.fetchParkings()

            // Cache ga saqlaymiz
            ParkingCache.shared.save(items)

            updateParkings(items, userLocation: userLocation)
            self.hasLoadedOnce = true
            self.reloadToken = UUID()

        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled { return }
            // Agar cache dan yuklangan bo'lsa, xato ko'rsatmaymiz
            if all.isEmpty {
                errorMessage = "Ma'lumotlar yuklanmadi"
            }

        }
    }

    private func updateParkings(_ items: [Parking], userLocation: CLLocation?) {
        self.all = items
        self.popular = Array(items.filter { ($0.is_popular ?? false) }.prefix(10))

        recomputeNearby(userLocation: userLocation)
    }
    func refresh(userLocation: CLLocation?) async {
        loadTask?.cancel()
        await loadAsync(userLocation: userLocation, force: true)
    }

    func recomputeNearby(userLocation: CLLocation?) {
        lastUserLocation = userLocation ?? lastUserLocation

        guard let userLocation = lastUserLocation else {
            nearby = Array(all.prefix(20))
            return
        }

        let sorted = all.sorted { a, b in
            CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: userLocation)
                < CLLocation(latitude: b.latitude, longitude: b.longitude).distance(
                    from: userLocation)
        }
        nearby = Array(sorted.prefix(20))
    }
}
