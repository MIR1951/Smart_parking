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

    @State private var showEReceipt = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4)
                }

                Spacer()

                Text("Payment")
                    .font(.headline)

                Spacer()

                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()

            // Success Icon
            ZStack {
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

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    showEReceipt = true
                } label: {
                    Text("Download E-Receipt")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.purple)
                        .cornerRadius(26)
                }

                Button {
                    showEReceipt = true
                } label: {
                    Text("View E-Ticket")
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showEReceipt) {
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
