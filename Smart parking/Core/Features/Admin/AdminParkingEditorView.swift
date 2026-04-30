import MapKit
import os
import PhotosUI
import SwiftUI

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
    @State private var pinCoordinate: CLLocationCoordinate2D?

    // Images
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var existingImageURLs: [String] = []

    // State
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

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
            EditorMapSection(
                pinCoordinate: $pinCoordinate,
                availableCities: store.availableCities,
                onAddressResolved: { addr in if address.isEmpty { address = addr } },
                onCityResolved: { c in if city.isEmpty { city = c } }
            )
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
            EditorFeaturesSection(selectedFeatures: $selectedFeatures)
        }
    }

    // MARK: - Images

    private var imagesSection: some View {
        formSection(title: loc.str(.adminImages), icon: "photo.on.rectangle") {
            EditorImageSection(
                existingImageURLs: $existingImageURLs,
                selectedImages: $selectedImages,
                selectedPhotoItems: $selectedPhotoItems
            )
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

    // MARK: - Image Upload

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
        pinCoordinate = CLLocationCoordinate2D(latitude: parking.latitude, longitude: parking.longitude)
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

                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedAddr = address.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)

                if let parking {
                    try await store.updateParking(
                        id: parking.id,
                        name: trimmedName,
                        city: trimmedCity.isEmpty ? nil : trimmedCity,
                        address: trimmedAddr.isEmpty ? nil : trimmedAddr,
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        pricePerHour: Double(pricePerHour),
                        totalSpots: Int(totalSpots),
                        description: trimmedDesc.isEmpty ? nil : trimmedDesc,
                        features: selectedFeatures.isEmpty ? nil : Array(selectedFeatures),
                        images: allImageURLs.isEmpty ? nil : allImageURLs
                    )
                } else {
                    try await store.createParking(
                        name: trimmedName,
                        city: trimmedCity,
                        address: trimmedAddr.isEmpty ? nil : trimmedAddr,
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        pricePerHour: Double(pricePerHour) ?? 0,
                        totalSpots: Int(totalSpots) ?? 0,
                        description: trimmedDesc.isEmpty ? nil : trimmedDesc,
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
        if raw.contains("message") || raw.contains("code") || raw.contains("hint") {
            return raw
        }
        return error.localizedDescription
    }
}
