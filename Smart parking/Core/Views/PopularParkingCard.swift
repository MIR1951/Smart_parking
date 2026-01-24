//
//  PopularParkingCard.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//

import SwiftUI


import SwiftUI

struct PopularParkingCard: View {
   @EnvironmentObject var availabilityStore: ParkingAvailabilityStore
    let parking: Parking
    

//   var availableSpots: Int {
//    availabilityStore.available[parking.id]
//    ?? max(parking.total_spots - (parking.live_occupancy ?? 0), 0) // fallback
//}

    var body: some View {
        let a = availabilityStore.availability(for: parking.id)
        VStack(alignment: .leading, spacing: 8) {

            ZStack(alignment: .topLeading) {

                AsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { phase in
                    switch phase {
                    case .empty:
                        // loading placeholder (xuddi oldingidek)
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))

                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()

                    case .failure:
                        // fallback (timeout bo‘lsa ham chiroyli)
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))

                            Image(systemName: "photo")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundColor(.gray.opacity(0.8))
                        }

                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
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
                .foregroundColor(.primary)

            Text(parking.name)
                .font(.headline)

            HStack {
                Text("$\(parking.price_per_hour, specifier: "%.2f")")
                    .foregroundColor(.primary)
                Text("/hr")
                    .foregroundColor(.gray)
            }

            HStack {
                Label("5 mins", systemImage: "clock")
                Spacer()
                Label("\(a?.availableSpots ?? 0) Spots", systemImage: "car.fill")
            }
            .foregroundColor(.gray)
            .font(.caption)
        }
        .frame(width: 220)
        .padding(12)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 3)
    }
}

