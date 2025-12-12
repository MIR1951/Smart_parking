//
//  PopularParkingCard.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//

import SwiftUI


struct PopularParkingCard: View {

    let parking: Parking

    var availableSpots: Int {
        max(parking.total_spots - (parking.live_occupancy ?? 0), 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            ZStack(alignment: .topLeading) {

                AsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.2))
                }
                .frame(width: 220, height: 140)
                .clipped()
                .cornerRadius(15)

                // Rating badge
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("4.9")
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
                Label("\(availableSpots) Spots", systemImage: "car.fill")
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
