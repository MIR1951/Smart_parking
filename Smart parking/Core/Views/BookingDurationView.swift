//
//  BookingDurationView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//

import CoreLocation
import SwiftUI

struct BookingDurationView: View {
    private let loc = LocalizationManager.shared
    let parking: Parking
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = BookingViewModel()

    private let durations = [30, 60, 90, 120, 150, 180]  // 30 min step

    var body: some View {
        VStack(spacing: 16) {

            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppTheme.Palette.textPrimary)
                        .padding(10)
                        .background(AppTheme.Palette.surface)
                        .clipShape(Circle())
                        .shadow(radius: 2)
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
                Text(parking.name).font(.title3).fontWeight(.semibold)
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
                Text(loc.str(.bookingPrepaidAmount))
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
                    Text(vm.isProcessing ? loc.str(.bookingProcessing) : loc.str(.bookingContinue))
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
        .alert(loc.str(.info), isPresented: $vm.showAlert) {
            Button(loc.str(.ok)) { if vm.didSucceed { dismiss() } }
        } message: {
            Text(vm.alertMessage)
        }
    }

    private func labelFor(minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) \(loc.str(.bookingMin))" }
        if minutes % 60 == 0 { return "\(minutes/60) \(loc.str(.bookingHour))" }
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
