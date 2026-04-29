//
//  AdminParkingEditorView.swift
//  Smart parking
//
//  Parking qo'shish / tahrirlash formasi — map picker + rasm yuklash + shahar tanlash
//

import MapKit
import os
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct AdminParkingEditorView: View {
    @Bindable var store: AdminStore
    let parking: Parking?
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc

    // Form fields
    @State private var name = ""
    @State private var city = ""
    @State private var address = ""
    @State private var pricePerHour = ""
    @State private var totalSpots = ""
    @State private var description = ""
    @State private var selectedFeatures: Set<String> = []
    @State private var showCityPicker = false

    // Map
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.2995, longitude: 69.2401),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )
    @State private var pinCoordinate: CLLocationCoordinate2D?
    @State private var searchQuery = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var resolvedAddress = ""

    // Images
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var existingImageURLs: [String] = []
    @State private var isDroppingImages = false

    // State
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let availableFeatures = [
        "CCTV", "24/7", "Covered", "EV Charging", "Disabled Access",
        "Security Guard", "WiFi", "Car Wash", "Valet",
    ]

    private var isEditing: Bool { parking != nil }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    basicInfoSection
                        .appReveal(0)

                    locationSection
                        .appReveal(0.05)

                    pricingSection
                        .appReveal(0.1)

                    descriptionSection
                        .appReveal(0.15)

                    featuresSection
                        .appReveal(0.2)

                    imagesSection
                        .appReveal(0.25)

                    // Save Button
                    AppPrimaryButton(
                        title: isProcessing
                            ? loc.str(.adminSaving)
                            : (isEditing ? loc.str(.adminSave) : loc.str(.adminAddParking)),
                        isLoading: isProcessing,
                        isEnabled: isFormValid && !isProcessing
                    ) {
                        save()
                    }
                    .padding(.top, 8)
                    .appReveal(0.3)
                }
                .padding()
            }
            .background(AppAnimatedBackground())
            .navigationTitle(isEditing ? loc.str(.adminEdit) : loc.str(.adminNewParking))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.str(.adminCancel)) { dismiss() }
                }
            }
            .alert(loc.str(.adminError), isPresented: $showError) {
                Button(loc.str(.ok)) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear { loadExistingData() }
        }
    }

    // MARK: - Basic Info

    private var basicInfoSection: some View {
        formSection(title: loc.str(.adminBasicInfo), icon: "info.circle") {
            formField(loc.str(.adminParkingName), text: $name)

            // City picker
            Button {
                showCityPicker.toggle()
            } label: {
                HStack {
                    Text(city.isEmpty ? loc.str(.adminSelectCity) : city)
                        .foregroundColor(city.isEmpty ? AppTheme.Palette.textTertiary : AppTheme.Palette.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textTertiary)
                }
                .font(AppTheme.Typography.body)
                .padding(14)
                .background(AppTheme.Palette.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
            }

            if showCityPicker {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(store.availableCities, id: \.self) { cityName in
                            Button {
                                city = cityName
                                showCityPicker = false
                            } label: {
                                HStack {
                                    Text(cityName)
                                        .font(AppTheme.Typography.body)
                                        .foregroundColor(city == cityName ? AppTheme.Palette.brand : AppTheme.Palette.textPrimary)
                                    Spacer()
                                    if city == cityName {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.Palette.brand)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(city == cityName ? AppTheme.Palette.brandSoft : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xSmall, style: .continuous))
                            }
                        }
                    }
                }
                .frame(maxHeight: 220)
                .padding(8)
                .background(AppTheme.Palette.surfaceSecondary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
            }

            formField(loc.str(.adminAddress), text: $address)
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        formSection(title: loc.str(.adminLocation), icon: "mappin.circle") {
            VStack(spacing: 10) {
                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.Palette.textTertiary)
                    TextField(loc.str(.adminSearchLocation), text: $searchQuery)
                        .font(AppTheme.Typography.body)
                        .onSubmit { searchLocation() }
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
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

                // Search results
                if !searchResults.isEmpty {
                    VStack(spacing: 4) {
                        ForEach(searchResults.prefix(5), id: \.self) { item in
                            Button {
                                selectSearchResult(item)
                            } label: {
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

                // Map
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

                // Info text
                Text(loc.str(.adminTapMapHint))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Palette.textTertiary)

                // Resolved coordinates
                if let coord = pinCoordinate {
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
            }
        }
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        formSection(title: loc.str(.adminPriceCapacity), icon: "banknote") {
            HStack(spacing: 12) {
                formField(loc.str(.adminPricePerHour), text: $pricePerHour)
                    .keyboardType(.numberPad)
                formField(loc.str(.adminTotalSpots), text: $totalSpots)
                    .keyboardType(.numberPad)
            }
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        formSection(title: loc.str(.adminDescription), icon: "text.alignleft") {
            TextEditor(text: $description)
                .frame(minHeight: 80)
                .padding(8)
                .font(AppTheme.Typography.body)
                .scrollContentBackground(.hidden)
                .background(AppTheme.Palette.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        formSection(title: loc.str(.adminFeatures), icon: "star.circle") {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(availableFeatures, id: \.self) { feature in
                    featureChip(feature)
                }
            }
        }
    }

    // MARK: - Images

    private var imagesSection: some View {
        formSection(title: loc.str(.adminImages), icon: "photo.on.rectangle") {
            VStack(spacing: 12) {
                // Existing images
                if !existingImageURLs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(existingImageURLs.enumerated()), id: \.element) { index, url in
                                ZStack(alignment: .topTrailing) {
                                    CachedAsyncImage(url: URL(string: url)) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(AppTheme.Palette.surfaceSecondary)
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .clipped()

                                    Button {
                                        existingImageURLs.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                            .shadow(radius: 2)
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }
                        }
                    }
                }

                // New selected images
                if !selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable().scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .clipped()

                                    Button {
                                        selectedImages.remove(at: index)
                                        if index < selectedPhotoItems.count {
                                            selectedPhotoItems.remove(at: index)
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                            .shadow(radius: 2)
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }
                        }
                    }
                }

                let totalImages = existingImageURLs.count + selectedImages.count
                let maxNewImages = max(0, 5 - totalImages)
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: max(1, maxNewImages),
                    matching: .images
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                        Text(loc.str(.adminAddImage))
                    }
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Palette.brand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.Palette.brandSoft)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
                }
                .disabled(totalImages >= 5)
                .opacity(totalImages >= 5 ? 0.5 : 1)
                .pressStyle()
                .onChange(of: selectedPhotoItems) { _, newItems in
                    Task { await loadSelectedImages(from: newItems) }
                }

                Text(loc.str(.adminImageHint))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Palette.textTertiary)

                // Drag & Drop zone
                if totalImages < 5 {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .strokeBorder(
                                isDroppingImages ? AppTheme.Palette.brand : AppTheme.Palette.textTertiary.opacity(0.4),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6])
                            )
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                    .fill(isDroppingImages ? AppTheme.Palette.brandSoft : Color.clear)
                            )
                            .frame(height: 64)

                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.to.line")
                                .font(.title3)
                                .foregroundColor(isDroppingImages ? AppTheme.Palette.brand : AppTheme.Palette.textTertiary)
                            Text(loc.str(.adminDropHint))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(isDroppingImages ? AppTheme.Palette.brand : AppTheme.Palette.textTertiary)
                        }
                    }
                    .onDrop(of: [UTType.image], isTargeted: $isDroppingImages) { providers in
                        handleDroppedImages(providers)
                    }
                }
            }
        }
    }

    // MARK: - Form Helpers

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !city.trimmingCharacters(in: .whitespaces).isEmpty
            && pinCoordinate != nil
            && Double(pricePerHour) != nil
            && Int(totalSpots) != nil
    }

    private func formSection(title: String, icon: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Palette.brand)
                Text(title)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }
            content()
        }
        .padding()
        .glassCard()
    }

    private func formField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(AppTheme.Typography.body)
            .padding(14)
            .background(AppTheme.Palette.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
    }

    private func featureChip(_ feature: String) -> some View {
        let isSelected = selectedFeatures.contains(feature)
        return Text(feature)
            .font(AppTheme.Typography.caption)
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : AppTheme.Palette.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                            startPoint: .leading, endPoint: .trailing
                        ))
                    : AnyShapeStyle(AppTheme.Palette.surfaceSecondary)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .onTapGesture {
                withAnimation(AppTheme.Anim.quick) {
                    if isSelected { selectedFeatures.remove(feature) }
                    else { selectedFeatures.insert(feature) }
                }
            }
    }

    // MARK: - Map / Location

    private func setPin(at coordinate: CLLocationCoordinate2D) {
        withAnimation(AppTheme.Anim.snappy) {
            pinCoordinate = coordinate
            mapPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )
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
            do {
                let response = try await search.start()
                searchResults = response.mapItems
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        let coord = item.placemark.coordinate
        setPin(at: coord)
        searchQuery = item.name ?? ""
        searchResults = []

        if let addr = item.placemark.formattedAddress {
            resolvedAddress = addr
            if address.isEmpty { address = addr }
        }
        // Shaharni avtomatik to'ldirish
        if city.isEmpty, let localityName = item.placemark.locality {
            let matched = store.availableCities.first {
                $0.localizedCaseInsensitiveContains(localityName)
                    || localityName.localizedCaseInsensitiveContains($0)
            }
            city = matched ?? localityName
        }
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        Task {
            if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
                let parts = [placemark.thoroughfare, placemark.subThoroughfare, placemark.locality].compactMap { $0 }
                resolvedAddress = parts.joined(separator: ", ")
                if address.isEmpty { address = resolvedAddress }
                // Shaharni avtomatik to'ldirish
                if city.isEmpty, let localityName = placemark.locality {
                    let matched = store.availableCities.first {
                        $0.localizedCaseInsensitiveContains(localityName)
                            || localityName.localizedCaseInsensitiveContains($0)
                    }
                    city = matched ?? localityName
                }
            }
        }
    }

    // MARK: - Image Helpers

    @discardableResult
    private func handleDroppedImages(_ providers: [NSItemProvider]) -> Bool {
        let total = existingImageURLs.count + selectedImages.count
        let canAdd = max(0, 5 - total)
        guard canAdd > 0 else { return false }

        var added = 0
        for provider in providers.prefix(canAdd) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                guard let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self.selectedImages.append(image)
                }
                added += 1
            }
        }
        return true
    }

    private func loadSelectedImages(from items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        await MainActor.run { selectedImages = images }
    }

    private func uploadImages() async throws -> [String] {
        let storageManager = SupabaseStorageManager()
        var urls: [String] = []
        let slug = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased().replacingOccurrences(of: " ", with: "-")

        for image in selectedImages {
            guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
            let url = try await storageManager.uploadParkingImage(
                imageData: data,
                city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                parkingSlug: slug
            )
            urls.append(url)
        }
        return urls
    }

    // MARK: - Data

    private func loadExistingData() {
        guard let parking else { return }
        name = parking.name
        city = parking.city
        address = parking.address ?? ""
        pricePerHour = "\(Int(parking.price_per_hour))"
        totalSpots = "\(parking.total_spots)"
        description = parking.description ?? ""
        if let features = parking.features { selectedFeatures = Set(features) }
        existingImageURLs = parking.images ?? []

        let coord = CLLocationCoordinate2D(latitude: parking.latitude, longitude: parking.longitude)
        pinCoordinate = coord
        mapPosition = .region(
            MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }

    private func save() {
        guard isFormValid, let coord = pinCoordinate else { return }
        isProcessing = true

        Task {
            do {
                var allImageURLs = existingImageURLs
                if !selectedImages.isEmpty {
                    let newURLs = try await uploadImages()
                    allImageURLs.append(contentsOf: newURLs)
                }

                if let parking {
                    try await store.updateParking(
                        id: parking.id,
                        name: name.trimmed,
                        city: city.trimmed.isEmpty ? nil : city.trimmed,
                        address: address.trimmed.isEmpty ? nil : address.trimmed,
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        pricePerHour: Double(pricePerHour),
                        totalSpots: Int(totalSpots),
                        description: description.trimmed.isEmpty ? nil : description.trimmed,
                        features: selectedFeatures.isEmpty ? nil : Array(selectedFeatures),
                        images: allImageURLs.isEmpty ? nil : allImageURLs
                    )
                } else {
                    try await store.createParking(
                        name: name.trimmed,
                        city: city.trimmed,
                        address: address.trimmed.isEmpty ? nil : address.trimmed,
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        pricePerHour: Double(pricePerHour) ?? 0,
                        totalSpots: Int(totalSpots) ?? 0,
                        description: description.trimmed.isEmpty ? nil : description.trimmed,
                        features: selectedFeatures.isEmpty ? nil : Array(selectedFeatures),
                        images: allImageURLs.isEmpty ? nil : allImageURLs
                    )
                }
                dismiss()
            } catch {
                Logger.admin.error("Parking save failed: \(String(describing: error))")
                errorMessage = friendlyErrorMessage(from: error)
                showError = true
            }
            isProcessing = false
        }
    }

    private func friendlyErrorMessage(from error: Error) -> String {
        if let storageErr = error as? StorageError {
            return storageErr.localizedDescription
        }
        let raw = String(describing: error)
        // PostgREST / Supabase API error details
        if raw.contains("message") || raw.contains("code") || raw.contains("hint") {
            return raw
        }
        return error.localizedDescription
    }
}

// MARK: - Helpers

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension CLPlacemark {
    var formattedAddress: String? {
        let parts = [thoroughfare, subThoroughfare, locality, administrativeArea].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
