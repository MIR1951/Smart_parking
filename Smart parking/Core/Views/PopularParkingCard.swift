//
//  PopularParkingCard.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import SwiftUI

struct PopularParkingCard: View {
    @Environment(LocalizationManager.self) private var loc
    let parking: Parking
    let availability: ParkingAvailability?
    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)? = nil

    private var spotsText: String {
        if let avail = availability {
            return "\(avail.available)/\(avail.total)"
        }
        return "--"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with overlays
            ZStack(alignment: .topLeading) {
                CachedAsyncImage(url: parking.imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.Palette.brand.opacity(0.15),
                                    AppTheme.Palette.brandLight.opacity(0.08),
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "car.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AppTheme.Palette.brand.opacity(0.3))
                        )
                }
                .frame(width: 220, height: 140)
                .clipped()
                .overlay(AppTheme.Gradient.cardOverlay)

                // Rating badge
                if let rating = parking.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .background(
                                Capsule().fill(.ultraThinMaterial)
                            )
                    )
                    .clipShape(Capsule())
                    .padding(10)
                }

                if let onToggleFavorite {
                    HStack {
                        Spacer()
                        Button {
                            AppTheme.Haptic.light()
                            onToggleFavorite()
                        } label: {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(
                                    isFavorite
                                        ? LinearGradient(
                                            colors: [AppTheme.Palette.favoriteAccent, AppTheme.Palette.danger],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        : LinearGradient(
                                            colors: [.white, .white.opacity(0.92)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                )
                                .symbolEffect(.bounce, value: isFavorite)
                                .frame(width: 32, height: 32)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                    }
                }
            }

            // Info section
            VStack(alignment: .leading, spacing: 8) {
                Text(parking.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Palette.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.Palette.brandLight)
                    Text(parking.address ?? "")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                        .lineLimit(1)
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
                        + Text("/\(loc.str(.bookingsPerHour))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.Palette.textSecondary)

                    Spacer()

                    // Availability
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
            .padding(14)
        }
        .frame(width: 220)
        .background(AppTheme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                .stroke(AppTheme.Palette.border, lineWidth: 1)
        )
        .appShadow(AppTheme.Shadow.medium())
    }

    private var availabilityColor: Color {
        guard let avail = availability else { return AppTheme.Palette.textTertiary }
        let ratio = Double(avail.available) / Double(max(avail.total, 1))
        if ratio > 0.3 { return AppTheme.Palette.success }
        if ratio > 0 { return AppTheme.Palette.warning }
        return AppTheme.Palette.danger
    }
}
