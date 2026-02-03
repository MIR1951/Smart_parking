//
//  PaymentSuccessView.swift
//  Smart parking
//
//  To'lov muvaffaqiyatli sahifasi
//

import SwiftUI

struct PaymentSuccessView: View {
    let parking: Parking
    let vehicle: Vehicle
    let selectedMinutes: Int
    let paymentMethod: PaymentMethod
    let reservationId: UUID

    // Callback to dismiss entire booking flow
    var onBackToHome: (() -> Void)?

    @State private var showEReceipt = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header - faqat title
            HStack {
                Spacer()
                Text("Payment")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)

            Spacer()

            // Success Icon with animation
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(Color.purple)
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("Payment Successful!")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 24)

            Text("Your Parking Slot Successfully Booked.\nYou can check your booking on Home Menu.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 32)

            // Reservation ID
            HStack {
                Text("Reservation ID:")
                    .foregroundColor(.gray)
                Text(reservationId.uuidString.prefix(8).uppercased())
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .padding(.top, 16)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                // View E-Receipt (opens sheet)
                Button {
                    showEReceipt = true
                } label: {
                    Text("View E-Receipt")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.purple)
                        .cornerRadius(26)
                }

                // Back to Home
                Button {
                    if let onBackToHome {
                        onBackToHome()
                    } else {
                        // Fallback - coordinator orqali
                        AppCoordinator.shared.goToHome()
                    }
                } label: {
                    Text("Back to Home")
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(26)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showEReceipt) {
            EReceiptView(
                parking: parking,
                vehicle: vehicle,
                selectedMinutes: selectedMinutes,
                paymentMethod: paymentMethod,
                reservationId: reservationId
            )
        }
    }
}
