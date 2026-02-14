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

    var body: some View {
        VStack(spacing: 0) {
            // Header - faqat title
            HStack {
                Spacer()
                Text(LocalizationManager.shared.str(.successPayment))
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)

            Spacer()

            // Success Icon with animation
            ZStack {
                Circle()
                    .fill(AppTheme.Palette.brandSoft)
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(AppTheme.Palette.brand)
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(LocalizationManager.shared.str(.successTitle))
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 24)

            Text(LocalizationManager.shared.str(.successMessage))
                .font(.subheadline)
                .foregroundColor(AppTheme.Palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 32)

            // Reservation ID
            HStack {
                Text(LocalizationManager.shared.str(.successReservationId))
                    .foregroundColor(AppTheme.Palette.textSecondary)
                Text(reservationId.uuidString.prefix(8).uppercased())
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .padding(.top, 16)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                // View E-Receipt (opens sheet)
                AppPrimaryButton(title: "View E-Receipt") {
                    showEReceipt = true
                }

                // Back to Home
                AppGhostButton(title: "Back to Home") {
                    if let onBackToHome {
                        onBackToHome()
                    } else {
                        // Fallback - coordinator orqali
                        AppCoordinator.shared.goToHome()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(AppTheme.Palette.pageBackground.ignoresSafeArea())
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
