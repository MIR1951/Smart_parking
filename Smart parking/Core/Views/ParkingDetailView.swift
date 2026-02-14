import SwiftUI

struct ParkingDetailView: View {
    private let loc = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore
    @EnvironmentObject var favorites: FavoritesStore

    let parking: Parking
    @State private var showBooking = false
    @State private var showShareSheet = false
    @State private var selectedTab: DetailTab = .about

    // Computed: real available spots
    private var availableSpots: Int {
        if let avail = availabilityStore.availability(for: parking.id) {
            return max(avail.availableSpots, 0)
        }
        return max(parking.total_spots - (parking.live_occupancy ?? 0), 0)
    }

    private var isAvailable: Bool {
        availableSpots > 0
    }

    var body: some View {

        VStack {
            ScrollView(showsIndicators: false) {

                VStack(alignment: .leading, spacing: 0) {

                    // MARK: — Header Image
                    headerImage

                    // MARK: — Summary (Name, Rating, Address)
                    headerInfo

                    // MARK: — Tabs (About, Gallery, Review)
                    tabSelector

                    // MARK: — Tab Content
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
                    .padding(.horizontal)
                    .padding(.top, 12)

                    Spacer().frame(height: 24)  // Book button markazga urilishmasligi uchun
                }
            }

        }
        .safeAreaInset(edge: .bottom) {  // ✅ book bar pastda
            bottomBookingBar
                .background(AppTheme.Palette.surface)
        }
        .background(AppTheme.Palette.pageBackground.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [shareText])
        }
    }

    private var shareText: String {
        "\(parking.name)\n\(parking.address ?? "")\n\(loc.str(.detailPrice)): $\(String(format: "%.2f", parking.price_per_hour))\(loc.str(.bookingsPerHour))"
    }
}

// MARK: — UI COMPONENTS

extension ParkingDetailView {

