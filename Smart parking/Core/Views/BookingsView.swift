//
//  BookingsView.swift
//  Smart parking
//
//  Mening bandlarim sahifasi - Ongoing, Completed, Cancelled
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Supabase
import SwiftUI

// MARK: - Models
struct BookingParking: Codable, Identifiable {
    let id: UUID
    let name: String
    let address: String?
    let thumbnail_url: String?
    let price_per_hour: Double
    let rating: Double?
}

struct BookingItem: Codable, Identifiable {
    let id: UUID
    let status: String

    let start_time: Date?
    let end_time: Date?
    let actual_start_time: Date?
    let actual_end_time: Date?

    let parking: BookingParking

    // Computed properties
    var isInParking: Bool {
        status == "in_use"
    }

    var isCompleted: Bool {
        status == "completed" || status == "expired" || status == "no_show"
            || (status == "active" && (end_time ?? Date()) <= Date())
    }

    var isCancelled: Bool {
        status == "canceled" || status == "cancelled"
    }

    var canCancel: Bool {
        // Faqat active va parkingga kirmagan bo'lsa cancel qilsa bo'ladi
        status == "active" && actual_start_time == nil
    }

    var durationMinutes: Int {
        guard let start = start_time, let end = end_time else { return 0 }
        return Int(end.timeIntervalSince(start) / 60)
    }

    var totalAmount: Double {
        let hours = Double(durationMinutes) / 60.0
        return hours * parking.price_per_hour
    }

    // Vaqt o'tib ketganini tekshirish
    var isOvertime: Bool {
        guard let end = end_time else { return false }
        return Date() > end && status == "in_use"
    }

    // Qo'shimcha to'lov (har 30 daqiqa uchun)
    var overtimeAmount: Double {
        guard isOvertime, let end = end_time else { return 0 }
        let overtimeMinutes = Date().timeIntervalSince(end) / 60
        let extra30MinBlocks = ceil(overtimeMinutes / 30)
        let halfHourRate = parking.price_per_hour / 2
        return extra30MinBlocks * halfHourRate
    }
}

enum BookingTab: String, CaseIterable {
    case ongoing = "Ongoing"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var displayName: String {
        switch self {
        case .ongoing: return LocalizationManager.shared.str(.bookingsOngoing)
        case .completed: return LocalizationManager.shared.str(.bookingsCompleted)
        case .cancelled: return LocalizationManager.shared.str(.bookingsCancelled)
        }
    }
}

// MARK: - Main View
struct BookingsView: View {

    // Sheet types
    enum SheetType { case detail, ticket }
    struct SheetItem: Identifiable {
        let id = UUID()
        let booking: BookingItem
        let type: SheetType
    }

    @StateObject private var vm = BookingsVM()
    @State private var tab: BookingTab = .ongoing
    @State private var sheetItem: SheetItem?
    @State private var showCancelAlert = false
    @State private var showCancelError = false
    @State private var cancelErrorMessage = ""
    @State private var bookingToCancel: BookingItem?

