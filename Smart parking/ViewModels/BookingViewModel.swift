//
//  BookingViewModel.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//


import Foundation
internal import Combine

@MainActor
final class BookingViewModel: ObservableObject {
    @Published var selectedMinutes: Int? = 60
    @Published var isProcessing = false

    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var didSucceed = false

    func prepaidText(hourlyRate: Double) -> String {
        let minutes = selectedMinutes ?? 0
        let amount = (Double(minutes) / 60.0) * hourlyRate
        return String(format: "$%.2f", amount)
    }

    func startPaymentThenCreateReservation(parkingId: UUID) {
        guard let minutes = selectedMinutes else { return }

        isProcessing = true
        didSucceed = false

        // 1) PAYMENT (sizning payment SDK bu yerda bo‘ladi)
        Task {
            let paymentResult = await simulatePaymentSuccess()
            guard paymentResult else {
                isProcessing = false
                alertMessage = "Payment failed. Try again."
                showAlert = true
                return
            }

            // 2) Payment success -> Supabase RPC
            do {
                let reservationId = try await ReservationManager.shared.createReservation(
                    parkingId: parkingId,
                    durationMinutes: minutes
                )

                isProcessing = false
                didSucceed = true
                alertMessage = "Reserved ✅\nReservation ID: \(reservationId.uuidString.prefix(8))..."
                showAlert = true

            } catch {
                // ⚠️ Bu yerda NO_SPOTS_AVAILABLE chiqishi mumkin (paymentdan keyin joy tugab qolsa)
                isProcessing = false
                alertMessage = "Reservation failed: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    // Demo only: payment success
    private func simulatePaymentSuccess() async -> (Bool) {
        try? await Task.sleep(nanoseconds: 900_000_000)
        return (true)
    }
}
