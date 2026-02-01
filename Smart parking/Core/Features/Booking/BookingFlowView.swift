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

    // Flow State
    @State private var currentStep: BookingStep = .duration
    @State private var selectedMinutes: Int = 60
    @State private var selectedVehicle: Vehicle?
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var reservationId: UUID?
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
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
                        onContinue: { currentStep = .payment }
                    )

                case .payment:
                    PaymentMethodsView(
                        selectedMethod: $selectedPaymentMethod,
                        onConfirm: { currentStep = .review }
                    )

                case .review:
                    if let vehicle = selectedVehicle {
                        ReviewSummaryView(
                            parking: parking,
                            selectedMinutes: selectedMinutes,
                            vehicle: vehicle,
                            paymentMethod: $selectedPaymentMethod,
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
                            reservationId: resId
                        )
                    }
                }

                // Loading overlay
                if isProcessing {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("Processing...")
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                    }
                    .padding(32)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(16)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func processPayment() {
        guard selectedVehicle != nil,
            selectedPaymentMethod != nil
        else { return }

        isProcessing = true

        Task {
            // 1) Simulate payment
            try? await Task.sleep(nanoseconds: 500_000_000)

            // 2) Create reservation
            do {
                let resId = try await ReservationManager.shared.createReservation(
                    parkingId: parking.id,
                    durationMinutes: selectedMinutes
                )

                await MainActor.run {
                    reservationId = resId
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
}

// MARK: - Duration Step (Simplified from existing BookingDurationView)
private struct BookingDurationStepView: View {
    let parking: Parking
    @Binding var selectedMinutes: Int
    let onBack: () -> Void
    let onContinue: () -> Void

    private let durations = [30, 60, 90, 120, 150, 180]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4)
                }

                Spacer()

                Text("Book Slot")
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

                Text("Reservation starts now. Select how long you need the parking spot.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)

            // Duration chips
            VStack(alignment: .leading, spacing: 10) {
                Text("Select duration")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(durations, id: \.self) { m in
                        DurationChipView(
                            title: labelFor(minutes: m),
                            isSelected: selectedMinutes == m
                        )
                        .onTapGesture { selectedMinutes = m }
                    }
                }
                .padding(.horizontal)
            }

            // Price
            VStack(alignment: .leading, spacing: 6) {
                Text("Prepaid amount")
                    .font(.caption)
                    .foregroundColor(.gray)

                let amount = (Double(selectedMinutes) / 60.0) * parking.price_per_hour
                Text(String(format: "$%.2f", amount))
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)
            .padding(.top, 6)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color.purple)
                    .cornerRadius(26)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private func labelFor(minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        if minutes % 60 == 0 { return "\(minutes/60) hour" }
        return "\(minutes/60)h \(minutes%60)m"
    }
}

private struct DurationChipView: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(isSelected ? .white : .black)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(isSelected ? Color.purple : Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 4)
    }
}
