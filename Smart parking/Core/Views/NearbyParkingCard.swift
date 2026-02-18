import SwiftUI

struct NearbyParkingCard: View {

    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore
    let parking: Parking
    var isFavorite: Bool = false
    let onHeartTap: (() -> Void)?
    @State private var didAppear = false

    private var availableSpots: Int {
        availabilityStore.availability(for: parking.id)?.availableSpots
            ?? availabilityStore.available[parking.id]
            ?? max(parking.total_spots - (parking.live_occupancy ?? 0), 0)
    }

    private var isAvailable: Bool { availableSpots > 0 }

    var body: some View {
        HStack(spacing: 15) {

            // Image + heart overlay
            ZStack(alignment: .topTrailing) {
                CachedAsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(AppTheme.Palette.surfaceSecondary)
                        .overlay(
                            Image(systemName: "car.fill")
                                .foregroundColor(AppTheme.Palette.textTertiary)
                        )
                }
                .frame(width: 90, height: 90)
                .overlay(AppTheme.Gradient.cardOverlay)
                .cornerRadius(AppTheme.Radius.medium)
                .clipped()

                if let onHeartTap {
                    Button(action: onHeartTap) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundColor(isFavorite ? .red : AppTheme.Palette.textPrimary)
                            .padding(6)
                            .background(AppTheme.Palette.surface)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(4)
                }
            }

            VStack(alignment: .leading, spacing: 5) {

                HStack {
                    Text(LocalizationManager.shared.str(.detailCarParking))
                        .font(AppTheme.Typography.captionBold)
                        .foregroundColor(AppTheme.Palette.brand)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.Palette.brandSoft)
                        .clipShape(Capsule())

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", parking.rating ?? 5))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Palette.textSecondary)
                    }
                }

                Text(parking.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Palette.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundColor(AppTheme.Palette.textTertiary)
                    Text(parking.address ?? "Unknown")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                        .lineLimit(1)
                }

                HStack {
                    // Price
                    HStack(spacing: 2) {
                        Text("$\(parking.price_per_hour, specifier: "%.2f")")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Palette.brand)
                        Text(LocalizationManager.shared.str(.bookingsPerHour))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Palette.textSecondary)
                    }

                    Spacer()

                    // Availability
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isAvailable ? AppTheme.Palette.success : AppTheme.Palette.danger)
                            .frame(width: 6, height: 6)
                        Text("\(availableSpots) Spots")
                            .font(AppTheme.Typography.captionBold)
                            .foregroundColor(
                                isAvailable ? AppTheme.Palette.success : AppTheme.Palette.danger)
                    }
                }
            }

            Spacer()
        }
        .padding(14)
        .appCard()
        .scaleEffect(didAppear ? 1 : 0.97)
        .opacity(didAppear ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.86), value: didAppear)
        .onAppear {
            didAppear = true
        }
    }
}
