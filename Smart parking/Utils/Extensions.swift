//
//  Extensions.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//

import Foundation
import SwiftUI
import CoreLocation


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

    static let primary = Color(hex: "#3A3DFF")
    static let primaryLight = Color(hex: "#6C7BFF")
    static let bgLight = Color(hex: "#F7F7F7")
    static let darkText = Color(hex: "#1E1E1E")
}


extension Parking {
    func distanceMeters(from userLocation: CLLocation) -> Double {
        let parkingLoc = CLLocation(latitude: latitude, longitude: longitude)
        return userLocation.distance(from: parkingLoc)
    }
}
