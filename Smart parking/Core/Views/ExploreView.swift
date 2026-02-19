//
//  ExploreView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import MapKit
import SwiftUI

struct ExploreView: View {
    @Environment(LocalizationManager.self) private var loc
    @EnvironmentObject var locationManager: LocationManager

    @EnvironmentObject var parkingsStore: ParkingsStore
    @EnvironmentObject var favoritesStore: FavoritesStore
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedParking: Parking?
    @State private var searchText = ""

    @State private var cameraDistance: CLLocationDistance = 5000
    @State private var cameraCenter: CLLocationCoordinate2D?

    private let minCameraDistance: CLLocationDistance = 300
    private let maxCameraDistance: CLLocationDistance = 25_000
    private let defaultCenter = CLLocationCoordinate2D(latitude: 41.3111, longitude: 69.2797)

    private var filteredParkings: [Parking] {
        if searchText.isEmpty { return parkingsStore.all }
        let query = searchText.lowercased()
        return parkingsStore.all.filter {
            $0.name.lowercased().contains(query)
                || ($0.address ?? "").lowercased().contains(query)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position, selection: $selectedParking) {
                ForEach(filteredParkings) { parking in
                    Annotation(
                        parking.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: parking.latitude,
                            longitude: parking.longitude
                        )
                    ) {
                        mapMarker(for: parking)
                    }
                    .tag(parking)
                }

                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .ignoresSafeArea(edges: .top)
            .onMapCameraChange(frequency: .continuous) { context in
                cameraCenter = context.camera.centerCoordinate
                cameraDistance = context.camera.distance
            }
            .onChange(of: selectedParking) { _, newParking in
                guard let parking = newParking else { return }
                let center = CLLocationCoordinate2D(
                    latitude: parking.latitude,
                    longitude: parking.longitude
                )
                moveCamera(to: center, distance: 1200, pitch: 45)
            }
            .overlay(alignment: .topTrailing) {
                zoomControls
                    .padding(.trailing, 20)
                    .padding(.top, 92)
            }

            if !filteredParkings.isEmpty {
                bottomCardCarousel
            }
        }
        .safeAreaInset(edge: .top) {
            searchOverlay
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
        .task {
            locationManager.requestPermission()

            if let location = locationManager.location {
                moveCamera(to: location.coordinate, distance: 5000)
            } else {
                moveCamera(to: defaultCenter, distance: 5000)
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            guard selectedParking == nil else { return }
            guard let location = newLocation else { return }
            moveCamera(to: location.coordinate, distance: max(cameraDistance, 5000))
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Map Marker
    @ViewBuilder
    private func mapMarker(for parking: Parking) -> some View {
        let isSelected = selectedParking?.id == parking.id

        Button {
            withAnimation(AppTheme.Anim.snappy) {
                selectedParking = parking
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                                    startPoint: .top, endPoint: .bottom)
                                : LinearGradient(
                                    colors: [AppTheme.Palette.surface, AppTheme.Palette.surface],
                                    startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                        .shadow(
                            color: isSelected
                                ? AppTheme.Palette.brand.opacity(0.4)
                                : Color.black.opacity(0.15),
                            radius: isSelected ? 10 : 4,
                            y: isSelected ? 4 : 2
                        )

                    Image(systemName: "car.fill")
                        .font(.system(size: isSelected ? 18 : 14))
                        .foregroundColor(isSelected ? .white : AppTheme.Palette.brand)
                }

                Text(parking.formattedPrice)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(AppTheme.Palette.brand)
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(AppTheme.Anim.snappy, value: isSelected)
    }

    // MARK: - Search Overlay
    private var searchOverlay: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Palette.brandLight)
                .font(.system(size: 16))

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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .stroke(AppTheme.Palette.borderGlass, lineWidth: 1)
        )
        .shadow(color: AppTheme.Palette.brand.opacity(0.1), radius: 16, y: 6)
    }

    // MARK: - Zoom Controls
    private var zoomControls: some View {
        VStack(spacing: 10) {
            zoomButton(systemName: "plus", accessibilityText: loc.str(.mapZoomIn)) {
                applyZoom(multiplier: 0.7)
            }
            zoomButton(systemName: "minus", accessibilityText: loc.str(.mapZoomOut)) {
                applyZoom(multiplier: 1.3)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .stroke(AppTheme.Palette.borderGlass, lineWidth: 1)
        )
        .shadow(color: AppTheme.Palette.brand.opacity(0.18), radius: 10, y: 4)
    }

    private func zoomButton(
        systemName: String,
        accessibilityText: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.Palette.textPrimary)
                .frame(width: 36, height: 36)
                .background(AppTheme.Palette.surface.opacity(0.8))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
    }

    private func applyZoom(multiplier: CLLocationDistance) {
        let currentDistance = cameraDistance > 0 ? cameraDistance : 5000
        let targetDistance = min(max(currentDistance * multiplier, minCameraDistance), maxCameraDistance)
        let center =
            selectedParkingCoordinate
            ?? locationManager.location?.coordinate
            ?? cameraCenter
            ?? defaultCenter

        moveCamera(to: center, distance: targetDistance)
    }

    private var selectedParkingCoordinate: CLLocationCoordinate2D? {
        guard let parking = selectedParking else { return nil }
        return CLLocationCoordinate2D(latitude: parking.latitude, longitude: parking.longitude)
    }

    private func moveCamera(to center: CLLocationCoordinate2D, distance: CLLocationDistance, pitch: CGFloat = 0) {
        cameraCenter = center
        cameraDistance = distance
        withAnimation(AppTheme.Anim.smooth) {
            position = .camera(
                MapCamera(
                    centerCoordinate: center,
                    distance: distance,
                    heading: 0,
                    pitch: pitch
                )
            )
        }
    }

    // MARK: - Bottom Card Carousel
    private var bottomCardCarousel: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(filteredParkings) { parking in
                        NavigationLink(value: AppRoute.parkingDetail(parking)) {
                            exploreCard(parking)
                        }
                        .buttonStyle(.plain)
                        .pressStyle()
                        .id(parking.id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .onChange(of: selectedParking) { _, newParking in
                if let parking = newParking {
                    withAnimation(AppTheme.Anim.smooth) {
                        proxy.scrollTo(parking.id, anchor: .center)
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Explore Card
    @ViewBuilder
    private func exploreCard(_ parking: Parking) -> some View {
        let availability = availabilityStore.availability(for: parking.id)

        HStack(spacing: 12) {
            CachedAsyncImage(url: parking.imageUrl) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(AppTheme.Palette.brand.opacity(0.1))
                    .overlay(
                        Image(systemName: "car.fill")
                            .foregroundColor(AppTheme.Palette.brand.opacity(0.3))
                    )
            }
            .frame(width: 75, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(parking.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Palette.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Palette.brandLight)
                    Text(parking.address ?? "")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                        .lineLimit(1)
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(parking.formattedPrice)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text(loc.str(.bookingsPerHour))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.Palette.textSecondary)
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(availabilityColor(for: availability))
                            .frame(width: 6, height: 6)
                        Text(availabilityText(for: availability))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.Palette.textSecondary)
                    }
                }
            }
        }
        .padding(10)
        .frame(width: 250)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                .stroke(
                    selectedParking?.id == parking.id
                        ? AppTheme.Palette.brand.opacity(0.5)
                        : AppTheme.Palette.borderGlass,
                    lineWidth: selectedParking?.id == parking.id ? 1.5 : 1
                )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
    }

    private func availabilityText(for availability: ParkingAvailability?) -> String {
        guard let availability else { return "--/--" }
        return "\(availability.available)/\(availability.total)"
    }

    private func availabilityColor(for availability: ParkingAvailability?) -> Color {
        guard let availability else { return AppTheme.Palette.textTertiary }
        let ratio = Double(availability.available) / Double(max(availability.total, 1))
        if ratio > 0.3 { return AppTheme.Palette.success }
        if ratio > 0 { return AppTheme.Palette.warning }
        return AppTheme.Palette.danger
    }
}
