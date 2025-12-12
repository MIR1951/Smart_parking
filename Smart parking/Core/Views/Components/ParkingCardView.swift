//
//  ParkingCardView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//


import SwiftUI

struct ParkingCardView: View {
    let parking: ParkingStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // IMAGE
            AsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(height: 160)
            .clipped()
            .cornerRadius(16)
            
            // TEXT CONTENT
            VStack(alignment: .leading, spacing: 4) {
                Text(parking.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.darkText)

                Text(parking.address ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                // AVAILABLE BADGE
                HStack {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 8, height: 8)

                    Text("\(parking.available_spots) spots available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 5)
    }
}
