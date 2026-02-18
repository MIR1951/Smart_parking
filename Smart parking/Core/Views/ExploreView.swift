internal import Combine
import CoreLocation
import MapKit
import SwiftUI

struct ExploreView: View {
    private let loc = LocalizationManager.shared

    @EnvironmentObject var parkings: ParkingsStore
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore
    @Environment(AppCoordinator.self) private var coordinator

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
    @State private var selectedCardId: UUID?
    @State private var scrolledCardId: UUID?
    @State private var isMarkerTap = false

    private var filtered: [Parking] {
        let base = parkings.nearby
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return base }

        return base.filter {
            $0.name.lowercased().contains(q) || ($0.address ?? "").lowercased().contains(q)
        }
    }

    private var visibleParkings: [Parking] {
        Array(filtered.prefix(10))
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                ForEach(filtered) { p in
                    Annotation(
                        "", coordinate: .init(latitude: p.latitude, longitude: p.longitude)
                    ) {
                        Button {
                            // Marker bosilganda card'ga scroll qilish
                            selectParking(p, fromMarker: true)
                        } label: {
                            ParkingMarkerView(
                                price: p.price_per_hour,
                                spots: availabilityStore.availability(for: p.id)?.availableSpots,
                                isSelected: selectedCardId == p.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .ignoresSafeArea()

            AppAnimatedBackground()
                .opacity(0.22)
                .allowsHitTesting(false)

            if !parkings.isLoading && !search.isEmpty && filtered.isEmpty {
                VStack {
                    AppStateView(
                        kind: .empty(
                            icon: "magnifyingglass",
                            title: loc.str(.exploreNoResults),
                            subtitle: loc.str(.exploreChangeSearch)
                        )
                    )
                    .appReveal(0.04)
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

                    TextField(loc.str(.exploreSearch), text: $search)
                        .autocorrectionDisabled()
                        .foregroundColor(AppTheme.Palette.textPrimary)

                    if !search.isEmpty {
                        Button {
                            AppTheme.Haptic.light()
                            withAnimation(AppTheme.Anim.smooth) { search = "" }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.Palette.textTertiary)
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppTheme.Palette.surface.opacity(0.88))
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
                        .background(AppTheme.Gradient.brand)
                        .cornerRadius(12)
                }
                .pressStyle()

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
                    .background(AppTheme.Gradient.brand)
                    .cornerRadius(12)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(
                        isRefreshing
                            ? .linear(duration: 1).repeatForever(autoreverses: false)
                            : .default,
                        value: isRefreshing
                    )
                }
                .pressStyle()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
            .alert(loc.str(.info), isPresented: $showFilterInfo) {
                Button(loc.str(.ok)) {}
            } message: {
                Text(loc.str(.exploreFilterInfo))
            }
        }

        // BOTTOM CARDS — overlay so map stays fullscreen
        .overlay(alignment: .bottom) {
            if isRefreshing {
                // Shimmer skeleton cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { _ in
                            PopularCardSkeleton()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }
                .background(
                    LinearGradient(
                        colors: [Color.clear, AppTheme.Palette.pageBackground.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            } else if !visibleParkings.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(visibleParkings.enumerated()), id: \.element.id) {
                            index, parking in
                            Button {
                                coordinator.showParkingDetail(parking)
                            } label: {
                                PopularParkingCard(parking: parking)
                                    .appReveal(Double(index) * 0.03)
                            }
                            .buttonStyle(.plain)
                            .id(parking.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }
                .scrollPosition(id: $scrolledCardId, anchor: .center)
                .onChange(of: scrolledCardId) { _, newId in
                    guard let newId, !isMarkerTap else { return }
                    selectedCardId = newId
                }
                .onAppear {
                    if scrolledCardId == nil, let first = visibleParkings.first {
                        scrolledCardId = first.id
                        selectedCardId = first.id
                    }
                }
                .background(
                    LinearGradient(
                        colors: [Color.clear, AppTheme.Palette.pageBackground.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
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
            if let loc, selectedCardId == nil {
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
        .onChange(of: selectedCardId) { _, newId in
            guard let newId,
                let parking = visibleParkings.first(where: { $0.id == newId })
            else { return }
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(
                            latitude: parking.latitude, longitude: parking.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                    )
                )
            }
        }
    }

    private func selectParking(_ parking: Parking, fromMarker: Bool = false) {
        AppTheme.Haptic.light()
        isMarkerTap = true
        selectedCardId = parking.id
        withAnimation {
            scrolledCardId = parking.id
        }
        // isMarkerTap bayrog'ini qaytarish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isMarkerTap = false
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
