//
//  ParkingsStore.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 24/01/26.
//


import Foundation
import CoreLocation
internal import Combine

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

    func load(userLocation: CLLocation?, force: Bool = false) {
        if hasLoadedOnce && !force { return }

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
            print("ERROR fetching parkings:", error)
        }
    }
    
    private func updateParkings(_ items: [Parking], userLocation: CLLocation?) {
        self.all = items
        self.popular = Array(items.filter { ($0.is_popular ?? false) }.prefix(10))
        
        if let userLocation {
            let sorted = items.sorted { a, b in
                CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: userLocation)
                <
                CLLocation(latitude: b.latitude, longitude: b.longitude).distance(from: userLocation)
            }
            self.nearby = Array(sorted.prefix(20))
        } else {
            self.nearby = Array(items.prefix(20))
        }
    }
    func refresh(userLocation: CLLocation?) async {
        loadTask?.cancel()
        await loadAsync(userLocation: userLocation, force: true)
    }
}
