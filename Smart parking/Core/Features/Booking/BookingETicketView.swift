import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct BookingETicketView: View {
    let item: BookingItem
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    barcodeSection
                    statusBadge
                    parkingInfoSection
                    Divider()
                    timeInfoSection
                    Divider()
                    priceInfoSection
                }
                .padding()
            }
            .background(AppAnimatedBackground())
            .navigationTitle(LocalizationManager.shared.str(.bookingsETicket))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationManager.shared.str(.bookingsClose)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { showShareSheet = true } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [ticketText])
            }
        }
    }

    // MARK: - Ticket Text
    private var ticketText: String {
        """
         \(item.parking.name)
        \(LocalizationManager.shared.str(.bookingsStart)): \(formatDateTime(item.start_time))
        \(LocalizationManager.shared.str(.bookingsEnd)): \(formatDateTime(item.end_time))
         \(item.id.uuidString)
        """
    }

    // MARK: - Status Badge
    private var statusBadge: some View {
        HStack {
            Text(localizedStatus(item.status))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    // MARK: - Barcode Section
    private var barcodeSection: some View {
        VStack(spacing: 12) {
            if let qrImage = generateQRCode(from: ticketText) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
            } else {
                Image(systemName: "qrcode")
                    .font(.system(size: 100))
                    .foregroundColor(AppTheme.Palette.textTertiary)
            }

            Text(item.id.uuidString.prefix(12).uppercased())
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Palette.textSecondary)
                .tracking(2)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.Palette.surface)
        .cornerRadius(AppTheme.Radius.large)
    }

    private func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator")
        else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }
        let scale = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: scale)
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
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
