//
//  AdminReservationsView.swift
//  Smart parking
//
//  Owner parkinglaridagi barcha rezervatsiyalar
//

import SwiftUI

struct AdminReservationsView: View {
    @Bindable var store: AdminStore
    @Environment(LocalizationManager.self) private var loc

    @State private var selectedParking: Parking?
    @State private var selectedStatus: String = "all"
    @State private var reservationToCancel: Reservation?
    @State private var showCancelConfirm = false
    @State private var scrollOffset: CGFloat = 0

    private let statuses = ["all", "active", "in_use", "completed", "cancelled", "expired"]
    private var headerProgress: CGFloat { min(max(scrollOffset / 100, 0), 1) }
    private var titleFontSize: CGFloat { 22 - headerProgress * 4 }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Text(loc.str(.adminReservations))
                    .font(.system(size: titleFontSize, weight: .bold, design: .rounded))
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .animation(AppTheme.Anim.snappy, value: headerProgress)

                // Parking picker
                if !store.ownedParkings.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            parkingFilterChip(nil, title: loc.str(.adminAllParkings))
                            ForEach(store.ownedParkings) { parking in
                                parkingFilterChip(parking, title: parking.name)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Status filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(statuses, id: \.self) { status in
                            statusChip(status)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 12)

            // Content
            ScrollView(showsIndicators: false) {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: -geo.frame(in: .named("reservScroll")).minY
                    )
                }.frame(height: 0)

