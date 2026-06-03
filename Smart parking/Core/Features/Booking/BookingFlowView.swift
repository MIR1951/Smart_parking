//
//  BookingFlowView.swift
//  Smart parking
//
//  To'liq booking flow boshqaruvchi view
//

import SwiftUI

enum BookingStep: Int, CaseIterable {
    case duration = 0
    case vehicle
    case payment
    case review
    case success
}

struct BookingFlowView: View {
    let parking: Parking

    @Environment(\.dismiss) private var dismiss
    @Environment(AppCoordinator.self) private var coordinator
    @EnvironmentObject private var availabilityStore: ParkingAvailabilityStore
    private let loc = LocalizationManager.shared

    // Flow State
    @State private var currentStep: BookingStep = .duration
    @State private var selectedMinutes: Int = 60
    @State private var selectedVehicle: Vehicle?
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var reservationId: UUID?
    @State private var reservationStartTime: Date = Date()
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    switch currentStep {
                    case .duration:
                        BookingDurationStepView(
                            parking: parking,
                            selectedMinutes: $selectedMinutes,
                            onBack: { dismiss() },
                            onContinue: { currentStep = .vehicle }
                        )

                    case .vehicle:
                        SelectVehicleView(
                            parking: parking,
                            selectedMinutes: selectedMinutes,
                            selectedVehicle: $selectedVehicle,
                            onBack: { currentStep = .duration },
                            onContinue: { currentStep = .payment }
                        )

                    case .payment:
                        PaymentMethodsView(
                            selectedMethod: $selectedPaymentMethod,
                            onBack: { currentStep = .vehicle },
                            onConfirm: { handlePaymentConfirm() }
                        )

                    case .review:
                        if let vehicle = selectedVehicle {
                            ReviewSummaryView(
                                parking: parking,
                                selectedMinutes: selectedMinutes,
                                vehicle: vehicle,
                                paymentMethod: $selectedPaymentMethod,
                                onBack: { currentStep = .payment },
                                onContinue: { processPayment() },
                                onChangePayment: { currentStep = .payment }
                            )
                        }

                    case .success:
                        if let vehicle = selectedVehicle,
                            let payment = selectedPaymentMethod,
                            let resId = reservationId
                        {
                            PaymentSuccessView(
                                parking: parking,
                                vehicle: vehicle,
                                selectedMinutes: selectedMinutes,
                                paymentMethod: payment,
                                reservationId: resId,
                                reservationStartTime: reservationStartTime,
                                onBackToHome: {
                                    coordinator.goToHome()
                                }
                            )
                        }
                    }
                }
                .id(currentStep)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity))
                )
                .animation(AppTheme.Anim.snappy, value: currentStep)

                // Loading overlay
                if isProcessing {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.4)
                            .tint(AppTheme.Palette.brand)

                        Text(loc.str(.bookingProcessing))
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Palette.textPrimary)
                            .fontWeight(.medium)
                    }
                    .padding(32)
                    .glassCard()
                    .transition(.scale(scale: 0.88).combined(with: .opacity))
                }
            }
            .navigationBarHidden(true)
        }
        .alert(loc.str(.error), isPresented: $showError) {
            Button(loc.str(.ok)) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func processPayment() {
        guard selectedVehicle != nil,
            let method = selectedPaymentMethod
        else { return }

        isProcessing = true

        Task {
            do {
                // 1) Wallet to'lov
                if method == .wallet {
                    let totalAmount = parking.price_per_hour * (Double(selectedMinutes) / 60.0)
                    let desc = "\(parking.name) – \(selectedMinutes) \(loc.str(.bookingMin))"
                    try await WalletManager.shared.deduct(amount: totalAmount, description: desc)
                }

                // 2) Reservation yaratish
                let resId: UUID
                do {
                    resId = try await ReservationManager.shared.createReservation(
                        parkingId: parking.id,
                        durationMinutes: selectedMinutes
                    )
                } catch {
                    // Reservation muvaffaqiyatsiz → pulni qaytarish
                    if method == .wallet {
                        let totalAmount = parking.price_per_hour * (Double(selectedMinutes) / 60.0)
                        try? await WalletManager.shared.topUp(
                            amount: totalAmount,
                         
                        )
                    }
                    throw error
                }

                // 3) Server dan haqiqiy start_time ni olamiz
                let startTime: Date
                if let reservation = try? await ReservationManager.shared.fetchReservation(resId) {
                    startTime = reservation.start_time
                } else {
                    startTime = Date()
                }

                await availabilityStore.refreshNow(force: true)

                await MainActor.run {
                    reservationId = resId
                    reservationStartTime = startTime
                    isProcessing = false
                    currentStep = .success
                }

            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func handlePaymentConfirm() {
        guard selectedPaymentMethod != nil else { return }
        currentStep = .review
    }
}

// MARK: - Duration Step (Simplified from existing BookingDurationView)
private struct BookingDurationStepView: View {
    let parking: Parking
    @Binding var selectedMinutes: Int
    let onBack: () -> Void
    let onContinue: () -> Void
    private let loc = LocalizationManager.shared

    private let durations = [30, 60, 90, 120, 150, 180]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppTheme.Palette.textPrimary)
                        .padding(12)
                        .background(AppTheme.Palette.surface)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4)
                }

                Spacer()

                Text(loc.str(.bookingBookSlot))
                    .font(.headline)

                Spacer()

                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(parking.name)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(loc.str(.bookingReservationInfo))
                    .font(.caption)
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }
            .padding(.horizontal)

            // Duration chips
            VStack(alignment: .leading, spacing: 10) {
                Text(loc.str(.bookingSelectDuration))
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(durations, id: \.self) { m in
                        DurationChipView(
                            title: labelFor(minutes: m),
                            isSelected: selectedMinutes == m
                        )
                        .onTapGesture {
                                AppTheme.Haptic.selection()
                                withAnimation(AppTheme.Anim.snappy) { selectedMinutes = m }
                            }
                    }
                }
                .padding(.horizontal)
            }

            // Price
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.str(.bookingPrepaidAmount))
                    .font(.caption)
                    .foregroundColor(AppTheme.Palette.textSecondary)

                let amount = (Double(selectedMinutes) / 60.0) * parking.price_per_hour
                Text("\(Int(amount)) \(loc.str(.walletCurrency))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Palette.textPrimary)
            }
            .padding(.horizontal)
            .padding(.top, 6)

            Spacer()

            // Continue button
            AppPrimaryButton(title: loc.str(.bookingContinue), action: onContinue)
                .padding(.horizontal)
                .padding(.bottom, 24)
        }
        .background(AppAnimatedBackground())
    }

    private func labelFor(minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) \(loc.str(.bookingMin))" }
        if minutes % 60 == 0 {
            let unit = minutes / 60 == 1 ? loc.str(.bookingHour) : loc.str(.bookingHours)
            return "\(minutes/60) \(unit)"
        }
        return "\(minutes/60)\(loc.str(.bookingHour)) \(minutes%60)\(loc.str(.bookingMin))"
    }
}

private struct DurationChipView: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(isSelected ? .white : AppTheme.Palette.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                isSelected
                    ? AnyShapeStyle(AppTheme.Gradient.brand)
                    : AnyShapeStyle(AppTheme.Palette.surface)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(
                color: isSelected ? AppTheme.Palette.brand.opacity(0.3) : .black.opacity(0.04),
                radius: isSelected ? 8 : 4,
                y: isSelected ? 4 : 2
            )
            .scaleEffect(isSelected ? 1.0 : 0.97)
            .animation(AppTheme.Anim.snappy, value: isSelected)
    }
}
