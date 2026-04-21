//
//  AdminDashboardView.swift
//  Smart parking
//
//  Admin dashboard — statistika va umumiy ko'rinish
//

import SwiftUI

struct AdminDashboardView: View {
    @Bindable var store: AdminStore
    @Environment(UserManager.self) private var userManager
    @Environment(LocalizationManager.self) private var loc

    @State private var showAddParking = false
    @State private var scrollOffset: CGFloat = 0

    private var headerProgress: CGFloat { min(max(scrollOffset / 150, 0), 1) }
    private var greetingFontSize: CGFloat { 22 - headerProgress * 4 }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = userManager.currentUser?.username ?? "Admin"
        let greeting: String
        switch hour {
        case 5..<12: greeting = loc.str(.adminGreetingMorning)
        case 12..<17: greeting = loc.str(.adminGreetingDay)
        case 17..<22: greeting = loc.str(.adminGreetingEvening)
        default: greeting = loc.str(.adminGreetingNight)
        }
        return "\(greeting), \(name)"
    }

    var body: some View {
        ZStack {
            AppAnimatedBackground()

            VStack(spacing: 0) {
                headerSection
                    .animation(AppTheme.Anim.snappy, value: headerProgress)

                ScrollView(showsIndicators: false) {
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: -geo.frame(in: .named("dashScroll")).minY
                        )
                    }.frame(height: 0)

                    VStack(spacing: 20) {
                        if store.isLoading && store.dashboardStats == nil {
                            AppStateView(kind: .loading(title: loc.str(.launchLoading)))
                                .padding(.top, 60)
                        } else if let stats = store.dashboardStats {
                            statsGrid(stats)
                                .appReveal(0.05)

                            completedCard(stats)
                                .appReveal(0.1)

                            quickActionsSection
                                .appReveal(0.15)

                            parkingsOverview
                                .appReveal(0.2)
                        } else if let error = store.error {
                            AppStateView(
                                kind: .error(
                                    title: loc.str(.adminError),
                                    subtitle: error,
                                    actionTitle: loc.str(.retry),
                                    action: { Task { await store.loadAll() } }
                                )
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .coordinateSpace(name: "dashScroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    withAnimation(AppTheme.Anim.snappy) { scrollOffset = value }
                }
                .refreshable { await store.loadAll() }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddParking) {
            AdminParkingEditorView(store: store, parking: nil)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: greetingFontSize, weight: .bold, design: .rounded))

                if headerProgress < 0.8 {
                    Text(loc.str(.adminDashboard))
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            Spacer()

            Image(systemName: "shield.checkered")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(12)
                .background(AppTheme.Palette.brandSoft)
                .clipShape(Circle())
        }
        .padding(.top, 8)
        .padding(.horizontal)
        .padding(.bottom, headerProgress < 0.5 ? 8 : 4)
    }

    // MARK: - Stats Grid

    private func statsGrid(_ stats: AdminParkingService.DashboardStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatCard(
                icon: "car.fill",
                title: loc.str(.adminTotalParkings),
                value: "\(stats.total_parkings)",
                color: AppTheme.Palette.brand
            )

            StatCard(
                icon: "square.grid.3x3.fill",
                title: loc.str(.detailTotalSpots),
                value: "\(stats.total_spots)",
                color: .teal
            )

            StatCard(
                icon: "clock.fill",
                title: loc.str(.adminActiveNow),
                value: "\(stats.active_reservations)",
                color: .orange
            )

            StatCard(
                icon: "calendar",
                title: loc.str(.bookingsTitle),
                value: "\(stats.today_reservations)",
                color: .purple
            )
        }
    }

    // MARK: - Completed Card

    private func completedCard(_ stats: AdminParkingService.DashboardStats) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundColor(AppTheme.Palette.success)
                .padding(10)
                .background(AppTheme.Palette.successSoft)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(loc.str(.bookingsCompleted))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                Text("\(stats.total_completed)")
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(loc.str(.reviewTotal))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Palette.textTertiary)
                let total = stats.active_reservations + stats.today_reservations + stats.total_completed
                Text("\(total)")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }
        }
        .padding()
        .glassCard()
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.str(.adminQuickActions))
                .font(AppTheme.Typography.headline)

            HStack(spacing: 12) {
                quickActionButton(
                    icon: "plus.circle.fill",
                    label: loc.str(.adminAddParking),
                    color: AppTheme.Palette.brand
                ) {
                    showAddParking = true
                }

                quickActionButton(
                    icon: "arrow.clockwise.circle.fill",
                    label: loc.str(.homeRetry),
                    color: AppTheme.Palette.accent
                ) {
                    Task { await store.loadAll() }
                }
            }
        }
    }

    private func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
                Text(label)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Palette.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassCard(cornerRadius: AppTheme.Radius.medium)
        }
        .pressStyle()
    }

    // MARK: - Parkings Overview

    private var parkingsOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(loc.str(.adminMyParkings))
                    .font(AppTheme.Typography.headline)
                Spacer()
                Text("\(store.ownedParkings.count) \(loc.str(.adminStatsParkings))")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }

            if store.ownedParkings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.Palette.textTertiary)
                    Text(loc.str(.adminNoParkings))
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .glassCard()
            } else {
                ForEach(store.ownedParkings.prefix(3)) { parking in
                    AdminParkingRow(parking: parking)
                }
            }
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .padding(8)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(value)
                .font(AppTheme.Typography.title2)
                .fontWeight(.bold)

            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard()
    }
}

// MARK: - Admin Parking Row

struct AdminParkingRow: View {
    let parking: Parking

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.Palette.surfaceSecondary)
                    .overlay(
                        Image(systemName: "car.fill")
                            .foregroundColor(AppTheme.Palette.textTertiary)
                    )
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(parking.name)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.semibold)

                Text(parking.address ?? parking.city)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 3) {
                    Image(systemName: "square.grid.3x3")
                        .font(.caption2)
                    Text("\(parking.total_spots)")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(AppTheme.Palette.textSecondary)

                Text("\(Int(parking.price_per_hour)) \(LocalizationManager.shared.str(.walletCurrency))")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Palette.brand)
                    .fontWeight(.medium)
            }
        }
        .padding(12)
        .glassCard(cornerRadius: AppTheme.Radius.medium)
    }
}
