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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            ZStack(alignment: .topLeading) {

                CachedAsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 220, height: 140)
                .clipped()
                .cornerRadius(15)

                // Rating badge
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(parking.rating ?? 1.0, specifier: "%.1f")")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                .padding(6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(10)
                .padding(8)
            }

            Text("Car Parking")
                .font(.caption)
                .foregroundColor(AppTheme.Palette.brand)

            Text(parking.name)
                .font(.headline)
                .foregroundColor(AppTheme.Palette.textPrimary)

            HStack {
                Text("$\(parking.price_per_hour, specifier: "%.2f")")
                    .foregroundColor(AppTheme.Palette.brand)
                Text("/hr")
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }

            HStack {
                Label("5 mins", systemImage: "clock")
                Spacer()
                Label("\(availableSpots) Spots", systemImage: "car.fill")
            }
            .foregroundColor(AppTheme.Palette.textSecondary)
            .font(.caption)
        }
        .frame(width: 220)
        .padding(12)
        .appCard()
    }
}