    // MARK: Header Image
    private var headerImage: some View {
        ZStack(alignment: .topLeading) {
            CachedAsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.2))
            }

            .frame(height: 260)
            .clipped()

            HStack {
                circularButton(system: "chevron.left") {
                    dismiss()
                }
                Spacer()
                circularButton(system: "square.and.arrow.up") {
                    showShareSheet = true
                }
                circularButton(
                    system: favorites.isFavorite(parking.id) ? "heart.fill" : "heart"
                ) {
                    favorites.toggle(parking.id)
                }
            }
            .padding(.horizontal)
            .padding(.top, 50)
        }

    }

    // MARK: Header Info
    private var headerInfo: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(parking.name)
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                Text(String(format: "%.1f", parking.rating ?? 4.5))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                Text("•")
                    .foregroundColor(AppTheme.Palette.textSecondary)
                Text("\(parking.total_spots) total spots")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                Text(parking.address ?? "Unknown")
            }
            .foregroundColor(AppTheme.Palette.textSecondary)
            .font(.subheadline)

        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: Tabs
    private var tabSelector: some View {
        HStack {
            ForEach(DetailTab.allCases, id: \.rawValue) { tab in
                VStack {
                    Text(tab.rawValue)
                        .font(.headline)
                        .foregroundColor(
                            selectedTab == tab
                                ? AppTheme.Palette.brand : AppTheme.Palette.textSecondary)

                    if selectedTab == tab {
                        Rectangle()
                            .fill(AppTheme.Palette.brand)
                            .frame(height: 3)

                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 3)
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut) { selectedTab = tab }
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: ABOUT TAB
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Real-time availability
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "car.fill")
                        .foregroundColor(isAvailable ? .green : .red)
                    Text("\(availableSpots) Spots Available")
                        .foregroundColor(isAvailable ? .green : .red)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle")
                    Text(
                        String(format: "$%.2f", parking.price_per_hour) + loc.str(.bookingsPerHour))
                }
                .foregroundColor(AppTheme.Palette.brand)
            }
            .font(.subheadline)
            .fontWeight(.medium)

            // Description from DB
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.str(.detailDescription))
                    .font(.headline)
                Text(parking.description ?? loc.str(.detailNoDescription))
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }

            // Features
            VStack(alignment: .leading, spacing: 8) {
                Text(loc.str(.detailFeatures))
                    .font(.headline)

                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                    featureItem(icon: "shield.checkered", title: loc.str(.detailSecurity))
                    featureItem(icon: "video.fill", title: loc.str(.detailCCTV))
                    featureItem(icon: "lightbulb.fill", title: loc.str(.detailLighting))
                    featureItem(icon: "figure.walk", title: loc.str(.detailCovered))
                }
            }

            // Parking Info
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
                        value: String(format: "$%.2f", parking.price_per_hour)
                            + loc.str(.bookingsPerHour))
                }
            }

        }
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
        .cornerRadius(10)
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

    // MARK: GALLERY TAB
    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(loc.str(.detailGallery))
                    .font(.headline)
                Spacer()
            }

            if let images = parking.images, !images.isEmpty {
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                    ForEach(images, id: \.self) { imageUrl in
                        CachedAsyncImage(url: URL(string: imageUrl)) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.2))
                        }
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                // Placeholder if no images
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                    Text(loc.str(.detailNoGallery))
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }

    // MARK: REVIEW TAB
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text(loc.str(.detailReviews))
                    .font(.headline)
                Spacer()
                Button(loc.str(.detailAddReview)) {}
                    .foregroundColor(AppTheme.Palette.brand)
                    .font(.subheadline)
            }

            // Rating Summary
            HStack(spacing: 16) {
                VStack {
                    Text(String(format: "%.1f", parking.rating ?? 4.5))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < Int(parking.rating ?? 4.5) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    Text(loc.str(.detailBasedOnReviews))
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }
                .padding()
                .background(AppTheme.Palette.brandSoft)
                .cornerRadius(12)

                Spacer()
            }

            // Example reviews (placeholder)
            VStack(spacing: 16) {
                reviewItem(
                    name: "John Doe",
                    date: "2 days ago",
                    rating: 5,
                    comment: "Great parking space! Very clean and safe. Will definitely use again."
                )

                reviewItem(
                    name: "Jane Smith",
                    date: "1 week ago",
                    rating: 4,
                    comment: "Good location, easy to find. A bit crowded on weekends."
                )
            }
        }
    }

    private func reviewItem(name: String, date: String, rating: Int, comment: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(AppTheme.Palette.brandSoft)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(name.prefix(1)))
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.Palette.brand)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .fontWeight(.medium)
                    Text(date)
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }

                Spacer()

                HStack(spacing: 2) {
                    ForEach(0..<rating, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
            }

            Text(comment)
                .font(.subheadline)
                .foregroundColor(AppTheme.Palette.textSecondary)
        }
        .padding()
        .background(AppTheme.Palette.pageBackground)
        .cornerRadius(12)
    }

    // MARK: Bottom Booking Bar
    private var bottomBookingBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(loc.str(.detailTotalPrice))
                    .foregroundColor(AppTheme.Palette.textSecondary)
                    .font(.caption)
                Text("$\(parking.price_per_hour, specifier: "%.2f") \(loc.str(.bookingsPerHour))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Palette.textPrimary)
            }
            Spacer()

            Button(action: { showBooking = true }) {
                Text(isAvailable ? loc.str(.detailBookSlot) : loc.str(.detailFullyBooked))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 160, height: 48)
                    .background(isAvailable ? AppTheme.Palette.brand : Color.gray)
                    .cornerRadius(14)
            }
            .disabled(!isAvailable)
            .fullScreenCover(isPresented: $showBooking) {
                BookingFlowView(parking: parking)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(AppTheme.Palette.surface)
    }

    // MARK: Button UI
    private func circularButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.headline)
                .foregroundColor(AppTheme.Palette.textPrimary)
                .padding(10)
                .background(AppTheme.Palette.surface)
                .clipShape(Circle())
                .shadow(radius: 3)
        }
    }
}

// MARK: — TABS ENUM

enum DetailTab: String, CaseIterable {
    case about = "About"
    case gallery = "Gallery"
    case review = "Review"
}

// MARK: - Parking Extension for images
extension Parking {
    var images: [String]? {
        // Bu property DB dan kelishi kerak, hozircha nil
        nil
    }
}
