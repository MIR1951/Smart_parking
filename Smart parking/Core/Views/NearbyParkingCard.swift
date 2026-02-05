import SwiftUI

struct NearbyParkingCard: View {

    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore
    let parking: Parking
    var isFavorite: Bool = false
    let onHeartTap: (() -> Void)?

    private var availableSpots: Int {
        availabilityStore.availability(for: parking.id)?.availableSpots
        ?? availabilityStore.available[parking.id]
        ?? max(parking.total_spots - (parking.live_occupancy ?? 0), 0)
    }

    var body: some View {
        HStack(spacing: 15) {

            // ✅ Image + heart overlay (rasm ustida)
            ZStack(alignment: .topTrailing) {
                CachedAsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 90, height: 90)
                .cornerRadius(15)
                .clipped()

                if let onHeartTap {
                    Button(action: onHeartTap) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : AppTheme.Palette.textPrimary)
                            .padding(8)
                            .background(AppTheme.Palette.surface)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(6) // ✅ image ichida joylashadi
                }
            }

            VStack(alignment: .leading, spacing: 4) {

                HStack {
                    Text("Car Parking")
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.brand)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.Palette.brandSoft)
                        .clipShape(Capsule())

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
                    .font(.headline)
                    .foregroundColor(AppTheme.Palette.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                    Text(parking.address ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Text("$\(parking.price_per_hour, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(AppTheme.Palette.brand)
                    Text("/hr")
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }

                HStack {
                    Label("04 Mins", systemImage: "clock")
                        .foregroundColor(AppTheme.Palette.brand)

                    Spacer()

                    Label("\(availableSpots) Spots", systemImage: "car.fill")
                        .foregroundColor(AppTheme.Palette.brand)
                }
                .font(.caption)
            }

            Spacer()
        }
        .padding(14)
        .appCard()
    }
}
