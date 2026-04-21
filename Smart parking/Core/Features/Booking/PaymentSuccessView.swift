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
    let reservationStartTime: Date

    // Callback to dismiss entire booking flow
    var onBackToHome: (() -> Void)?

    @Environment(AppCoordinator.self) private var coordinator
    @State private var showEReceipt = false
    @State private var animateSuccess = false
    private let loc = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header - faqat title
                HStack {
                    Spacer()
                    Text(loc.str(.successPayment))
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
                    .scaleEffect(animateSuccess ? 1.06 : 0.94)
                    .opacity(animateSuccess ? 1 : 0.72)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: animateSuccess
                    )

                Circle()
                    .fill(AppTheme.Palette.brand)
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
                    .symbolEffect(.bounce.up.byLayer, value: animateSuccess)
            }
            .appReveal(0.06)

            Text(loc.str(.successTitle))
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 24)
                .appReveal(0.10)

            Text(loc.str(.successMessage))
                .font(.subheadline)
                .foregroundColor(AppTheme.Palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 32)
                .appReveal(0.12)

            // Reservation ID
            HStack {
                Text(LocalizationManager.shared.str(.successReservationId))
                    .foregroundColor(AppTheme.Palette.textSecondary)
                Text(reservationId.uuidString.prefix(8).uppercased())
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .padding(.top, 16)
            .appReveal(0.15)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                // View E-Receipt (opens sheet)
                AppPrimaryButton(title: loc.str(.successViewReceipt)) {
                    showEReceipt = true
                }

                // Back to Home
                AppGhostButton(title: loc.str(.successBackToHome)) {
                    if let onBackToHome {
                        onBackToHome()
                    } else {
                        // Fallback - coordinator orqali
                        coordinator.goToHome()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .appReveal(0.18)
        }
        .background(AppAnimatedBackground())
        .navigationBarHidden(true)
        .sheet(isPresented: $showEReceipt) {
            EReceiptView(
                parking: parking,
                vehicle: vehicle,
                selectedMinutes: selectedMinutes,
                paymentMethod: paymentMethod,
                reservationId: reservationId,
                reservationStartTime: reservationStartTime
            )
        }
        .onAppear {
            animateSuccess = true
            AppTheme.Haptic.success()
        }
    }
}
