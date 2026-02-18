import SwiftUI

struct HomeView: View {
    private let loc = LocalizationManager.shared

    @EnvironmentObject var parkings: ParkingsStore
    @EnvironmentObject var favorites: FavoritesStore
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore
    @Environment(AppCoordinator.self) private var coordinator

    @State private var search = ""
    @StateObject private var locationManager = LocationManager()
    @State private var didRequestLocation = false
    @State private var isRefreshing = false
    @ObservedObject private var notifManager = NotificationManager.shared

    /// Initial load holati — data hali kelmaguncha shimmer ko'rsatish uchun
    private var isInitialLoading: Bool {
        parkings.all.isEmpty && parkings.errorMessage == nil
    }

    private var searchQuery: String {
        search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var filteredPopular: [Parking] {
        guard !searchQuery.isEmpty else { return parkings.popular }
        return parkings.popular.filter {
            $0.name.lowercased().contains(searchQuery)
                || ($0.address ?? "").lowercased().contains(searchQuery)
        }
    }

    private var filteredNearby: [Parking] {
        guard !searchQuery.isEmpty else { return parkings.nearby }
        return parkings.nearby.filter {
            $0.name.lowercased().contains(searchQuery)
                || ($0.address ?? "").lowercased().contains(searchQuery)
        }
    }

    @State private var isScrolled = false

    var body: some View {
        ZStack {
            backgroundDecoration

            VStack(spacing: 0) {
                // MARK: - Sticky Header
                headerSection
                    .padding(.bottom, 8)

                // MARK: - Sticky Search Bar
                searchSection
                    .padding(.bottom, 4)
                    .background(AppTheme.Palette.pageBackground.opacity(0.72))
                    .shadow(
                        color: isScrolled ? Color.black.opacity(0.06) : Color.clear,
                        radius: isScrolled ? 6 : 0,
                        y: isScrolled ? 3 : 0
                    )
                    .zIndex(1)

                // MARK: - Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if isRefreshing || isInitialLoading {
                            HomeShimmerView()
                                .appReveal()
                        } else if let error = parkings.errorMessage, parkings.all.isEmpty {
                            AppStateView(
                                kind: .error(
                                    title: loc.str(.homeLoadFailed),
                                    subtitle: error,
                                    actionTitle: loc.str(.homeRetry),
                                    action: {
                                        parkings.load(
                                            userLocation: locationManager.location, force: true)
                                    }
                                )
                            )
                            .appReveal(0.05)
                            .padding(.top, 30)
                        } else if !parkings.isLoading && parkings.all.isEmpty {
                            AppStateView(
                                kind: .empty(
                                    icon: "car",
                                    title: loc.str(.homeNoParking),
                                    subtitle: loc.str(.homeCheckInternet)
                                )
                            )
                            .appReveal(0.05)
                            .padding(.top, 30)
                        } else {
                            popularSection
                                .appReveal(0.03)
                            nearbySection
                                .appReveal(0.08)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: geo.frame(in: .named("homeScroll")).minY
                            )
                        }
                    )
                }
                .coordinateSpace(name: "homeScroll")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    withAnimation(.easeOut(duration: 0.15)) {
                        isScrolled = value < -10
                    }
                }
                .id(parkings.reloadToken)
            }
        }

        .onAppear {
            if !didRequestLocation {
                didRequestLocation = true
                locationManager.requestPermission()
            }
        }
        .onChange(of: locationManager.location) { _, newValue in
            guard let loc = newValue else { return }
            parkings.load(userLocation: loc)
        }

        .refreshable {
            withAnimation { isRefreshing = true }
            await parkings.refresh(userLocation: locationManager.location)
            availabilityStore.initialLoad(force: true)
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeOut(duration: 0.3)) { isRefreshing = false }
        }

        .task {
            availabilityStore.initialLoad(force: false)
            availabilityStore.startRealtime()
            parkings.load(userLocation: locationManager.location)
        }
    }

    // MARK: - UI sections (sizning oldingi dizayn)

    private var backgroundDecoration: some View {
        AppAnimatedBackground()
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.str(.homeLocation))
                    .foregroundColor(AppTheme.Palette.textSecondary)
                    .font(.caption)
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(AppTheme.Palette.brand)
                    Text(locationManager.placeName)
                        .font(.headline)
                        .foregroundColor(AppTheme.Palette.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
            Button {
                coordinator.showNotifications()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(AppTheme.Palette.surface)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "bell.badge")
                                .foregroundColor(AppTheme.Palette.brand)
                        )

                    // Notification Badge
                    if notifManager.unreadCount > 0 {
                        Text("\(min(notifManager.unreadCount, 99))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.Palette.surface.opacity(0.90))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.Palette.border, lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(AppTheme.Palette.textSecondary)
            TextField(loc.str(.homeSearchParking), text: $search).autocorrectionDisabled()
                .foregroundColor(AppTheme.Palette.textPrimary)

            if !search.isEmpty {
                Button {
                    AppTheme.Haptic.light()
                    withAnimation(AppTheme.Anim.smooth) { search = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.Palette.textTertiary)
                        .font(.body)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, 12)
        .background(AppTheme.Palette.surface.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .stroke(AppTheme.Palette.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }

    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(loc.str(.homePopularParking)).font(AppTheme.Typography.title3)
                Spacer()
                if !filteredPopular.isEmpty {
                    Text("\(filteredPopular.count)")
                        .foregroundColor(AppTheme.Palette.textSecondary)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(filteredPopular) { parking in
                        ZStack(alignment: .topTrailing) {

                            Button {
                                coordinator.showParkingDetail(parking)
                            } label: {
                                PopularParkingCard(parking: parking)
                            }
                            .buttonStyle(.plain)

                            Button {
                                AppTheme.Haptic.medium()
                                favorites.toggle(parking.id)
                            } label: {
                                Image(
                                    systemName: favorites.isFavorite(parking.id)
                                        ? "heart.fill" : "heart"
                                )
                                .font(.callout)
                                .foregroundColor(favorites.isFavorite(parking.id) ? .red : .white)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .padding(14)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(loc.str(.homeNearbyParking)).font(AppTheme.Typography.title3)
                Spacer()
                if !filteredNearby.isEmpty {
                    Text("\(filteredNearby.count)")
                        .foregroundColor(AppTheme.Palette.textSecondary)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 16) {
                ForEach(filteredNearby) { parking in
                    Button {
                        coordinator.showParkingDetail(parking)
                    } label: {
                        NearbyParkingCard(
                            parking: parking,
                            isFavorite: favorites.isFavorite(parking.id),
                            onHeartTap: {
                                favorites.toggle(parking.id)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            if !searchQuery.isEmpty && filteredNearby.isEmpty && filteredPopular.isEmpty {
                AppStateView(
                    kind: .empty(
                        icon: "magnifyingglass",
                        title: loc.str(.homeSearchNoResults),
                        subtitle: loc.str(.homeSearchNoResultsSub)
                    )
                )
                .padding(.top, 20)
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
