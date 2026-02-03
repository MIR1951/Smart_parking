import SwiftUI

struct ParkingDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore

    let parking: Parking
    @State private var showBooking = false
    @State private var selectedTab: DetailTab = .about

    // Computed: real available spots
    private var availableSpots: Int {
        if let avail = availabilityStore.availability(for: parking.id) {
            return avail.availableSpots
        }
        return parking.total_spots - (parking.live_occupancy ?? 0)
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
                .background(.white)  // xohlasang bgLight qil
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
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
                circularButton(system: "square.and.arrow.up") {}
                circularButton(system: "heart") {}
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
                    .foregroundColor(.gray)
                Text("•")
                    .foregroundColor(.gray)
                Text("\(parking.total_spots) total spots")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                Text(parking.address ?? "Unknown")
            }
            .foregroundColor(.gray)
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
                        .foregroundColor(selectedTab == tab ? Color.purple : .gray)

                    if selectedTab == tab {
                        Rectangle()
                            .fill(Color.purple)
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
                    Text(String(format: "$%.2f/hr", parking.price_per_hour))
                }
                .foregroundColor(.purple)
            }
            .font(.subheadline)
            .fontWeight(.medium)

            // Description from DB
            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.headline)
                Text(parking.description ?? "No description available for this parking location.")
                    .foregroundColor(.gray)
            }

            // Features
            VStack(alignment: .leading, spacing: 8) {
                Text("Features")
                    .font(.headline)

                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                    featureItem(icon: "shield.checkered", title: "24/7 Security")
                    featureItem(icon: "video.fill", title: "CCTV")
                    featureItem(icon: "lightbulb.fill", title: "Good Lighting")
                    featureItem(icon: "figure.walk", title: "Covered Parking")
                }
            }

            // Parking Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Parking Info")
                    .font(.headline)

                HStack {
                    infoItem(title: "Total Spots", value: "\(parking.total_spots)")
                    Spacer()
                    infoItem(title: "Available", value: "\(availableSpots)")
                    Spacer()
                    infoItem(
                        title: "Price", value: String(format: "$%.2f/hr", parking.price_per_hour))
                }
            }

        }
    }

    private func featureItem(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func infoItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    // MARK: GALLERY TAB
    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Gallery")
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
                        .foregroundColor(.gray)
                    Text("No gallery images available")
                        .foregroundColor(.gray)
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
                Text("Reviews")
                    .font(.headline)
                Spacer()
                Button("Add Review") {}
                    .foregroundColor(.purple)
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
                    Text("Based on reviews")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
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
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(name.prefix(1)))
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .fontWeight(.medium)
                    Text(date)
                        .font(.caption)
                        .foregroundColor(.gray)
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
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: Bottom Booking Bar
    private var bottomBookingBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Total Price")
                    .foregroundColor(.gray)
                    .font(.caption)
                Text("$\(parking.price_per_hour, specifier: "%.2f") /hr")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            Spacer()

            Button(action: { showBooking = true }) {
                Text(isAvailable ? "Book Slot" : "Fully Booked")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 160, height: 48)
                    .background(isAvailable ? Color.purple : Color.gray)
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
        .background(Color.bgLight)
    }

    // MARK: Button UI
    private func circularButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.headline)
                .foregroundColor(.black)
                .padding(10)
                .background(Color.white)
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
