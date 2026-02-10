//
//  BookingsView.swift
//  Smart parking
//
//  Mening bandlarim sahifasi - Ongoing, Completed, Cancelled
//

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
}

// MARK: - Main View
struct BookingsView: View {

    @StateObject private var vm = BookingsVM()
    @State private var tab: BookingTab = .ongoing
    @State private var selectedBooking: BookingItem?
    @State private var showETicket = false
    @State private var showCancelAlert = false
    @State private var showCancelError = false
    @State private var cancelErrorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Top segmented (Ongoing/Completed/Cancelled)
                bookingTabs

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if vm.isLoading && vm.items.isEmpty {
                            BookingsShimmerView()
                                .padding(.top, 8)
                        } else if let error = vm.error {
                            AppStateView(
                                kind: .error(
                                    title: "Bandlar yuklanmadi",
                                    subtitle: error,
                                    actionTitle: "Retry",
                                    action: { Task { await vm.load() } }
                                )
                            )
                            .padding(.top, 40)
                        } else if vm.filtered(tab).isEmpty {
                            emptyState
                        } else {
                            ForEach(vm.filtered(tab)) { item in
                                BookingCard(
                                    item: item,
                                    tab: tab,
                                    onLeftTap: { handleLeftButton(item) },
                                    onTicketTap: { openTicket(item) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(AppTheme.Palette.pageBackground.ignoresSafeArea())
            .navigationTitle("My Bookings")
            .navigationBarTitleDisplayMode(.inline)
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .alert("Cancel Booking", isPresented: $showCancelAlert) {
                Button("Yes, Cancel", role: .destructive) {
                    if let booking = selectedBooking {
                        cancelBooking(booking)
                    }
                }
                Button("No", role: .cancel) {}
            } message: {
                Text("Are you sure you want to cancel this booking?")
            }
            .alert("Error", isPresented: $showCancelError) {
                Button("OK") {}
            } message: {
                Text(cancelErrorMessage)
            }
            .sheet(isPresented: $showETicket) {
                if let booking = selectedBooking {
                    BookingETicketView(item: booking)
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "ticket")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No \(tab.rawValue) Bookings")
                .font(.headline)
                .foregroundColor(AppTheme.Palette.textPrimary)

            Text("Your \(tab.rawValue.lowercased()) bookings will appear here")
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
                    Text(t.rawValue)
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
        .background(AppTheme.Palette.surface)
    }

    // MARK: - Actions
    private func handleLeftButton(_ item: BookingItem) {
        selectedBooking = item

        switch tab {
        case .ongoing:
            if item.isInParking {
                // Timer - parkingda, cancel qilolmaydi
                showETicket = true
            } else if item.canCancel {
                // Cancel qilish mumkin
                showCancelAlert = true
            } else {
                // Boshqa holat - faqat ko'rish
                showETicket = true
            }

        case .completed, .cancelled:
            // Faqat ko'rish
            showETicket = true
        }
    }

    private func openTicket(_ item: BookingItem) {
        selectedBooking = item
        showETicket = true
    }

    private func cancelBooking(_ item: BookingItem) {
        Task {
            do {
                try await ReservationManager.shared.cancelReservation(reservationId: item.id)
                await vm.load()
            } catch {
                cancelErrorMessage = "Cannot cancel: \(error.localizedDescription)"
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
                return "Timer"
            } else if item.canCancel {
                return "Cancel"
            } else {
                return "View"
            }
        case .completed:
            return "View"
        case .cancelled:
            return "View"
        }
    }

    private var rightButtonTitle: String {
        switch tab {
        case .ongoing:
            return "E-Ticket"
        case .completed:
            return "View Receipt"
        case .cancelled:
            return "Details"
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
                        Text("Car Parking")
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
                        Text(item.parking.address ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(AppTheme.Palette.textSecondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 4) {
                        Text("$\(item.parking.price_per_hour, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(AppTheme.Palette.brand)
                        Text("/hr")
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

                Button(action: onTicketTap) {
                    Text(rightButtonTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.Palette.brand)
                        .clipShape(Capsule())
                }
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
                Text("Start")
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
                Text("End")
                    .font(.caption2)
                    .foregroundColor(AppTheme.Palette.textSecondary)

                Text(formatTime(item.end_time))
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Spacer()

            // Duration
            Text("\(item.durationMinutes) min")
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
                Text("Overtime!")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)

                Text("Extra charge: $\(item.overtimeAmount, specifier: "%.2f")")
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
            .background(AppTheme.Palette.pageBackground)
            .navigationTitle("E-Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
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
        Parking: \(item.parking.name)
        Status: \(item.status)
        Start: \(formatDateTime(item.start_time))
        End: \(formatDateTime(item.end_time))
        Reservation ID: \(item.id.uuidString)
        """
    }

    private var statusBadge: some View {
        HStack {
            Text(item.status.capitalized)
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
        VStack {
            HStack(spacing: 2) {
                ForEach(0..<40, id: \.self) { index in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: barcodeWidth(for: index), height: 60)
                }
            }

            Text(item.id.uuidString.prefix(12).uppercased())
                .font(.caption)
                .foregroundColor(AppTheme.Palette.textSecondary)
        }
        .padding()
        .background(AppTheme.Palette.surface)
        .cornerRadius(16)
    }

    private func barcodeWidth(for index: Int) -> CGFloat {
        let hash = item.id.hashValue
        let seed = abs(hash >> (index % 8)) % 4
        return CGFloat(seed + 1)
    }

    private var parkingInfoSection: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: URL(string: item.parking.thumbnail_url ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.2))
            }
            .frame(width: 80, height: 60)
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.parking.name)
                    .font(.headline)

                Text(item.parking.address ?? "")
                    .font(.caption)
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }

            Spacer()
        }
    }

    private var timeInfoSection: some View {
        VStack(spacing: 12) {
            infoRow(title: "Start Time", value: formatDateTime(item.start_time))
            infoRow(title: "End Time", value: formatDateTime(item.end_time))
            infoRow(title: "Duration", value: "\(item.durationMinutes) minutes")

            if item.actual_start_time != nil {
                infoRow(title: "Actual Entry", value: formatDateTime(item.actual_start_time))
            }
            if item.actual_end_time != nil {
                infoRow(title: "Actual Exit", value: formatDateTime(item.actual_end_time))
            }
        }
    }

    private var priceInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Price per Hour")
                Spacer()
                Text(String(format: "$%.2f", item.parking.price_per_hour))
                    .fontWeight(.medium)
            }

            HStack {
                Text("Base Amount")
                Spacer()
                Text(String(format: "$%.2f", item.totalAmount))
                    .fontWeight(.medium)
            }

            if item.overtimeAmount > 0 {
                HStack {
                    Text("Overtime Charge")
                    Spacer()
                    Text(String(format: "+$%.2f", item.overtimeAmount))
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }

            Divider()

            HStack {
                Text("Total")
                    .fontWeight(.semibold)
                Spacer()
                Text(String(format: "$%.2f", item.totalAmount + item.overtimeAmount))
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
}
