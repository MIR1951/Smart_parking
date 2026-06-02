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
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(AppCoordinator.self) private var coordinator

    @EnvironmentObject var parkingsStore: ParkingsStore
    @EnvironmentObject var favoritesStore: FavoritesStore
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore

    @State private var searchText = ""
    @State private var badgePulse = false
    @State private var scrollOffset: CGFloat = 0

    private var headerProgress: CGFloat {
        min(max(scrollOffset / 200, 0), 1)
    }

    private var popularParkings: [Parking] {
        filterBySearch(parkingsStore.popular)
    }

    private var nearbyParkings: [Parking] {
        filterBySearch(parkingsStore.nearby)
    }

    var body: some View {
        ZStack {
            AppAnimatedBackground()

            VStack(spacing: 0) {
                topSection

                if parkingsStore.isLoading && popularParkings.isEmpty && nearbyParkings.isEmpty {
                    ScrollView(showsIndicators: false) {
                        HomeShimmerView()
                            .padding(.top, 16)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: -geo.frame(in: .named("homeScroll")).minY
                                )
                        }
                        .frame(height: 0)

                        VStack(spacing: 24) {
                            if !popularParkings.isEmpty {
                                popularSection
                                    .appReveal(0.04)
                            }

                            if !nearbyParkings.isEmpty {
                                nearbySection
                                    .appReveal(0.08)
                            }

                            if popularParkings.isEmpty && nearbyParkings.isEmpty
                                && !parkingsStore.isLoading
                            {
                                emptyState
                                    .appReveal(0.1)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                    .coordinateSpace(name: "homeScroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        withAnimation(AppTheme.Anim.snappy) { scrollOffset = value }
                    }
                    .refreshable {
                        await refreshAllHomeData()
                    }
                }
            }
        }
        .task {
            locationManager.requestPermission()

            parkingsStore.bootstrapCity(using: locationManager.placeName, fallback: "Tashkent")
            parkingsStore.applyFilters(userLocation: locationManager.location)
        }
        .onChange(of: locationManager.location) { _, newLocation in
            parkingsStore.applyFilters(userLocation: newLocation)
        }
        .onChange(of: locationManager.placeName) { _, newPlace in
            parkingsStore.bootstrapCity(using: newPlace, fallback: "Tashkent")
        }
        .onChange(of: parkingsStore.availableCities) { _, _ in
            parkingsStore.bootstrapCity(using: locationManager.placeName, fallback: "Tashkent")
        }
        .onChange(of: notificationManager.unreadCount) { oldValue, newValue in
            if newValue > oldValue {
                AppTheme.Haptic.light()
                badgePulse = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { badgePulse = true }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func filterBySearch(_ items: [Parking]) -> [Parking] {
        if searchText.isEmpty {
            return items
        }
        let query = searchText.lowercased()
        return items.filter {
            $0.name.lowercased().contains(query)
                || ($0.address ?? "").lowercased().contains(query)
        }
    }

    // MARK: - Fixed Top Section
    private var topSection: some View {
        VStack(spacing: 14) {
            heroHeader
                .appReveal(0.0)

            cityAndSearch
                .appReveal(0.02)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var heroHeader: some View {
        let titleSize: CGFloat = 28 - (headerProgress * 8)   // 28 → 20
        let bellSize: CGFloat = 46 - (headerProgress * 10)   // 46 → 36
        let greetingOpacity: Double = max(0, min(1, Double(1 - headerProgress * 2)))

        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                    .opacity(greetingOpacity)

                Text(userManager.currentUser?.username ?? loc.str(.homeGreeting))
                    .font(.system(size: titleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Palette.textPrimary)
            }

            Spacer()

            Button {
                coordinator.showNotifications()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20 - headerProgress * 4))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Palette.brand, AppTheme.Palette.homeAccent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: bellSize, height: bellSize)
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
                                                AppTheme.Palette.danger, AppTheme.Palette.accent,
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .scaleEffect(badgePulse ? 1.15 : 1.0)
                            .shadow(color: AppTheme.Palette.danger.opacity(badgePulse ? 0.6 : 0.2), radius: badgePulse ? 6 : 2)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: badgePulse)
                            .offset(x: 4, y: -4)
                            .onAppear { badgePulse = true }
                    }
                }
            }
            .pressStyle()
        }
    }

    private var cityAndSearch: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                cityMenu

                HStack(spacing: 10) {
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
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .glassCard(cornerRadius: AppTheme.Radius.medium)
            }
        }
    }

    private var cityMenu: some View {
        Menu {
            ForEach(parkingsStore.availableCities, id: \.self) { city in
                Button {
                    parkingsStore.setSelectedCity(city)
                } label: {
                    if parkingsStore.selectedCity.caseInsensitiveCompare(city) == .orderedSame {
                        Label(city, systemImage: "checkmark")
                    } else {
                        Text(city)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.Palette.brand)

                Text(parkingsStore.selectedCity)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundColor(AppTheme.Palette.textPrimary)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: AppTheme.Radius.medium)
            .frame(minWidth: 110, alignment: .leading)
        }
    }

    private var greeting: String {
        loc.str(.homeGreeting)
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
                                availability: availabilityStore.availability(for: parking.id),
                                distance: parking.distance(from: locationManager.location),
                                isFavorite: favoritesStore.isFavorite(parking.id),
                                onToggleFavorite: {
                                    AppTheme.Haptic.success()
                                    Task { @MainActor in
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
                            distance: parking.distance(from: locationManager.location),
                            isFavorite: favoritesStore.isFavorite(parking.id),
                            onToggleFavorite: {
                                AppTheme.Haptic.success()
                                Task { @MainActor in
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

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                        startPoint: .top,
                        endPoint: .bottom
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

    @MainActor
    private func refreshAllHomeData() async {
        await parkingsStore.loadAvailableCities()
        await parkingsStore.refresh(userLocation: locationManager.location)
        await availabilityStore.refreshNow(force: true)
        await notificationManager.load()
        parkingsStore.bootstrapCity(using: locationManager.placeName, fallback: "Tashkent")
        parkingsStore.applyFilters(userLocation: locationManager.location)
    }
}
