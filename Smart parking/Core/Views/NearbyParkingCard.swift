//
//  NearbyParkingCard.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import SwiftUI

struct NearbyParkingCard: View {
    @Environment(LocalizationManager.self) private var loc
    let parking: Parking
    let availability: ParkingAvailability?
    var distance: Double? = nil
    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)? = nil

    private var spotsText: String {
        if let avail = availability {
            return "\(avail.available)/\(avail.total)"
        }
        return "--"
    }

    private var ratingValue: Double {
        parking.rating ?? 5.0
    }

    var body: some View {
        HStack(spacing: 14) {
            // Parking image
            CachedAsyncImage(url: parking.imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Palette.brand.opacity(0.12),
                                AppTheme.Palette.brandLight.opacity(0.06),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "car.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.Palette.brand.opacity(0.3))
                    )
            }
            .frame(width: 90, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))

            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(parking.name)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Palette.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                  
                }

                HStack(spacing: 5) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.Palette.brandLight)
                    Text(parking.address ?? "")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                        .lineLimit(1)

                    if let distance {
                        DistanceBadge(meters: distance)
                    }
                }

                if let availability {
                    OccupancyBar(available: availability.available, total: availability.total)
                        .padding(.top, 2)
                }

                HStack {
                    // Price
                    Text(parking.formattedPrice)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                         Text("/\(loc.str(.bookingsPerHour))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.Palette.textSecondary)

                    Spacer()

                  
                }
            }

            Spacer(minLength: 0)

            VStack{
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.Palette.warning)
                    Text(String(format: "%.1f", ratingValue))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(AppTheme.Palette.surfaceSecondary)
                .clipShape(Capsule())
                // Favorite button
                if let onToggleFavorite {
                    Button {
                        AppTheme.Haptic.light()
                        onToggleFavorite()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundStyle(
                                isFavorite
                                    ? LinearGradient(
                                        colors: [AppTheme.Palette.favoriteAccent, AppTheme.Palette.danger],
                                        startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(
                                        colors: [
                                            AppTheme.Palette.textTertiary,
                                            AppTheme.Palette.textTertiary,
                                        ],
                                        startPoint: .top, endPoint: .bottom)
                            )
                            .symbolEffect(.bounce, value: isFavorite)
                            .frame(width: 34, height: 34)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                // Spots indicator
                                  HStack(spacing: 4) {
                                      Circle()
                                          .fill(availabilityColor)
                                          .frame(width: 6, height: 6)
                                      Text(spotsText)
                                          .font(.system(size: 11, weight: .semibold, design: .rounded))
                                          .foregroundColor(AppTheme.Palette.textSecondary)
                                  }
            }
        }
        .padding(12)
        .background(AppTheme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                .stroke(AppTheme.Palette.border, lineWidth: 1)
        )
        .appShadow(AppTheme.Shadow.small())
    }

    private var availabilityColor: Color {
        guard let avail = availability else { return AppTheme.Palette.textTertiary }
        let ratio = Double(avail.available) / Double(max(avail.total, 1))
        if ratio > 0.3 { return AppTheme.Palette.success }
        if ratio > 0 { return AppTheme.Palette.warning }
        return AppTheme.Palette.danger
    }
}
