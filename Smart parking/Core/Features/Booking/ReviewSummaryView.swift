//
//  ReviewSummaryView.swift
//  Smart parking
//
//  Band qilish ma'lumotlari xulosa sahifasi
//

import SwiftUI

struct ReviewSummaryView: View {
    let parking: Parking
    let selectedMinutes: Int
    let vehicle: Vehicle
    @Binding var paymentMethod: PaymentMethod?
    let onBack: () -> Void
    let onContinue: () -> Void
    let onChangePayment: () -> Void

    // Calculated values
    private var startTime: Date { Date() }
    private var endTime: Date { startTime.addingTimeInterval(Double(selectedMinutes) * 60) }
    private var hours: Double { Double(selectedMinutes) / 60.0 }
    private var amount: Double { hours * parking.price_per_hour }
    private var fees: Double { 2.0 }  // Fixed fee
    private var total: Double { amount + fees }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Parking Info Card
                    parkingInfoCard

                    // Time & Vehicle Info
                    timeVehicleInfo

                    Divider()

                    // Price Info
                    priceInfo

                    Divider()

                    // Payment Method
                    paymentMethodRow
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }

            Spacer()

            // Continue Button
            continueButton
        }
        .background(AppTheme.Palette.pageBackground.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppTheme.Palette.textPrimary)
                    .padding(12)
                    .background(AppTheme.Palette.surface)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4)
            }

            Spacer()

            Text("Review Summary")
                .font(.headline)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Parking Info Card
    private var parkingInfoCard: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.2))
            }
            .frame(width: 100, height: 80)
            .cornerRadius(12)
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text("Car Parking")
                    .font(.caption)
                    .foregroundColor(AppTheme.Palette.brand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.Palette.brandSoft)
                    .cornerRadius(8)

                Text(parking.name)
                    .font(.headline)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                    Text(parking.address ?? "")
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", parking.rating ?? 4.9))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(AppTheme.Palette.surface)
        .cornerRadius(16)
    }

    // MARK: - Time & Vehicle Info
    private var timeVehicleInfo: some View {
        VStack(spacing: 12) {
            infoRow(title: "Arriving Time", value: formatDateTime(startTime))
            infoRow(title: "Exit Time", value: formatDateTime(endTime))
            infoRow(title: "Vehicle", value: "\(vehicle.name) (\(vehicle.type.rawValue))")
            infoRow(title: "Duration", value: formatDuration(selectedMinutes))
        }
    }

    // MARK: - Price Info
    private var priceInfo: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Amount")
                Spacer()
                Text(String(format: "$%.2f", parking.price_per_hour))
                    .fontWeight(.medium)
                Text("/hr")
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }

            HStack {
                Text("Total Hours")
                Spacer()
                Text(formatDuration(selectedMinutes))
                    .fontWeight(.medium)
            }

            HStack {
                Text("Fees")
                Spacer()
                Text(String(format: "$%.2f", fees))
                    .fontWeight(.medium)
            }

            Divider()

            HStack {
                Text("Total")
                    .fontWeight(.semibold)
                Spacer()
                Text(String(format: "$%.2f", total))
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
    }

    // MARK: - Payment Method Row
    private var paymentMethodRow: some View {
        HStack {
            if let method = paymentMethod {
                Image(systemName: method.icon)
                    .foregroundColor(AppTheme.Palette.brand)
                Text(method.displayName)
            } else {
                Text("Select Payment")
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }

            Spacer()

            Button("Change") {
                onChangePayment()
            }
            .foregroundColor(AppTheme.Palette.brand)
        }
        .padding()
        .background(AppTheme.Palette.surface)
        .cornerRadius(12)
    }

    // MARK: - Continue Button
    private var continueButton: some View {
        AppPrimaryButton(
            title: "Continue",
            isEnabled: paymentMethod != nil
        ) {
            onContinue()
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }

    // MARK: - Helpers
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(AppTheme.Palette.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd | hh:mm a"
        return formatter.string(from: date)
    }

    private func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return "\(m) min" }
        if m == 0 { return "\(h) hour\(h > 1 ? "s" : "")" }
        return "\(h)h \(m)m"
    }
}