                LazyVStack(spacing: 12) {
                    if filteredReservations.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 44))
                                .foregroundColor(AppTheme.Palette.textTertiary)
                            Text(loc.str(.adminNoReservations))
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Palette.textSecondary)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(Array(filteredReservations.enumerated()), id: \.element.id) { index, reservation in
                            AdminReservationCard(
                                reservation: reservation,
                                parking: parkingFor(reservation.parking_id),
                                onCancel: {
                                    reservationToCancel = reservation
                                    showCancelConfirm = true
                                }
                            )
                            .appReveal(Double(index) * 0.03)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .coordinateSpace(name: "reservScroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                withAnimation(AppTheme.Anim.snappy) { scrollOffset = value }
            }
        }
        .background(AppAnimatedBackground())
        .navigationBarHidden(true)
        .task {
            await loadReservations()
        }
        .refreshable {
            await loadReservations()
        }
        .alert(loc.str(.adminCancelReservation), isPresented: $showCancelConfirm) {
            Button(loc.str(.bookingsNo), role: .cancel) {}
            Button(loc.str(.bookingsCancel), role: .destructive) {
                if let reservation = reservationToCancel {
                    Task {
                        try? await store.cancelReservation(
                            id: reservation.id,
                            parkingId: reservation.parking_id
                        )
                    }
                }
            }
        } message: {
            Text(loc.str(.adminCancelReservationConfirm))
        }
    }

    // MARK: - Filters

    private var filteredReservations: [Reservation] {
        let allReservations: [Reservation]

        if let parking = selectedParking {
            allReservations = store.reservations[parking.id] ?? []
        } else {
            allReservations = store.reservations.values.flatMap { $0 }
        }

        if selectedStatus == "all" {
            return allReservations.sorted { $0.start_time > $1.start_time }
        }
        return allReservations
            .filter { $0.status == selectedStatus }
            .sorted { $0.start_time > $1.start_time }
    }

    private func parkingFor(_ parkingId: UUID) -> Parking? {
        store.ownedParkings.first { $0.id == parkingId }
    }

    private func loadReservations() async {
        for parking in store.ownedParkings {
            await store.loadReservations(for: parking.id)
        }
    }

    // MARK: - Chips

    private func parkingFilterChip(_ parking: Parking?, title: String) -> some View {
        let isSelected = selectedParking?.id == parking?.id
        return Button {
            withAnimation(AppTheme.Anim.snappy) {
                selectedParking = parking
            }
        } label: {
            Text(title)
                .font(AppTheme.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppTheme.Palette.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                        : AnyShapeStyle(AppTheme.Palette.surfaceGlass)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.clear : AppTheme.Palette.border,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func statusChip(_ status: String) -> some View {
        let isSelected = selectedStatus == status
        let displayName: String = switch status {
        case "all": loc.str(.adminAllStatuses)
        case "active": loc.str(.statusActive)
        case "in_use": loc.str(.statusInUse)
        case "completed": loc.str(.statusCompleted)
        case "cancelled": loc.str(.statusCancelled)
        case "expired": loc.str(.statusExpired)
        default: status
        }

        return Button {
            AppTheme.Haptic.selection()
            withAnimation(AppTheme.Anim.snappy) {
                selectedStatus = status
            }
        } label: {
            Text(displayName)
                .font(AppTheme.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppTheme.Palette.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? statusColor(status) : AppTheme.Palette.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "active": return .blue
        case "in_use": return .orange
        case "completed": return AppTheme.Palette.success
        case "cancelled": return AppTheme.Palette.danger
        case "expired": return .gray
        default: return AppTheme.Palette.brand
        }
    }
}

// MARK: - Admin Reservation Card

private struct AdminReservationCard: View {
    let reservation: Reservation
    let parking: Parking?
    let onCancel: () -> Void

    private var statusColor: Color {
        switch reservation.status {
        case "active": return .blue
        case "in_use": return .orange
        case "completed": return AppTheme.Palette.success
        case "cancelled": return AppTheme.Palette.danger
        case "expired": return .gray
        default: return .secondary
        }
    }

    private var statusLabel: String {
        switch reservation.status {
        case "active": return LocalizationManager.shared.str(.statusActive)
        case "in_use": return LocalizationManager.shared.str(.statusInUse)
        case "completed": return LocalizationManager.shared.str(.statusCompleted)
        case "cancelled": return LocalizationManager.shared.str(.statusCancelled)
        case "expired": return LocalizationManager.shared.str(.statusExpired)
        default: return reservation.status
        }
    }

    private var estimatedRevenue: Int? {
        guard let parking else { return nil }
        let hours = reservation.end_time.timeIntervalSince(reservation.start_time) / 3600
        return Int(hours * parking.price_per_hour)
    }

    private var durationText: String {
        let interval = reservation.end_time.timeIntervalSince(reservation.start_time)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 && minutes > 0 { return "\(hours) soat \(minutes) min" }
        if hours > 0 { return "\(hours) soat" }
        return "\(minutes) min"
    }

    private var isCancellable: Bool {
        reservation.status == "active" || reservation.status == "in_use"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: parking name + status
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(parking?.name ?? LocalizationManager.shared.str(.unknown))
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.semibold)

                    Text(durationText)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Palette.textTertiary)
                }

                Spacer()

                Text(statusLabel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xSmall, style: .continuous))
            }

            // Times
            HStack(spacing: 0) {
                timeBlock(icon: "clock", label: LocalizationManager.shared.str(.bookingsStart), date: reservation.start_time)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.Palette.textTertiary)
                Spacer()
                timeBlock(icon: "clock.badge.checkmark", label: LocalizationManager.shared.str(.bookingsEnd), date: reservation.end_time)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(AppTheme.Palette.surfaceSecondary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))

            // Revenue + ID
            HStack {
                if let revenue = estimatedRevenue {
                    HStack(spacing: 4) {
                        Image(systemName: "banknote")
                            .font(.caption2)
                            .foregroundColor(AppTheme.Palette.success)
                        Text("\(revenue) \(LocalizationManager.shared.str(.walletCurrency))")
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.Palette.success)
                    }
                }

                Spacer()

                Text("ID: \(reservation.id.uuidString.prefix(8))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(AppTheme.Palette.textTertiary)
            }

            // Cancel button
            if isCancellable {
                Button(action: onCancel) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                        Text(LocalizationManager.shared.str(.adminCancelReservation))
                    }
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Palette.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppTheme.Palette.dangerSoft)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xSmall, style: .continuous))
                }
                .pressStyle()
            }
        }
        .padding()
        .glassCard()
    }

    private func timeBlock(icon: String, label: String, date: Date) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(AppTheme.Palette.textTertiary)
            Text(formatDate(date))
                .font(AppTheme.Typography.caption)
                .fontWeight(.medium)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm"
        return formatter.string(from: date)
    }
}
