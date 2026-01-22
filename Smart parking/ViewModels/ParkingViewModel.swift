import Foundation
import CoreLocation
internal import Combine

@MainActor
final class ParkingViewModel: ObservableObject {
    @Published var popularParkings: [Parking] = []
    @Published var nearbyParkings: [Parking] = []

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoadedOnce = false

    private let service = ParkingService()
    private var loadTask: Task<Void, Never>?

    /// Main entry
    func loadParkings(userLocation: CLLocation?, force: Bool = false) {
        // Agar oldin yuklangan bo‘lsa va force bo‘lmasa – qayta yuklama
        if hasLoadedOnce && force == false { return }

        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.loadParkingsAsync(userLocation: userLocation, force: force)
        }
    }

    private func loadParkingsAsync(userLocation: CLLocation?, force: Bool) async {
        // Task boshlanishidan oldin ham tekshirib qo‘yamiz (race oldini oladi)
        if hasLoadedOnce && force == false { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let all = try await service.fetchParkings()
            hasLoadedOnce = true

            // Popular
            popularParkings = Array(all.filter { ($0.is_popular ?? false) }.prefix(10))

            // Nearby
            if let userLocation {
                let sorted = all.sorted { a, b in
                    let da = CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: userLocation)
                    let db = CLLocation(latitude: b.latitude, longitude: b.longitude).distance(from: userLocation)
                    return da < db
                }
                nearbyParkings = Array(sorted.prefix(20))
            } else {
                nearbyParkings = Array(all.prefix(20))
            }

        } catch {
            // cancelled normal holat
            if let urlError = error as? URLError, urlError.code == .cancelled { return }
            errorMessage = "Ma’lumotlar yuklanmadi"
            print("ERROR fetching parkings:", error)
        }
    }
}