    var body: some View {
        ZStack {
            AppAnimatedBackground()

            VStack(spacing: 0) {

                // Top segmented (Ongoing/Completed/Cancelled)
                bookingTabs

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if vm.isLoading && vm.items.isEmpty {
                            BookingsShimmerView()
                                .appReveal()
                                .padding(.top, 8)
                        } else if let error = vm.error {
                            AppStateView(
                                kind: .error(
                                    title: LocalizationManager.shared.str(.bookingsLoadFailed),
                                    subtitle: error,
                                    actionTitle: LocalizationManager.shared.str(.bookingsRetry),
                                    action: { Task { await vm.load() } }
                                )
                            )
                            .appReveal(0.05)
                            .padding(.top, 40)
                        } else if vm.filtered(tab).isEmpty {
                            emptyState
                                .appReveal(0.05)
                        } else {
                            ForEach(Array(vm.filtered(tab).enumerated()), id: \.element.id) {
                                index, item in
                                BookingCard(
                                    item: item,
                                    tab: tab,
                                    onLeftTap: { handleLeftButton(item) },
                                    onTicketTap: { openTicket(item) }
                                )
                                .appReveal(Double(index) * 0.03)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle(LocalizationManager.shared.str(.bookingsTitle))
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .refreshable { await vm.load() }
        .alert(
            LocalizationManager.shared.str(.bookingsCancelTitle), isPresented: $showCancelAlert
        ) {
            Button(LocalizationManager.shared.str(.bookingsYesCancel), role: .destructive) {
                if let booking = bookingToCancel {
                    cancelBooking(booking)
                }
            }
            Button(LocalizationManager.shared.str(.bookingsNo), role: .cancel) {}
        } message: {
            Text(LocalizationManager.shared.str(.bookingsCancelMessage))
        }
        .alert(LocalizationManager.shared.str(.error), isPresented: $showCancelError) {
            Button(LocalizationManager.shared.str(.ok)) {}
        } message: {
            Text(cancelErrorMessage)
        }
        .sheet(item: $sheetItem) { item in
            switch item.type {
            case .ticket:
                BookingETicketView(item: item.booking)
            case .detail:
                BookingDetailSheet(item: item.booking)
            }
        }
        .animation(AppTheme.Anim.snappy, value: tab)
        .animation(AppTheme.Anim.smooth, value: vm.items.count)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "ticket")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text(LocalizationManager.shared.str(.bookingsNoBookings))
                .font(.headline)
                .foregroundColor(AppTheme.Palette.textPrimary)

            Text(LocalizationManager.shared.str(.bookingsEmptySubtitle))
                .font(.caption)
                .foregroundColor(AppTheme.Palette.textSecondary)
        }
        .padding(.top, 80)
    }

    // MARK: - Tabs
    private var bookingTabs: some View {
        HStack(spacing: 0) {
            ForEach(BookingTab.allCases, id: \.self) { t in
                VStack(spacing: 8) {
                    Text(t.displayName)
                        .font(.headline)
                        .foregroundColor(
                            tab == t ? AppTheme.Palette.brand : AppTheme.Palette.textSecondary)

                    Capsule()
                        .fill(tab == t ? AppTheme.Palette.brand : Color.clear)
                        .frame(height: 3)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut) { tab = t }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(AppTheme.Palette.surface.opacity(0.90))
    }

    // MARK: - Actions
    private func handleLeftButton(_ item: BookingItem) {
        switch tab {
        case .ongoing:
            if item.isInParking {
                sheetItem = SheetItem(booking: item, type: .ticket)
            } else if item.canCancel {
                bookingToCancel = item
                showCancelAlert = true
            } else {
                sheetItem = SheetItem(booking: item, type: .detail)
            }
        case .completed, .cancelled:
            sheetItem = SheetItem(booking: item, type: .detail)
        }
    }

    private func openTicket(_ item: BookingItem) {
        sheetItem = SheetItem(booking: item, type: .ticket)
    }

    private func cancelBooking(_ item: BookingItem) {
        Task {
            do {
                try await ReservationManager.shared.cancelReservation(reservationId: item.id)
                await vm.load()
            } catch {
                cancelErrorMessage =
                    "\(LocalizationManager.shared.str(.bookingsCannotCancel)): \(error.localizedDescription)"
                showCancelError = true
            }
        }
    }
}

// MARK: - Booking Card
struct BookingCard: View {
    let item: BookingItem
    let tab: BookingTab
    let onLeftTap: () -> Void
    let onTicketTap: () -> Void

    private var leftButtonTitle: String {
        switch tab {
        case .ongoing:
            if item.isInParking {
                return LocalizationManager.shared.str(.bookingsTimer)
            } else if item.canCancel {
                return LocalizationManager.shared.str(.bookingsCancel)
            } else {
                return LocalizationManager.shared.str(.bookingsView)
            }
        case .completed:
            return LocalizationManager.shared.str(.bookingsView)
        case .cancelled:
            return LocalizationManager.shared.str(.bookingsView)
        }
    }

    private var rightButtonTitle: String {
        switch tab {
        case .ongoing:
            return LocalizationManager.shared.str(.bookingsETicket)
        case .completed:
            return LocalizationManager.shared.str(.bookingsViewReceipt)
        case .cancelled:
            return LocalizationManager.shared.str(.bookingsDetails)
        }
    }

    private var leftButtonStyle: (Color, Color) {
        switch tab {
        case .ongoing:
            if item.canCancel {
                return (Color.red.opacity(0.1), Color.red)
            } else {
                return (AppTheme.Palette.brand.opacity(0.1), AppTheme.Palette.brand)
            }
        case .completed:
            return (Color.green.opacity(0.1), Color.green)
        case .cancelled:
            return (Color.orange.opacity(0.1), Color.orange)
        }
    }

    var body: some View {
        VStack(spacing: 12) {

            HStack(alignment: .top, spacing: 12) {

                CachedAsyncImage(url: URL(string: item.parking.thumbnail_url ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.2))
                }
                .frame(width: 110, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 6) {

                    HStack {
                        Text(LocalizationManager.shared.str(.detailCarParking))
                            .font(.caption)
                            .foregroundColor(AppTheme.Palette.brand)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.Palette.brand.opacity(0.10))
                            .clipShape(Capsule())

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", item.parking.rating ?? 4.5))
                                .font(.caption)
                                .foregroundColor(AppTheme.Palette.textSecondary)
                        }
                    }

                    Text(item.parking.name)
                        .font(.headline)
                        .foregroundColor(AppTheme.Palette.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(AppTheme.Palette.textSecondary)
                        Text(
                            item.parking.address ?? LocalizationManager.shared.str(.bookingsUnknown)
                        )
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                        .lineLimit(1)
                    }

                    HStack(spacing: 4) {
                        Text("\(Int(item.parking.price_per_hour)) so'm")
                            .font(.headline)
                            .foregroundColor(AppTheme.Palette.brand)
                        Text(LocalizationManager.shared.str(.bookingsPerHour))
                            .font(.caption)
                            .foregroundColor(AppTheme.Palette.textSecondary)
                    }
                }
            }

            // Time Info
            timeInfoSection

            // Overtime warning (agar vaqt o'tib ketgan bo'lsa)
            if item.isOvertime {
                overtimeWarning
            }

            // Ongoing: 2 ta button, Completed/Cancelled: 1 ta button
            if tab == .ongoing {
                HStack(spacing: 12) {
                    Button(action: onLeftTap) {
                        Text(leftButtonTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(leftButtonStyle.1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(leftButtonStyle.0)
                            .clipShape(Capsule())
                    }
                    .pressStyle()

                    Button(action: onTicketTap) {
                        Text(rightButtonTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.Gradient.brand)
                            .clipShape(Capsule())
                    }
                    .pressStyle()
                }
            } else {
                Button(action: onTicketTap) {
                    Text(rightButtonTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.Gradient.brand)
                        .clipShape(Capsule())
                }
                .pressStyle()
            }
        }
        .padding(14)
        .background(AppTheme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Time Info
    private var timeInfoSection: some View {
        HStack(spacing: 16) {
            // Start Time
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizationManager.shared.str(.bookingsStart))
                    .font(.caption2)
                    .foregroundColor(AppTheme.Palette.textSecondary)

                Text(formatTime(item.start_time))
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(AppTheme.Palette.textSecondary)

            // End Time
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizationManager.shared.str(.bookingsEnd))
                    .font(.caption2)
                    .foregroundColor(AppTheme.Palette.textSecondary)

                Text(formatTime(item.end_time))
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Spacer()

            // Duration
            Text("\(item.durationMinutes) \(LocalizationManager.shared.str(.bookingMin))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Palette.brand)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.Palette.brand.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(AppTheme.Palette.pageBackground)
        .cornerRadius(12)
    }

    // MARK: - Overtime Warning
    private var overtimeWarning: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizationManager.shared.str(.bookingsOvertime))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)

                Text(
                    "\(LocalizationManager.shared.str(.bookingsExtraCharge)): $\(item.overtimeAmount, specifier: "%.2f")"
                )
                .font(.caption2)
                .foregroundColor(AppTheme.Palette.textSecondary)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }

    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "--:--" }
        return DateFormatter.shortDateTime.string(from: date)
    }
}

