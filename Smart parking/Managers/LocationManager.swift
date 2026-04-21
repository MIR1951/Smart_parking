 import Combine
import CoreLocation
import MapKit

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var placeName: String = "Unknown"

    private let manager = CLLocationManager()
    private var didStartUpdating = false
    private var lastGeocodedLocation: CLLocation?
    private var reverseGeocodeTask: Task<Void, Never>?

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingIfNeeded()
        default:
            // denied/restricted
            placeName = "Location Off"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingIfNeeded()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            placeName = "Location Off"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }

        location = loc
        placeName = String(format: "%.4f, %.4f", loc.coordinate.latitude, loc.coordinate.longitude)
        // ✅ 1 marta olgach stop
        manager.stopUpdatingLocation()
        didStartUpdating = false

        // ✅ Reverse geocode (city/country)
        reverseGeocodeIfNeeded(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {

        manager.stopUpdatingLocation()
        didStartUpdating = false
        if placeName == "Unknown" { placeName = "Location Error" }
    }

    private func startUpdatingIfNeeded() {
        guard didStartUpdating == false else { return }
        didStartUpdating = true
        manager.startUpdatingLocation()
    }

    private func reverseGeocodeIfNeeded(_ loc: CLLocation) {
        // Juda ko‘p geocode bo‘lib ketmasin
        if let last = lastGeocodedLocation, last.distance(from: loc) < 200 { return }
        lastGeocodedLocation = loc

        reverseGeocodeTask?.cancel()
        reverseGeocodeTask = Task { [weak self] in
            guard let self else { return }
            do {
                guard let request = MKReverseGeocodingRequest(location: loc) else { return }
                let mapItems = try await request.mapItems
                let addressRepresentations = mapItems.first?.addressRepresentations
                let city = addressRepresentations?.cityWithContext
                let country = addressRepresentations?.regionName
                let fullAddress =
                    mapItems.first?.address?.shortAddress
                    ?? mapItems.first?.address?.fullAddress

                let text = [city, country].compactMap { $0 }.joined(separator: ", ")
                let resolvedText = text.isEmpty ? (fullAddress ?? "") : text
                guard !resolvedText.isEmpty else { return }

                await MainActor.run {
                    self.placeName = resolvedText
                }
            } catch is CancellationError {
                // ignore cancellation
            } catch {

            }
        }
    }
}
