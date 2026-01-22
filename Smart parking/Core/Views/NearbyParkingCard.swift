import SwiftUI

struct NearbyParkingCard: View {

    let parking: Parking

    var availableSpots: Int {
        max(parking.total_spots - (parking.live_occupancy ?? 0), 0)
    }

    var body: some View {
        HStack(spacing: 15) {

            // ✅ Safe AsyncImage (timeout bo‘lsa ham UI buzilmaydi)
            AsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))

                case .success(let img):
                    img
                        .resizable()
                        .scaledToFill()

                case .failure:
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))

                        Image(systemName: "photo")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.gray.opacity(0.8))
                    }

                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .frame(width: 90, height: 90)
            .cornerRadius(15)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {

                Text("Car Parking")
                    .foregroundColor(.primary)
                    .font(.caption)

                Text(parking.name)
                    .font(.headline)

                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(parking.address ?? "")
                }
                .foregroundColor(.gray)
                .font(.caption)

                HStack {
                    Text("$\(parking.price_per_hour, specifier: "%.2f")")
                        .foregroundColor(.primary)
                    Text("/hr")
                        .foregroundColor(.gray)
                }

                HStack {
                    Label("5 mins", systemImage: "clock")
                    Spacer()
                    Label("\(availableSpots) Spots", systemImage: "car.fill")
                }
                .foregroundColor(.gray)
                .font(.caption)
            }

            Spacer()

            Image(systemName: "heart")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 2)
    }
}
