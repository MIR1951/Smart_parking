//
//  BookingDurationView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//


import SwiftUI
import CoreLocation

struct BookingDurationView: View {
    let parking: Parking
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = BookingViewModel()

    private let durations = [30, 60, 90, 120, 150, 180] // 30 min step

    var body: some View {
        VStack(spacing: 16) {

            // Header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppTheme.Palette.textPrimary)
                        .padding(10)
                        .background(AppTheme.Palette.surface)
                        .clipShape(Circle())
                        .shadow(radius: 2)
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
                Text(parking.name).font(.title3).fontWeight(.semibold)
                Text("Reservation starts now. Arriving late reduces prepaid time usable inside.")
                    .font(.caption)
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }
            .padding(.horizontal)

            // Duration chips
            VStack(alignment: .leading, spacing: 10) {
                Text("Select duration")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(durations, id: \.self) { m in
                        DurationChip(
                            title: labelFor(minutes: m),
                            isSelected: vm.selectedMinutes == m
                        )
                        .onTapGesture { vm.selectedMinutes = m }
                    }
                }
                .padding(.horizontal)
            }

            // Price
            VStack(alignment: .leading, spacing: 6) {
                Text("Prepaid amount")
                    .font(.caption)
                    .foregroundColor(AppTheme.Palette.textSecondary)

                Text(vm.prepaidText(hourlyRate: parking.price_per_hour))
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)
            .padding(.top, 6)

            Spacer()

            // Pay button
            Button {
                vm.startPaymentThenCreateReservation(parkingId: parking.id)
            } label: {
                HStack {
                    if vm.isProcessing { ProgressView().tint(.white) }
                    Text(vm.isProcessing ? "Processing..." : "Pay & Reserve")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(AppTheme.Palette.brand)
                .cornerRadius(16)
            }
            .disabled(vm.selectedMinutes == nil || vm.isProcessing)
            .padding(.horizontal)
            .padding(.bottom, 12)

        }
        .background(AppTheme.Palette.pageBackground.ignoresSafeArea())
        .alert("Reservation", isPresented: $vm.showAlert) {
            Button("OK") { if vm.didSucceed { dismiss() } }
        } message: {
            Text(vm.alertMessage)
        }
    }

    private func labelFor(minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        if minutes % 60 == 0 { return "\(minutes/60) hour" }
        return "\(minutes/60)h \(minutes%60)m"
    }
}

private struct DurationChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(isSelected ? .white : AppTheme.Palette.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(isSelected ? AppTheme.Palette.brand : AppTheme.Palette.surface)
            .cornerRadius(14)
            .shadow(radius: 2)
    }
}
