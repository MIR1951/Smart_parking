import SwiftUI

// MARK: - FavoriteView

struct FavoriteView: View {
    private let loc = LocalizationManager.shared

    @EnvironmentObject var favorites: FavoritesStore
    @EnvironmentObject var parkings: ParkingsStore
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore
    @Environment(AppCoordinator.self) private var coordinator

    @State private var selectedToRemove: Parking?

    private var favoriteParkings: [Parking] {
        parkings.all.filter { favorites.isFavorite($0.id) }
    }

    var body: some View {
        ZStack {
            AppAnimatedBackground()

            if favoriteParkings.isEmpty {
                AppStateView(
                    kind: .empty(
                        icon: "heart.slash",
                        title: loc.str(.favoriteNoFavorites),
                        subtitle: loc.str(.favoriteNoFavoritesSub)
                    )
                )
                .appReveal(0.05)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(Array(favoriteParkings.enumerated()), id: \.element.id) {
                            index, parking in
                            Button {
                                coordinator.showParkingDetail(parking)
                            } label: {
                                NearbyParkingCard(
                                    availabilityStore: _availabilityStore,
                                    parking: parking,
                                    isFavorite: true,
                                    onHeartTap: {
                                        selectedToRemove = parking
                                    }
                                )
                                .appReveal(Double(index) * 0.03)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle(loc.str(.favoriteTitle))
        .navigationBarTitleDisplayMode(.large)

        // Realtime + initial load (agar root’da start qilingan bo‘lsa ham zarar qilmaydi)
        .task {
            availabilityStore.initialLoad()
            availabilityStore.startRealtime()
        }

        .sheet(item: $selectedToRemove) { p in
            RemoveFavoriteSheet(
                parking: p,
                onCancel: { selectedToRemove = nil },
                onRemove: {
                    favorites.remove(p.id)
                    selectedToRemove = nil
                }
            )
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
        }
    }
}
struct RemoveFavoriteSheet: View {
    let parking: Parking
    let onCancel: () -> Void
    let onRemove: () -> Void

    private let loc = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 14) {
            Text(loc.str(.favoriteRemoveTitle))
                .font(.headline)
                .padding(.top, 6)

            HStack(spacing: 12) {
                AsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: Rectangle().fill(Color.gray.opacity(0.2))
                    }
                }
                .frame(width: 70, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(loc.str(.detailCarParking))
                            .font(.caption)
                            .foregroundColor(AppTheme.Palette.brand)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", parking.rating ?? 5))
                                .font(.caption)
                                .foregroundColor(AppTheme.Palette.textSecondary)
                        }
                    }

                    Text(parking.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(
                        "\(Int(parking.price_per_hour)) so'm \(loc.str(.bookingsPerHour))"
                    )
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Palette.brand)
                }
            }
            .padding()
            .background(AppTheme.Palette.pageBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text(loc.str(.favoriteCancel))
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Palette.brand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.Palette.brandSoft)
                        .clipShape(Capsule())
                }
                .pressStyle()

                Button(action: onRemove) {
                    Text(loc.str(.favoriteYesRemove))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.Palette.brand)
                        .clipShape(Capsule())
                }
                .pressStyle()
            }
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.bottom, 14)
        .background(AppTheme.Palette.surface)
    }
}
