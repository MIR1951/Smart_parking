//
//  HomeView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(LocalizationManager.self) private var loc
    @Environment(UserManager.self) private var userManager
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(AppCoordinator.self) private var coordinator

    @EnvironmentObject var parkingsStore: ParkingsStore
    @EnvironmentObject var favoritesStore: FavoritesStore
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore

    @State private var searchText = ""
    @State private var scrollOffset: CGFloat = 0

    private var filteredParkings: [Parking] {
        if searchText.isEmpty {
            return parkingsStore.all
        }
        let query = searchText.lowercased()
        return parkingsStore.all.filter {
            $0.name.lowercased().contains(query)
                || ($0.address ?? "").lowercased().contains(query)
        }
    }

    private var popularParkings: [Parking] {
        Array(
            filteredParkings.sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
                .prefix(5)
        )
    }

    private var nearbyParkings: [Parking] {
        Array(filteredParkings.prefix(10))
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppAnimatedBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Invisible offset tracker
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: ScrollOffsetKey.self,
                                value: geo.frame(in: .named("homeScroll")).minY
                            )
                    }
                    .frame(height: 0)

                    VStack(spacing: 24) {
                        // Hero header
                        heroHeader
                            .appReveal(0.0)

                        // Search bar
                        searchBar
                            .appReveal(0.05)

                        // Popular section
                        if !popularParkings.isEmpty {
                            popularSection
                                .appReveal(0.1)
                        }

                        // Nearby section
                        if !nearbyParkings.isEmpty {
                            nearbySection
                                .appReveal(0.15)
                        }

                        // Empty state
                        if filteredParkings.isEmpty && !parkingsStore.isLoading {
                            emptyState
                                .appReveal(0.1)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }
            }
            .coordinateSpace(name: "homeScroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                scrollOffset = value
            }

            // Sticky compact header
            if scrollOffset < -60 {
                stickyHeader
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .task {
            if parkingsStore.all.isEmpty {
                parkingsStore.load(userLocation: nil)
            }
            availabilityStore.initialLoad()
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Hero Header
    private var heroHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)

                Text(userManager.currentUser?.username ?? loc.str(.homeGreeting))
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Palette.textPrimary)
            }

            Spacer()

            // Notification bell
            Button {
                coordinator.showNotifications()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 46, height: 46)
                        .background(AppTheme.Palette.surfaceGlass)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.Palette.borderGlass, lineWidth: 1)
                        )

                    if notificationManager.unreadCount > 0 {
                        Text("\(notificationManager.unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                AppTheme.Palette.danger, Color(hex: "#FF7675"),
                                            ],
                                            startPoint: .top, endPoint: .bottom
                                        )
                                    )
                            )
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .pressStyle()
        }
        .padding(.horizontal, 20)
    }

    private var greeting: String {
        loc.str(.homeGreeting)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Palette.brandLight)
                .font(.system(size: 16, weight: .medium))

            TextField(loc.str(.homeSearch), text: $searchText)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Palette.textPrimary)
                .tint(AppTheme.Palette.brand)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.Palette.textTertiary)
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: AppTheme.Radius.medium)
        .padding(.horizontal, 20)
    }

    // MARK: - Popular Section
    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppTheme.Palette.brand)
                        .font(.system(size: 16))
                    Text(loc.str(.homePopular))
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Palette.textPrimary)
                }

                Spacer()

                Button(loc.str(.homeSeeAll)) {
                    coordinator.selectedTab = .explore
                }
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.Palette.brandLight)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(popularParkings) { parking in
                        NavigationLink(value: AppRoute.parkingDetail(parking)) {
                            PopularParkingCard(
                                parking: parking,
                                availability: availabilityStore.availability(for: parking.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .pressStyle()
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Nearby Section
    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(AppTheme.Palette.accent)
                        .font(.system(size: 16))
                    Text(loc.str(.homeNearby))
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Palette.textPrimary)
                }

                Spacer()

                Button(loc.str(.homeSeeAll)) {
                    coordinator.selectedTab = .explore
                }
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.Palette.brandLight)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(nearbyParkings) { parking in
                    NavigationLink(value: AppRoute.parkingDetail(parking)) {
                        NearbyParkingCard(
                            parking: parking,
                            availability: availabilityStore.availability(for: parking.id),
                            isFavorite: favoritesStore.isFavorite(parking.id),
                            onToggleFavorite: {
                                Task {
                                    favoritesStore.toggle(parking.id)
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .pressStyle()
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Sticky Header
    private var stickyHeader: some View {
        HStack {
            Text(userManager.currentUser?.username ?? loc.str(.homeGreeting))
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Palette.textPrimary)

            Spacer()

            Button {
                coordinator.showNotifications()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Palette.brand)

                    if notificationManager.unreadCount > 0 {
                        Circle()
                            .fill(AppTheme.Palette.danger)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -2)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(AppTheme.Palette.border)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            Text(loc.str(.homeNoResults))
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Palette.textPrimary)

            Text(loc.str(.homeSearchNoResultsSub))
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .glassCard()
        .padding(.horizontal, 20)
    }
}

// MARK: - Scroll Offset

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
