import SwiftUI

// MARK: - FavoriteView

struct FavoriteView: View {

    @EnvironmentObject var favorites: FavoritesStore
    @EnvironmentObject var parkings: ParkingsStore
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore

    @State private var selectedToRemove: Parking?

    private var favoriteParkings: [Parking] {
        parkings.all.filter { favorites.isFavorite($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(favoriteParkings) { parking in
                        NavigationLink {
                            ParkingDetailView(parking: parking)
                        } label: {
                            NearbyParkingCard(
                                availabilityStore: _availabilityStore,
                                parking: parking,
                                onHeartTap: {
                                    selectedToRemove = parking
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(Color.bgLight.ignoresSafeArea())
            .navigationTitle("Favorite")
            .navigationBarTitleDisplayMode(.inline)

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
}
struct RemoveFavoriteSheet: View {
    let parking: Parking
    let onCancel: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("Remove from Favorites?")
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
                        Text("Car Parking")
                            .font(.caption)
                            .foregroundColor(.purple)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", parking.rating ?? 5))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Text(parking.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text("$\(parking.price_per_hour, specifier: "%.2f") /hr")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(Color.bgLight)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple.opacity(0.10))
                        .clipShape(Capsule())
                }

                Button(action: onRemove) {
                    Text("Yes, Remove")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.bottom, 14)
        .background(Color.white)
    }
}
