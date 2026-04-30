import MapKit
import SwiftUI

struct EditorMapSection: View {
    @Environment(LocalizationManager.self) private var loc

    @Binding var pinCoordinate: CLLocationCoordinate2D?

    var availableCities: [String]
    var onAddressResolved: (String) -> Void
    var onCityResolved: (String) -> Void

    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.2995, longitude: 69.2401),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )
    @State private var searchQuery = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var resolvedAddress = ""

    var body: some View {
        VStack(spacing: 10) {
            searchBar

            if !searchResults.isEmpty {
                searchResultsList
            }

            mapView

            Text(loc.str(.adminTapMapHint))
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Palette.textTertiary)

            if let coord = pinCoordinate {
                coordinateInfo(coord)
            }
        }
        .onChange(of: pinCoordinate) { _, newCoord in
            guard let coord = newCoord else { return }
            withAnimation(AppTheme.Anim.snappy) {
                mapPosition = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Palette.textTertiary)
            TextField(loc.str(.adminSearchLocation), text: $searchQuery)
                .font(AppTheme.Typography.body)
                .onSubmit { searchLocation() }
            if isSearching {
                ProgressView().scaleEffect(0.8)
            } else if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.Palette.textTertiary)
                }
            }
        }
        .padding(10)
        .background(AppTheme.Palette.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
    }

    private var searchResultsList: some View {
        VStack(spacing: 4) {
            ForEach(searchResults.prefix(5), id: \.self) { item in
                Button { selectSearchResult(item) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(AppTheme.Palette.brand)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name ?? "")
                                .font(AppTheme.Typography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.Palette.textPrimary)
                                .lineLimit(1)
                            if let subtitle = item.placemark.formattedAddress {
                                Text(subtitle)
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.Palette.textTertiary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(AppTheme.Palette.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
    }

    private var mapView: some View {
        MapReader { proxy in
            Map(position: $mapPosition) {
                if let coord = pinCoordinate {
                    Annotation("", coordinate: coord) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(AppTheme.Palette.brand)
                            .background(Circle().fill(.white).frame(width: 20, height: 20))
                    }
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .gesture(
                LongPressGesture(minimumDuration: 0.35)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onEnded { value in
                        if case .second(true, let drag?) = value {
                            if let coord = proxy.convert(drag.location, from: .local) {
                                AppTheme.Haptic.success()
                                setPin(at: coord)
                                reverseGeocode(coord)
                            }
                        }
                    }
            )
            .onTapGesture { screenCoord in
                if let coordinate = proxy.convert(screenCoord, from: .local) {
                    AppTheme.Haptic.selection()
                    setPin(at: coordinate)
                    reverseGeocode(coordinate)
                }
            }
        }
    }

    private func coordinateInfo(_ coord: CLLocationCoordinate2D) -> some View {
        HStack(spacing: 12) {
            Label(
                String(format: "%.5f, %.5f", coord.latitude, coord.longitude),
                systemImage: "location.fill"
            )
            .font(AppTheme.Typography.caption)
            .foregroundColor(AppTheme.Palette.brand)

            Spacer()

            if !resolvedAddress.isEmpty {
                Text(resolvedAddress)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(AppTheme.Palette.brandSoft)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xSmall, style: .continuous))
    }

    // MARK: - Actions

    private func setPin(at coordinate: CLLocationCoordinate2D) {
        withAnimation(AppTheme.Anim.snappy) {
            pinCoordinate = coordinate
            mapPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
    }

    private func searchLocation() {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.2995, longitude: 69.2401),
            span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
        )
        Task {
            let search = MKLocalSearch(request: request)
            do { searchResults = try await search.start().mapItems }
            catch { searchResults = [] }
            isSearching = false
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        setPin(at: item.placemark.coordinate)
        searchQuery = item.name ?? ""
        searchResults = []
        if let addr = item.placemark.formattedAddress {
            resolvedAddress = addr
            onAddressResolved(addr)
        }
        if let locality = item.placemark.locality {
            let matched = availableCities.first {
                $0.localizedCaseInsensitiveContains(locality)
                    || locality.localizedCaseInsensitiveContains($0)
            }
            onCityResolved(matched ?? locality)
        }
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        Task {
            if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
                let parts = [placemark.thoroughfare, placemark.subThoroughfare, placemark.locality].compactMap { $0 }
                resolvedAddress = parts.joined(separator: ", ")
                onAddressResolved(resolvedAddress)
                if let locality = placemark.locality {
                    let matched = availableCities.first {
                        $0.localizedCaseInsensitiveContains(locality)
                            || locality.localizedCaseInsensitiveContains($0)
                    }
                    onCityResolved(matched ?? locality)
                }
            }
        }
    }
}

extension CLPlacemark {
    var formattedAddress: String? {
        let parts = [thoroughfare, subThoroughfare, locality, administrativeArea].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
