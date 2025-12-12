//
//  BookingSheet.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//


import SwiftUI

struct BookingSheet: View {
    let parking: Parking
    @State private var duration = 60
    
    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.3))
                .padding(.top, 8)

            Text("Select Duration")
                .font(.system(size: 22, weight: .bold))

            DurationPicker(duration: $duration)

            Button {
                Task {
                    try await ReservationManager().createReservation(
                        parkingId: parking.id,
                        durationMinutes: duration
                    )
                }
            } label: {
                Text("Confirm Booking")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .cornerRadius(16)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
    }
}
