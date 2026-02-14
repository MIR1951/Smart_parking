//
//  PopularParkingCard.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//

import SwiftUI

struct PopularParkingCard: View {
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore
    let parking: Parking

    private var availableSpots: Int {
        availabilityStore.availability(for: parking.id)?.availableSpots
            ?? availabilityStore.available[parking.id]
            ?? max(parking.total_spots - (parking.live_occupancy ?? 0), 0)
    }

    private var isAvailable: Bool { availableSpots > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Image + overlay
            ZStack(alignment: .topLeading) {
                CachedAsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(AppTheme.Palette.surfaceSecondary)
                        .overlay(
                            Image(systemName: "car.fill")
                                .font(.title)
                                .foregroundColor(AppTheme.Palette.textTertiary)
                        )
                }
                .frame(width: 220, height: 140)
                .clipped()
                .overlay(AppTheme.Gradient.cardOverlay)
                .cornerRadius(AppTheme.Radius.medium)

                // Rating badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    Text("\(parking.rating ?? 1.0, specifier: "%.1f")")
                        .foregroundColor(.white)
                        .font(AppTheme.Typography.captionBold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial)
                .cornerRadius(AppTheme.Radius.xSmall)
                .padding(8)

                // Availability badge (bottom-right of image)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(
                                    isAvailable ? AppTheme.Palette.success : AppTheme.Palette.danger
                                )
                                .frame(width: 6, height: 6)
                            Text("\(availableSpots) spots")
                                .font(AppTheme.Typography.captionBold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(AppTheme.Radius.xSmall)
                        .padding(8)
                    }
                }
                .frame(width: 220, height: 140)
            }

            // Category
            Text(LocalizationManager.shared.str(.detailCarParking))
                .font(AppTheme.Typography.captionBold)
                .foregroundColor(AppTheme.Palette.brand)

            // Name
            Text(parking.name)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Palette.textPrimary)
                .lineLimit(1)

            // Price
            HStack(spacing: 2) {
                Text("$\(parking.price_per_hour, specifier: "%.2f")")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Palette.brand)
                Text(LocalizationManager.shared.str(.bookingsPerHour))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }
        }
        .frame(width: 220)
        .padding(12)
        .appCard()
    }
}
