//
//  Extensions.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//

import CoreLocation
import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)

        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

}

extension Parking {
    func distanceMeters(from userLocation: CLLocation) -> Double {
        let parkingLoc = CLLocation(latitude: latitude, longitude: longitude)
        return userLocation.distance(from: parkingLoc)
    }

    /// Convenience: URL built from thumbnail_url
    var imageUrl: URL? {
        guard let str = thumbnail_url, !str.isEmpty else { return nil }
        return URL(string: str)
    }

    /// Formatted price string, e.g. "15000 so'm"
    var formattedPrice: String {
        "\(Int(price_per_hour)) \(LocalizationManager.shared.str(.walletCurrency))"
    }
}

extension ParkingAvailability {
    /// Alias matching naming used in card views
    var available: Int { availableSpots }
    /// Approximate total spots for availability ratio
    var total: Int { availableSpots + liveOccupancy + reservedSpots }
}
