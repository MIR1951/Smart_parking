//
//  ParkingCardComponents.swift
//  Smart parking
//
//  Shared card UI components: occupancy bar, distance badge.
//

import CoreLocation
import SwiftUI

// MARK: - Occupancy Bar

struct OccupancyBar: View {
    let available: Int
    let total: Int
    var height: CGFloat = 4

    private var ratio: Double {
        guard total > 0 else { return 0 }
        return Double(available) / Double(total)
    }

    private var color: Color {
        if ratio > 0.3 { return AppTheme.Palette.success }
        if ratio > 0 { return AppTheme.Palette.warning }
        return AppTheme.Palette.danger
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(AppTheme.Palette.surfaceSecondary)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(geo.size.width * min(ratio, 1.0), height))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Distance Badge

struct DistanceBadge: View {
    let meters: Double

    private var formatted: String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        }
        let km = meters / 1000
        return String(format: "%.1f km", km)
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "location.fill")
                .font(.system(size: 9, weight: .bold))
            Text(formatted)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundColor(AppTheme.Palette.brand)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.Palette.brandSoft)
        .clipShape(Capsule())
    }
}

extension Parking {
    func distance(from location: CLLocation?) -> Double? {
        guard let location else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude).distance(from: location)
    }
}
