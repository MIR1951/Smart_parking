//
//  BookingsView.swift
//  Smart parking
//
//  Mening bandlarim sahifasi - Ongoing, Completed, Cancelled
//

import SwiftUI

struct BookingsView: View {
    @EnvironmentObject private var availabilityStore: ParkingAvailabilityStore
    @Environment(AppCoordinator.self) private var coordinator

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
    @State private var scrollOffset: CGFloat = 0
    @State private var showCancelError = false
    @State private var cancelErrorMessage = ""
    @State private var bookingToCancel: BookingItem?

    private var headerProgress: CGFloat {
        min(max(scrollOffset / 150, 0), 1)
    }

    private var currentFontSize: CGFloat {
        CGFloat(28 - (headerProgress * 8))
    }

    var body: some View {
        ZStack {
            AppAnimatedBackground()

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Group {
                        Text(LocalizationManager.shared.str(.bookingsTitle))
                    }
                    .font(.system(size: currentFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 4)
                    .opacity(headerProgress < 0.8 ? 1.0 : max(0.0, 1.0 - (headerProgress - 0.8) * 5.0))

                    bookingTabs
                }
                .animation(AppTheme.Anim.snappy, value: headerProgress)

                ScrollView(showsIndicators: false) {
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: -geo.frame(in: .named("bookingsScroll")).minY
                        )
                    }.frame(height: 0)
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
                            ForEach(Array(vm.filtered(tab).enumerated()), id: \.element.id) { index, item in
                                BookingCard(
                                    item: item,
                                    tab: tab,
                                    onCardTap: { coordinator.showParkingDetail(item.parking.asParking) },
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
                .coordinateSpace(name: "bookingsScroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    withAnimation(AppTheme.Anim.snappy) { scrollOffset = value }
                }
                .refreshable { await vm.load() }
            }
        }
        .task {
            await vm.load()
            vm.startRealtime()
        }
        .alert(LocalizationManager.shared.str(.bookingsCancelTitle), isPresented: $showCancelAlert) {
            Button(LocalizationManager.shared.str(.bookingsYesCancel), role: .destructive) {
                if let booking = bookingToCancel { cancelBooking(booking) }
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
            case .ticket: BookingETicketView(item: item.booking)
            case .detail: BookingDetailSheet(item: item.booking)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(AppTheme.Anim.snappy, value: tab)
        .animation(AppTheme.Anim.smooth, value: vm.items.count)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Palette.brand.opacity(0.15),
                                AppTheme.Palette.brandLight.opacity(0.05),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)

                Image(systemName: "ticket")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }

            Text(LocalizationManager.shared.str(.bookingsNoBookings))
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Palette.textPrimary)

            Text(LocalizationManager.shared.str(.bookingsEmptySubtitle))
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Palette.textSecondary)
        }
        .padding(.top, 80)
    }

    // MARK: - Tabs
    private var bookingTabs: some View {
        HStack(spacing: 6) {
            ForEach(BookingTab.allCases, id: \.self) { t in
                Button {
                    withAnimation(AppTheme.Anim.snappy) { tab = t }
                } label: {
                    Text(t.displayName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(tab == t ? .white : AppTheme.Palette.textSecondary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            tab == t
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                                    startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(AppTheme.Palette.surfaceSecondary)
        .clipShape(Capsule())
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 10)
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
                await availabilityStore.refreshNow(force: true)
            } catch {
                cancelErrorMessage = "\(LocalizationManager.shared.str(.bookingsCannotCancel)): \(error.localizedDescription)"
                showCancelError = true
            }
        }
    }
}
