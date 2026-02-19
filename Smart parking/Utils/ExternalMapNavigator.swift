//
//  ExternalMapNavigator.swift
//  Smart parking
//
//  Created by Smart Parking on 20/02/26.
//

import CoreLocation
import MapKit

#if canImport(UIKit)
import UIKit
#endif

enum ExternalMapNavigator {
    enum App: CaseIterable, Hashable {
        case apple
        case google
        case yandex

        var title: String {
            switch self {
            case .apple:
                return "Apple Maps"
            case .google:
                return "Google Maps"
            case .yandex:
                return "Yandex Maps"
            }
        }
    }

    static func availableApps() -> [App] {
        [.apple, .google, .yandex]
    }

    static func open(
        _ app: App,
        coordinate: CLLocationCoordinate2D,
        name: String?
    ) {
        switch app {
        case .apple:
            openAppleMaps(coordinate: coordinate, name: name)
        case .google:
            openGoogleMaps(coordinate: coordinate)
        case .yandex:
            openYandexMaps(coordinate: coordinate)
        }
    }

    private static func openAppleMaps(
        coordinate: CLLocationCoordinate2D,
        name: String?
    ) {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        destination.name = name

        destination.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ]
        )
    }

    private static func openGoogleMaps(coordinate: CLLocationCoordinate2D) {
        let lat = coordinate.latitude
        let lon = coordinate.longitude

        if canOpenGoogleMapsURL,
            let url = URL(string: "comgooglemaps://?daddr=\(lat),\(lon)&directionsmode=driving")
        {
            open(url)
            return
        }

        if let webURL = URL(
            string: "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lon)")
        {
            open(webURL)
        }
    }

    private static func openYandexMaps(coordinate: CLLocationCoordinate2D) {
        let lat = coordinate.latitude
        let lon = coordinate.longitude

        if canOpenYandexMapsURL,
            let url = URL(string: "yandexmaps://maps.yandex.com/?rtext=~\(lat),\(lon)&rtt=auto")
        {
            open(url)
            return
        }

        if let webURL = URL(string: "https://yandex.com/maps/?rtext=~\(lat),\(lon)&rtt=auto") {
            open(webURL)
        }
    }

    private static var canOpenGoogleMapsURL: Bool {
        canOpenScheme("comgooglemaps://")
    }

    private static var canOpenYandexMapsURL: Bool {
        canOpenScheme("yandexmaps://")
    }

    private static func canOpenScheme(_ scheme: String) -> Bool {
        #if canImport(UIKit)
        guard let url = URL(string: scheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
        #else
        return false
        #endif
    }

    private static func open(_ url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }
}
