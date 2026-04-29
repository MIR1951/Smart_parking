import SwiftUI

struct BookingDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: BookingItem

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    statusBadge
                    parkingInfoSection
                    Divider().padding(.horizontal)
                    timeInfoSection
                    Divider().padding(.horizontal)
                    priceInfoSection
                }
                .padding()
            }
            .background(AppAnimatedBackground())
            .navigationTitle(LocalizationManager.shared.str(.bookingsDetails))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationManager.shared.str(.bookingsClose)) { dismiss() }
                }
            }
        }
    }

    // MARK: - Status Badge
    private var statusBadge: some View {
        HStack {
            Text(localizedStatus(item.status))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(statusColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var statusColor: Color {
        switch item.status {
        case "active", "in_use": return AppTheme.Palette.success
        case "completed": return AppTheme.Palette.bookingAccent
        case "cancelled", "canceled": return AppTheme.Palette.danger
        case "expired", "no_show": return AppTheme.Palette.warning
        default: return AppTheme.Palette.textSecondary
        }
    }

    // MARK: - Parking Info
    private var parkingInfoSection: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: URL(string: item.parking.thumbnail_url ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(AppTheme.Palette.surfaceSecondary)
            }
            .frame(width: 80, height: 60)
            .cornerRadius(AppTheme.Radius.small)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.parking.name)
                    .font(AppTheme.Typography.headline)
                Text(item.parking.address ?? "")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Time Info
    private var timeInfoSection: some View {
        VStack(spacing: 12) {
            infoRow(title: LocalizationManager.shared.str(.bookingsStart), value: formatDateTime(item.start_time))
            infoRow(title: LocalizationManager.shared.str(.bookingsEnd), value: formatDateTime(item.end_time))
            infoRow(title: LocalizationManager.shared.str(.bookingsDuration),
                    value: "\(item.durationMinutes) \(LocalizationManager.shared.str(.bookingMin))")

            if item.actual_start_time != nil {
                infoRow(title: LocalizationManager.shared.str(.bookingsActualEntry), value: formatDateTime(item.actual_start_time))
            }
            if item.actual_end_time != nil {
                infoRow(title: LocalizationManager.shared.str(.bookingsActualExit), value: formatDateTime(item.actual_end_time))
            }
        }
    }

    // MARK: - Price Info
    private var priceInfoSection: some View {
        VStack(spacing: 12) {
            infoRow(
                title: LocalizationManager.shared.str(.bookingsPricePerHour),
                value: "\(Int(item.parking.price_per_hour)) \(LocalizationManager.shared.str(.walletCurrency))"
            )
            infoRow(
                title: LocalizationManager.shared.str(.bookingsBaseAmount),
                value: "\(Int(item.totalAmount)) \(LocalizationManager.shared.str(.walletCurrency))"
            )

            if item.overtimeAmount > 0 {
                HStack {
                    Text(LocalizationManager.shared.str(.bookingsOvertimeCharge))
                    Spacer()
                    Text("+\(Int(item.overtimeAmount)) \(LocalizationManager.shared.str(.walletCurrency))")
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Palette.warning)
                }
            }

            Divider()

            HStack {
                Text(LocalizationManager.shared.str(.reviewTotal))
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(item.totalAmount + item.overtimeAmount)) \(LocalizationManager.shared.str(.walletCurrency))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Palette.brand)
            }
        }
    }

    // MARK: - Helpers
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundColor(AppTheme.Palette.textSecondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }

    private func formatDateTime(_ date: Date?) -> String {
        guard let date = date else { return "--" }
        return DateFormatter.fullDateTime.string(from: date)
    }

    private func localizedStatus(_ status: String) -> String {
        switch status {
        case "active": return LocalizationManager.shared.str(.statusActive)
        case "in_use": return LocalizationManager.shared.str(.statusInUse)
        case "completed": return LocalizationManager.shared.str(.statusCompleted)
        case "cancelled", "canceled": return LocalizationManager.shared.str(.statusCancelled)
        case "expired": return LocalizationManager.shared.str(.statusExpired)
        case "no_show": return LocalizationManager.shared.str(.statusNoShow)
        default: return status.capitalized
        }
    }
}
