import CoreLocation
import MapKit
import SwiftUI

struct ExploreView: View {

    @EnvironmentObject var parkings: ParkingsStore
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore

    @State private var search = ""
    @StateObject private var locationManager = LocationManager()

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.3117, longitude: 69.2797),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )

    @State private var didRequestLocation = false
    @State private var showFilterInfo = false
    @State private var isRefreshing = false

    private var filtered: [Parking] {
        let base = parkings.nearby
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return base }

        return base.filter {
            $0.name.lowercased().contains(q) || ($0.address ?? "").lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {
                    ForEach(filtered) { p in
                        Annotation(
                            "", coordinate: .init(latitude: p.latitude, longitude: p.longitude)
                        ) {
                            Circle()
                                .fill(AppTheme.Palette.brand)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                .ignoresSafeArea()

                if !parkings.isLoading && !search.isEmpty && filtered.isEmpty {
                    VStack {
                        AppStateView(
                            kind: .empty(
                                icon: "magnifyingglass",
                                title: "Natija topilmadi",
                                subtitle: "Qidiruv matnini o'zgartirib ko'ring."
                            )
                        )
                        .padding(.top, 120)
                        Spacer()
                    }
                }
            }

            // TOP SEARCH BAR
            .safeAreaInset(edge: .top) {
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.Palette.textSecondary)

                        TextField("Search Parking", text: $search)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppTheme.Palette.surface)
                    .clipShape(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                            .stroke(AppTheme.Palette.border, lineWidth: 1)
                    )

                    Button {
                        showFilterInfo = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.Palette.brand)
                            .cornerRadius(12)
                    }

                    // Refresh button
                    Button {
                        Task { await refreshData() }
                    } label: {
                        Image(
                            systemName: isRefreshing
                                ? "arrow.triangle.2.circlepath" : "arrow.clockwise"
                        )
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.Palette.brand)
                        .cornerRadius(12)
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(
                            isRefreshing
                                ? .linear(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                            value: isRefreshing
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(AppTheme.Palette.pageBackground.opacity(0.9))
                .alert("Info", isPresented: $showFilterInfo) {
                    Button("OK") {}
                } message: {
                    Text("Filter bo'limi keyingi versiyada qo'shiladi.")
                }
            }

            // BOTTOM CARDS
            .safeAreaInset(edge: .bottom) {
                if isRefreshing {
                    // Shimmer skeleton cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(0..<3, id: \.self) { _ in
                                PopularCardSkeleton()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    }
                    .background(Color.clear)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(filtered.prefix(10)) { parking in
                                NavigationLink {
                                    ParkingDetailView(parking: parking)
                                } label: {
                                    PopularParkingCard(parking: parking)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    }
                    .background(Color.clear)
                }
            }

            .toolbar(.hidden, for: .navigationBar)

            .task {
                availabilityStore.initialLoad()
                availabilityStore.startRealtime()

                if !didRequestLocation {
                    didRequestLocation = true
                    locationManager.requestPermission()
                }

                if parkings.all.isEmpty && !parkings.isLoading {
                    parkings.load(userLocation: locationManager.location)
                }
            }
            .onChange(of: locationManager.location) { _, loc in
                if let loc {
                    withAnimation {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: loc.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            )
                        )
                    }
                }
                if parkings.all.isEmpty {
                    parkings.load(userLocation: loc, force: true)
                } else {
                    parkings.recomputeNearby(userLocation: loc)
                }
            }
        }
    }

    private func refreshData() async {
        isRefreshing = true
        await parkings.refresh(userLocation: locationManager.location)
        availabilityStore.initialLoad(force: true)
        // Shimmer ni biroz ko'rsatish
        try? await Task.sleep(nanoseconds: 800_000_000)
        withAnimation(.easeOut(duration: 0.3)) {
            isRefreshing = false
        }
    }
}
