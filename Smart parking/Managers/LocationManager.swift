import CoreLocation
internal import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var placeName: String = "Unknown"

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var didStartUpdating = false
    private var lastGeocodedLocation: CLLocation?

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
        print("DEBUG: auth ->", authorizationStatus.rawValue)

        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingIfNeeded()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            placeName = "Location Off"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        print("DEBUG: didUpdateLocations ->", loc.coordinate.latitude, loc.coordinate.longitude)

        location = loc
        placeName = String(format: "%.4f, %.4f", loc.coordinate.latitude, loc.coordinate.longitude)
        // ✅ 1 marta olgach stop
        manager.stopUpdatingLocation()
        didStartUpdating = false

        // ✅ Reverse geocode (city/country)
        reverseGeocodeIfNeeded(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error)
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

        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, error in
            guard let self else { return }
            if let _ = error { return }

            let pm = placemarks?.first
            let city = pm?.locality ?? pm?.administrativeArea
            let country = pm?.country

            let text = [city, country].compactMap { $0 }.joined(separator: ", ")
            if !text.isEmpty {
                Task { @MainActor in
                    self.placeName = text
                }
            }
        }
    }
}
