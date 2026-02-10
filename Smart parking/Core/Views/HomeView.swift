import SwiftUI

struct HomeView: View {

    @EnvironmentObject var parkings: ParkingsStore
    @EnvironmentObject var favorites: FavoritesStore
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore

    @State private var search = ""
    @StateObject private var locationManager = LocationManager()
    @State private var didRequestLocation = false
    @State private var isRefreshing = false

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

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Palette.pageBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        searchSection
                        if isRefreshing || (parkings.isLoading && parkings.all.isEmpty) {
                            // Shimmer skeleton
                            HomeShimmerView()
                        } else if let error = parkings.errorMessage, parkings.all.isEmpty {
                            AppStateView(
                                kind: .error(
                                    title: "Parkinglar yuklanmadi",
                                    subtitle: error,
                                    actionTitle: "Qayta urinish",
                                    action: {
                                        parkings.load(
                                            userLocation: locationManager.location, force: true)
                                    }
                                )
                            )
                            .padding(.top, 30)
                        } else if !parkings.isLoading && parkings.all.isEmpty {
                            AppStateView(
                                kind: .empty(
                                    icon: "car",
                                    title: "Parking topilmadi",
                                    subtitle: "Internet yoki joylashuvni tekshirib ko'ring."
                                )
                            )
                            .padding(.top, 30)
                        } else {
                            popularSection
                            nearbySection
                        }
                    }
                    .padding(.vertical)
                }
                .id(parkings.reloadToken)
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
            }
        }
    }

    // MARK: - UI sections (sizning oldingi dizayn)

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Location").foregroundColor(AppTheme.Palette.textSecondary).font(.caption)
                HStack {
                    Image(systemName: "location.fill").foregroundColor(AppTheme.Palette.brand)
                    Text(locationManager.placeName)
                        .font(.headline)
                        .foregroundColor(AppTheme.Palette.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }
            }
            Spacer()
            NavigationLink(destination: NotificationsView()) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(AppTheme.Palette.brandSoft)
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: "bell").foregroundColor(AppTheme.Palette.brand))

                    // Notification Badge
                    if NotificationManager.shared.unreadCount > 0 {
                        Text("\(min(NotificationManager.shared.unreadCount, 99))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(AppTheme.Palette.textSecondary)
            TextField("Search parking", text: $search).autocorrectionDisabled()
                .foregroundColor(AppTheme.Palette.textPrimary)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, 12)
        .background(AppTheme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .stroke(AppTheme.Palette.border, lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Popular Parking").font(.title3).fontWeight(.semibold)
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

                            NavigationLink {
                                ParkingDetailView(parking: parking)
                            } label: {
                                PopularParkingCard(parking: parking)
                            }

                            Button {
                                favorites.toggle(parking.id)
                            } label: {
                                Image(
                                    systemName: favorites.isFavorite(parking.id)
                                        ? "heart.fill" : "heart"
                                )
                                .foregroundColor(favorites.isFavorite(parking.id) ? .red : .white)
                                .padding(10)
                                .background(Color.black.opacity(0.35))
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
                Text("Nearby Parking").font(.title3).fontWeight(.semibold)
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
                    NavigationLink {
                        ParkingDetailView(parking: parking)
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
                        title: "Natija topilmadi",
                        subtitle: "Boshqa nom yoki manzil bilan qidirib ko'ring."
                    )
                )
                .padding(.top, 20)
            }
        }
    }
}
