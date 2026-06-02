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

    // MARK: - Computed

    private var ratingText: String {
        String(format: "%.1f", parking.rating ?? 5.0)
    }

    private var distanceText: String? {
        guard let d = distance else { return nil }
        return d < 1000 ? "\(Int(d)) m" : String(format: "%.1f km", d / 1000)
    }

    private var spotsColor: Color {
        guard let avail = availability else { return AppTheme.Palette.textTertiary }
        let ratio = Double(avail.available) / Double(max(avail.total, 1))
        if ratio > 0.3 { return AppTheme.Palette.success }
        if ratio > 0 { return AppTheme.Palette.warning }
        return AppTheme.Palette.danger
    }

    private var spotsLabel: String {
        guard let avail = availability else { return "–" }
        return "\(avail.available)/\(avail.total)"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            mainRow
            separator
            bottomBar
        }
        .glassCard()
    }

    // MARK: - Main row

    private var mainRow: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail
            infoStack
            Spacer(minLength: 0)
            favoriteButton
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    // MARK: - Thumbnail

    private var thumbnail: some View {
        CachedAsyncImage(url: parking.imageUrl) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Palette.brand.opacity(0.13),
                            AppTheme.Palette.brandLight.opacity(0.06),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Image(systemName: "car.2.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.Palette.brand.opacity(0.28))
                )
        }
        .frame(width: 82, height: 82)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
    }

    // MARK: - Info

    private var infoStack: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Name
            Text(parking.name)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Palette.textPrimary)
                .lineLimit(1)

            // Address
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.Palette.brandLight)
                Text(parking.address ?? "")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            // Rating + distance
            HStack(spacing: 10) {
                // Rating
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.Palette.warning)
                    Text(ratingText)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }

                // Distance
                if let distanceText {
                    HStack(spacing: 3) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.Palette.brand)
                        Text(distanceText)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.Palette.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Favorite

    private var favoriteButton: some View {
        Group {
            if let onToggleFavorite {
                Button {
                    AppTheme.Haptic.light()
                    onToggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            isFavorite
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppTheme.Palette.favoriteAccent, AppTheme.Palette.danger],
                                    startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(AppTheme.Palette.textTertiary)
                        )
                        .symbolEffect(.bounce, value: isFavorite)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 30, height: 30)
                        .background(AppTheme.Palette.surfaceSecondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Separator

    private var separator: some View {
        Rectangle()
            .fill(AppTheme.Palette.border)
            .frame(height: 1)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(alignment: .center) {
            // Availability
            HStack(spacing: 6) {
                Circle()
                    .fill(spotsColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: spotsColor.opacity(0.5), radius: 4)
                Text(spotsLabel)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.Palette.textSecondary)
                Text(loc.str(.detailAvailable))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppTheme.Palette.textTertiary)
            }

            Spacer()

            // Price
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(parking.formattedPrice)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("/\(loc.str(.bookingsPerHour))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.Palette.textTertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
