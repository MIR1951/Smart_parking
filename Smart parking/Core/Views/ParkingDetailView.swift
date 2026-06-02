import CoreLocation
import SwiftUI

struct ParkingDetailView: View {
    private let loc = LocalizationManager.shared

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore
    @EnvironmentObject var favorites: FavoritesStore
    @EnvironmentObject var reviewStore: ParkingReviewStore
    @Environment(AppCoordinator.self) private var coordinator

    let parking: Parking

    @State private var showShareSheet = false
    @State private var selectedTab: DetailTab = .about
    @State private var showNavigationApps = false
    @State private var showGalleryViewer = false
    @State private var selectedGalleryIndex = 0
    @State private var showAddReviewSheet = false
    @State private var reviewErrorMessage = ""
    @State private var showReviewError = false
    @State private var reviewWarningMessage = ""
    @State private var showReviewWarning = false
    @Namespace private var tabNamespace

    private var availableSpots: Int {
        if let avail = availabilityStore.availability(for: parking.id) {
            return max(avail.availableSpots, 0)
        }
        return max(parking.total_spots - (parking.live_occupancy ?? 0), 0)
    }

    private var isAvailable: Bool {
        availableSpots > 0
    }

    private var galleryImages: [String] {
        if let images = parking.images, !images.isEmpty {
            return images
        }
        if let thumbnail = parking.thumbnail_url, !thumbnail.isEmpty {
            return [thumbnail]
        }
        return []
    }

    private var reviewSummary: (average: Double, count: Int) {
        reviewStore.summary(for: parking.id, fallbackRating: parking.rating)
    }

    private var mapApps: [ExternalMapNavigator.App] {
        ExternalMapNavigator.availableApps()
    }

    var body: some View {
        VStack(spacing: 0) {
            headerImage
            headerInfo
            tabSelector

            ScrollView(showsIndicators: false) {
                Group {
                    switch selectedTab {
                    case .about:
                        aboutSection
                    case .gallery:
                        gallerySection
                    case .review:
                        reviewSection
                    }
                }
                .id(selectedTab)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .padding(.horizontal)
                .padding(.top, 12)
                .animation(AppTheme.Anim.smooth, value: selectedTab)

                Spacer().frame(height: 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBookingBar
                .background(AppTheme.Palette.surface)
        }
        .background(AppAnimatedBackground())
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [shareText])
        }
        .sheet(isPresented: $showAddReviewSheet) {
            AddParkingReviewSheet(
                parkingName: parking.name,
                isSubmitting: reviewStore.isSubmitting(parkingId: parking.id),
                onSubmit: { rating, comment in
                    await submitReview(rating: rating, comment: comment)
                }
            )
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showGalleryViewer) {
            ParkingGalleryViewer(
                imageURLs: galleryImages,
                startIndex: selectedGalleryIndex
            )
        }
        .confirmationDialog(
            loc.str(.detailNavigateWith),
            isPresented: $showNavigationApps,
            titleVisibility: .visible
        ) {
            ForEach(mapApps, id: \.self) { app in
                Button(app.title) {
                    ExternalMapNavigator.open(
                        app,
                        coordinate: CLLocationCoordinate2D(
                            latitude: parking.latitude,
                            longitude: parking.longitude
                        ),
                        name: parking.name
                    )
                }
            }
            Button(loc.str(.cancel), role: .cancel) {}
        }
        .alert(loc.str(.error), isPresented: $showReviewError) {
            Button(loc.str(.ok)) {}
        } message: {
            Text(reviewErrorMessage)
        }
        .alert(loc.str(.info), isPresented: $showReviewWarning) {
            Button(loc.str(.ok)) {}
        } message: {
            Text(reviewWarningMessage)
        }
        .task {
            await reviewStore.load(parkingId: parking.id)
        }
        .onChange(of: selectedTab) { _, newValue in
            guard newValue == .review else { return }
            Task {
                await reviewStore.load(parkingId: parking.id)
            }
        }
    }

    private var shareText: String {
        "\(parking.name)\n\(parking.address ?? "")\n\(loc.str(.detailPrice)): \(Int(parking.price_per_hour)) \(loc.str(.walletCurrency))\(loc.str(.bookingsPerHour))"
    }

    private func submitReview(rating: Int, comment: String) async {
        do {
            try await reviewStore.submit(parkingId: parking.id, rating: rating, comment: comment)
            showAddReviewSheet = false
        } catch {
            reviewErrorMessage = error.localizedDescription
            showReviewError = true
        }
    }

    private func handleAddReviewTap() {
        Task {
            await reviewStore.load(parkingId: parking.id)
            await MainActor.run {
                presentReviewComposerOrWarning()
            }
        }
    }

    private func presentReviewComposerOrWarning() {
        switch reviewStore.eligibility(for: parking.id) {
        case .eligible:
            showAddReviewSheet = true
        case .needsBooking:
            reviewWarningMessage = loc.str(.reviewNeedBookingWarning)
            showReviewWarning = true
        case .alreadyReviewed:
            reviewWarningMessage = loc.str(.reviewAlreadySubmittedWarning)
            showReviewWarning = true
        }
    }
}