// MARK: - Booking E-Ticket View
struct BookingETicketView: View {
    let item: BookingItem
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Barcode
                    barcodeSection

                    // Status Badge
                    statusBadge

                    // Parking Info
                    parkingInfoSection

                    Divider()

                    // Time Info
                    timeInfoSection

                    Divider()

                    // Price Info
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
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [ticketText])
            }
        }
    }

    private var ticketText: String {
        """
         \(item.parking.name)
        \(LocalizationManager.shared.str(.bookingsStart)): \(formatDateTime(item.start_time))
        \(LocalizationManager.shared.str(.bookingsEnd)): \(formatDateTime(item.end_time))
         \(item.id.uuidString)
        """
    }

    private var statusBadge: some View {
        HStack {
            Text(localizedStatus(item.status))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.1))
                .cornerRadius(12)
        }
    }

    private var statusColor: Color {
        switch item.status {
        case "active", "in_use": return .green
        case "completed": return .blue
        case "cancelled", "canceled": return .red
        case "expired", "no_show": return .orange
        default: return .gray
        }
    }

    private var barcodeSection: some View {
        VStack(spacing: 12) {
            if let qrImage = generateQRCode(from: ticketText) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
            } else {
                // Fallback if QR code generation fails
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

    private var timeInfoSection: some View {
        VStack(spacing: 12) {
            infoRow(
                title: LocalizationManager.shared.str(.bookingsStart),
                value: formatDateTime(item.start_time))
            infoRow(
                title: LocalizationManager.shared.str(.bookingsEnd),
                value: formatDateTime(item.end_time))
            infoRow(
                title: LocalizationManager.shared.str(.bookingsDuration),
                value: "\(item.durationMinutes) \(LocalizationManager.shared.str(.bookingMin))")

            if item.actual_start_time != nil {
                infoRow(
                    title: LocalizationManager.shared.str(.bookingsActualEntry),
                    value: formatDateTime(item.actual_start_time))
            }
            if item.actual_end_time != nil {
                infoRow(
                    title: LocalizationManager.shared.str(.bookingsActualExit),
                    value: formatDateTime(item.actual_end_time))
            }
        }
    }

    private var priceInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(LocalizationManager.shared.str(.bookingsPricePerHour))
                Spacer()
                Text("\(Int(item.parking.price_per_hour)) so'm")
                    .fontWeight(.medium)
            }

            HStack {
                Text(LocalizationManager.shared.str(.bookingsBaseAmount))
                Spacer()
                Text("\(Int(item.totalAmount)) so'm")
                    .fontWeight(.medium)
            }

            if item.overtimeAmount > 0 {
                HStack {
                    Text(LocalizationManager.shared.str(.bookingsOvertimeCharge))
                    Spacer()
                    Text("+\(Int(item.overtimeAmount)) so'm")
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }

            Divider()

            HStack {
                Text(LocalizationManager.shared.str(.reviewTotal))
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(item.totalAmount + item.overtimeAmount)) so'm")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Palette.brand)
            }
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(AppTheme.Palette.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
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

// MARK: - Booking Detail Sheet (View button — no QR)
struct BookingDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: BookingItem

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Status badge
                    statusBadge

                    // Parking info
                    parkingInfoSection

                    Divider().padding(.horizontal)

                    // Time info
                    timeInfoSection

                    Divider().padding(.horizontal)

                    // Price info
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

    private var statusBadge: some View {
        HStack {
            Text(localizedStatus(item.status))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(statusColor.opacity(0.12))
                .cornerRadius(20)
        }
    }

    private var statusColor: Color {
        switch item.status {
        case "active", "in_use": return .green
        case "completed": return .blue
        case "cancelled", "canceled": return .red
        case "expired", "no_show": return .orange
        default: return .gray
        }
    }

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

    private var timeInfoSection: some View {
        VStack(spacing: 12) {
            infoRow(
                title: LocalizationManager.shared.str(.bookingsStart),
                value: formatDateTime(item.start_time))
            infoRow(
                title: LocalizationManager.shared.str(.bookingsEnd),
                value: formatDateTime(item.end_time))
            infoRow(
                title: LocalizationManager.shared.str(.bookingsDuration),
                value: "\(item.durationMinutes) \(LocalizationManager.shared.str(.bookingMin))")

            if item.actual_start_time != nil {
                infoRow(
                    title: LocalizationManager.shared.str(.bookingsActualEntry),
                    value: formatDateTime(item.actual_start_time))
            }
            if item.actual_end_time != nil {
                infoRow(
                    title: LocalizationManager.shared.str(.bookingsActualExit),
                    value: formatDateTime(item.actual_end_time))
            }
        }
    }

    private var priceInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(LocalizationManager.shared.str(.bookingsPricePerHour))
                Spacer()
                Text("\(Int(item.parking.price_per_hour)) so'm")
                    .fontWeight(.medium)
            }

            HStack {
                Text(LocalizationManager.shared.str(.bookingsBaseAmount))
                Spacer()
                Text("\(Int(item.totalAmount)) so'm")
                    .fontWeight(.medium)
            }

            if item.overtimeAmount > 0 {
                HStack {
                    Text(LocalizationManager.shared.str(.bookingsOvertimeCharge))
                    Spacer()
                    Text("+\(Int(item.overtimeAmount)) so'm")
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }

            Divider()

            HStack {
                Text(LocalizationManager.shared.str(.reviewTotal))
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(item.totalAmount + item.overtimeAmount)) so'm")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Palette.brand)
            }
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(AppTheme.Palette.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
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
