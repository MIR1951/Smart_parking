import SwiftUI

struct HomeView: View {

    @EnvironmentObject var parkings: ParkingsStore
    @EnvironmentObject var favorites: FavoritesStore
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore

    @State private var search = ""
    @StateObject private var locationManager = LocationManager()
    @State private var didRequestLocation = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    searchSection
                    popularSection
                    nearbySection
                }
                .padding(.vertical)
            }

            .overlay {
                if parkings.isLoading && parkings.all.isEmpty {
                    ZStack {
                        Color.black.opacity(0.08).ignoresSafeArea()
                        ProgressView("Loading...")
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(14)
                    }
                }
            }
            .id(parkings.reloadToken)

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
                await parkings.refresh(userLocation: locationManager.location)
                availabilityStore.initialLoad(force: true)

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
                Text("Location").foregroundColor(.gray).font(.caption)
                HStack {
                    Image(systemName: "location.fill").foregroundColor(.primary)
                    Text(locationManager.placeName)
                        .font(.headline)
                        .foregroundColor(.black)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            NavigationLink(destination: NotificationsView()) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.primary.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: "bell").foregroundColor(.primary))

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
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField("Search Parking", text: $search).autocorrectionDisabled()
        }
        .padding()
        .background(Color.bgLight)
        .cornerRadius(15)
        .padding(.horizontal)
    }

    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Popular Parking").font(.title3).fontWeight(.semibold)
                Spacer()
                Text("See All").foregroundColor(.primary).font(.subheadline)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(parkings.popular) { parking in
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
                Text("See All").foregroundColor(.primary).font(.subheadline)
            }
            .padding(.horizontal)

            VStack(spacing: 16) {
                ForEach(parkings.nearby) { parking in
                    NavigationLink {
                        ParkingDetailView(parking: parking)
                    } label: {
                        NearbyParkingCard(
                            parking: parking,
                            onHeartTap: {
                                favorites.toggle(parking.id)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