// MARK: - UI

extension ParkingDetailView {
    private var headerImage: some View {
        ZStack(alignment: .topLeading) {
            CachedAsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.2))
            }
            .frame(height: 260)
            .clipShape(
                UnevenRoundedRectangle(
                    bottomLeadingRadius: AppTheme.Radius.large,
                    bottomTrailingRadius: AppTheme.Radius.large
                )
            )

            HStack {
                circularButton(system: "chevron.left") {
                    dismiss()
                }
                Spacer()
                circularButton(system: "square.and.arrow.up") {
                    showShareSheet = true
                }
                circularButton(system: favorites.isFavorite(parking.id) ? "heart.fill" : "heart") {
                    favorites.toggle(parking.id)
                }
            }
            .padding(.horizontal)
            .padding(.top, 50)
        }
    }

    private var headerInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(parking.name)
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(AppTheme.Palette.warning)
                    .font(.caption)
                Text(String(format: "%.1f", reviewSummary.average > 0 ? reviewSummary.average : (parking.rating ?? 4.5)))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                Text("•")
                    .foregroundColor(AppTheme.Palette.textSecondary)
                Text("\(parking.total_spots) \(loc.str(.detailTotalSpots))")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                if !parking.city.isEmpty {
                    Text("•")
                        .foregroundColor(AppTheme.Palette.textSecondary)
                    Text(parking.city)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                Text(parking.address ?? loc.str(.unknown))
            }
            .foregroundColor(AppTheme.Palette.textSecondary)
            .font(.subheadline)
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private var tabSelector: some View {
        HStack {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                VStack(spacing: 6) {
                    Text(tab.title)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(
                            selectedTab == tab
                                ? AppTheme.Palette.brand : AppTheme.Palette.textTertiary
                        )

                    if selectedTab == tab {
                        Capsule()
                            .fill(AppTheme.Gradient.brand)
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "tabUnderline", in: tabNamespace)
                    } else {
                        Capsule()
                            .fill(Color.clear)
                            .frame(height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    withAnimation(AppTheme.Anim.smooth) { selectedTab = tab }
                    AppTheme.Haptic.light()
                }
            }
        }
        .padding(.top, 16)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "car.fill")
                        .foregroundColor(
                            isAvailable ? AppTheme.Palette.success : AppTheme.Palette.danger
                        )
                    Text("\(availableSpots) \(loc.str(.detailSpotsAvailable))")
                        .foregroundColor(
                            isAvailable ? AppTheme.Palette.success : AppTheme.Palette.danger
                        )
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle")
                    Text("\(Int(parking.price_per_hour)) \(loc.str(.walletCurrency))" + loc.str(.bookingsPerHour))
                }
                .foregroundColor(AppTheme.Palette.brand)
            }
            .font(.subheadline)
            .fontWeight(.medium)

            Button {
                showNavigationApps = true
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond")
                    Text(loc.str(.detailNavigate))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Palette.brand)
                .padding(12)
                .background(AppTheme.Palette.brand.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(loc.str(.detailDescription))
                    .font(.headline)
                Text(parking.description ?? loc.str(.detailNoDescription))
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }

            if let features = parking.features, !features.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc.str(.detailFeatures))
                        .font(.headline)

                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                        ForEach(features, id: \.self) { feature in
                            featureItem(icon: iconForFeature(feature), title: feature)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(loc.str(.detailParkingInfo))
                    .font(.headline)

                HStack {
                    infoItem(title: loc.str(.detailTotalSpots), value: "\(parking.total_spots)")
                    Spacer()
                    infoItem(title: loc.str(.detailAvailable), value: "\(availableSpots)")
                    Spacer()
                    infoItem(
                        title: loc.str(.detailPrice),
                        value: "\(Int(parking.price_per_hour)) \(loc.str(.walletCurrency))" + loc.str(.bookingsPerHour)
                    )
                }
            }

            additionalInfoSection
        }
    }

    @ViewBuilder
    private var additionalInfoSection: some View {
        let hasAny = parking.working_hours != nil || parking.phone != nil
            || parking.covered != nil || parking.max_height_cm != nil
        if hasAny {
            VStack(alignment: .leading, spacing: 8) {
                Text(loc.str(.detailAdditionalInfo))
                    .font(.headline)

                VStack(spacing: 6) {
                    if let hours = parking.working_hours {
                        additionalInfoRow(
                            icon: "clock.fill",
                            label: loc.str(.detailWorkingHours),
                            value: hours
                        )
                    }
                    if let phone = parking.phone, !phone.isEmpty {
                        if let url = URL(string: "tel:\(phone.filter { !$0.isWhitespace })") {
                            Link(destination: url) {
                                additionalInfoRow(
                                    icon: "phone.fill",
                                    label: loc.str(.detailPhone),
                                    value: phone,
                                    isLink: true
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if let covered = parking.covered {
                        additionalInfoRow(
                            icon: covered ? "umbrella.fill" : "sun.max.fill",
                            label: loc.str(.detailCovered),
                            value: covered ? loc.str(.yesLabel) : loc.str(.noLabel)
                        )
                    }
                    if let maxH = parking.max_height_cm {
                        additionalInfoRow(
                            icon: "arrow.up.to.line",
                            label: loc.str(.detailMaxHeight),
                            value: "\(maxH) sm"
                        )
                    }
                }
            }
        }
    }

    private func additionalInfoRow(
        icon: String, label: String, value: String, isLink: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.Palette.brand)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppTheme.Palette.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isLink ? AppTheme.Palette.brand : AppTheme.Palette.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.Palette.brandSoft)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
    }

    private func featureItem(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.Palette.brand)
                .frame(width: 24)
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.Palette.textSecondary)
            Spacer()
        }
        .padding(10)
        .background(AppTheme.Palette.brandSoft)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
    }

    private func iconForFeature(_ feature: String) -> String {
        let lower = feature.lowercased()
        if lower.contains("security") || lower.contains("xavfsizlik") { return "shield.checkered" }
        if lower.contains("cctv") || lower.contains("kamera") { return "video.fill" }
        if lower.contains("light") || lower.contains("yoritish") { return "lightbulb.fill" }
        if lower.contains("covered") || lower.contains("yopiq") { return "umbrella.fill" }
        if lower.contains("ev") || lower.contains("charging") || lower.contains("zaryadlash") {
            return "bolt.car.fill"
        }
        if lower.contains("disabled") || lower.contains("nogiron") { return "figure.roll" }
        if lower.contains("24") || lower.contains("hour") { return "clock.fill" }
        if lower.contains("wash") || lower.contains("yuvish") { return "drop.fill" }
        if lower.contains("valet") { return "person.fill" }
        if lower.contains("elevator") || lower.contains("lift") { return "arrow.up.arrow.down" }
        return "checkmark.circle.fill"
    }

    private func infoItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.Palette.textSecondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(loc.str(.detailGallery))
                    .font(.headline)
                Spacer()
            }

            if galleryImages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                    Text(loc.str(.detailNoGallery))
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                    ForEach(Array(galleryImages.enumerated()), id: \.offset) { index, imageURL in
                        Button {
                            selectedGalleryIndex = index
                            showGalleryViewer = true
                        } label: {
                            CachedAsyncImage(url: URL(string: imageURL)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Rectangle().fill(Color.gray.opacity(0.2))
                            }
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var reviewSection: some View {
        let reviews = reviewStore.reviews(for: parking.id)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(loc.str(.detailReviews))
                    .font(.headline)
                Spacer()
                Button(loc.str(.detailAddReview)) {
                    handleAddReviewTap()
                }
                .foregroundColor(AppTheme.Palette.brand)
                .font(.subheadline)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(format: "%.1f", reviewSummary.average))
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(reviewSummary.average.rounded(.down)) ? "star.fill" : "star")
                                .foregroundColor(AppTheme.Palette.warning)
                                .font(.caption)
                        }
                    }

                    Text(reviewSummary.count > 0 ? "\(reviewSummary.count) \(loc.str(.detailBasedOnReviews))" : loc.str(.detailNoReviewsYet))
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Palette.brandSoft)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            }

            if reviewStore.isLoading(parkingId: parking.id) {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if reviews.isEmpty {
                Text(loc.str(.detailNoReviewsYet))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 14) {
                    ForEach(reviews) { review in
                        reviewItem(review)
                    }
                }
            }
        }
    }

    private func reviewItem(_ review: ParkingReview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(AppTheme.Palette.brandSoft)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String((review.author?.displayName ?? "U").prefix(1)))
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.Palette.brand)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.author?.displayName ?? "User")
                        .fontWeight(.medium)
                    Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }

                Spacer()

                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < review.rating ? "star.fill" : "star")
                            .foregroundColor(AppTheme.Palette.warning)
                            .font(.caption)
                    }
                }
            }

            Text(review.comment)
                .font(.subheadline)
                .foregroundColor(AppTheme.Palette.textSecondary)
        }
        .padding()
        .background(AppTheme.Palette.pageBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
    }

    private var bottomBookingBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(loc.str(.detailTotalPrice))
                    .foregroundColor(AppTheme.Palette.textSecondary)
                    .font(.caption)
                Text("\(Int(parking.price_per_hour)) \(loc.str(.walletCurrency))\(loc.str(.bookingsPerHour))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Palette.textPrimary)
            }
            Spacer()

            Button(action: { coordinator.startBookingFlow(parking) }) {
                Text(isAvailable ? loc.str(.detailBookSlot) : loc.str(.detailFullyBooked))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 160, height: 48)
                    .background {
                        if isAvailable {
                            AppTheme.Gradient.brand
                        } else {
                            Color.gray
                        }
                    }
                    .clipShape(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                    )
            }
            .disabled(!isAvailable)
            .pressStyle()
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(AppTheme.Palette.surface.opacity(0.7))
                )
        )
    }

    private func circularButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.headline)
                .foregroundColor(AppTheme.Palette.textPrimary)
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
        .pressStyle()
    }
}
