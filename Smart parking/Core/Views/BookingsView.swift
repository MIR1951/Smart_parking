import SwiftUI
import Supabase

// MARK: - Models (UI uchun)
struct BookingParking: Codable, Identifiable {
    let id: UUID
    let name: String
    let address: String?
    let thumbnail_url: String?
    let price_per_hour: Double
    let rating: Double?
}

struct BookingItem: Codable, Identifiable {
    let id: UUID
    let status: String

    let start_time: Date?
    let end_time: Date?
    let actual_start_time: Date?
    let actual_end_time: Date?

    let parking: BookingParking
}


enum BookingTab: String, CaseIterable {
    case ongoing = "Ongoing"
    case completed = "Completed"
    case cancelled = "Cancelled"
}




// MARK: - Main View
struct BookingsView: View {

    @StateObject private var vm = BookingsVM()
    @State private var tab: BookingTab = .ongoing

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Top segmented (Ongoing/Completed/Cancelled)
                bookingTabs

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if vm.isLoading && vm.items.isEmpty {
                            ProgressView()
                                .padding(.top, 40)
                        } else if let error = vm.error {
                            VStack(spacing: 12) {
                                Text(error).foregroundColor(.red)
                                Button("Retry") { Task { await vm.load() } }
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(vm.filtered(tab)) { item in
                                BookingCard(
                                    item: item,
                                    leftButtonTitle: leftButtonTitle(for: item),
                                    onLeftTap: { handleLeft(item) },
                                    onTicketTap: { openTicket(item) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.bgLight.ignoresSafeArea())
            .navigationTitle("My Booking")
            .navigationBarTitleDisplayMode(.inline)
            .task { await vm.load() }
            .refreshable { await vm.load() }
        }
    }

    // MARK: - UI Components

    private var bookingTabs: some View {
        HStack(spacing: 0) {
            ForEach(BookingTab.allCases, id: \.self) { t in
                VStack(spacing: 8) {
                    Text(t.rawValue)
                        .font(.headline)
                        .foregroundColor(tab == t ? Color.purple : .gray)

                    Capsule()
                        .fill(tab == t ? Color.purple : Color.clear)
                        .frame(height: 3)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut) { tab = t }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color.white)
    }

    // MARK: - Actions
    private func leftButtonTitle(for item: BookingItem) -> String {
        // Dizayndagi kabi:
        //  - Ongoing’da ba’zan "Timer", ba’zan "Cancel" ko‘rsatilgan
        // Siz statusga qarab tanlaysiz:
        if item.status == "in_use" { return "Timer" }
        if item.status == "active" { return "Cancel" }
        return "Action"
    }

    private func handleLeft(_ item: BookingItem) {
        // TODO:
        // - "Timer" -> timer screen
        // - "Cancel" -> reservation cancel RPC / update
        print("Left tapped:", item.id)
    }

    private func openTicket(_ item: BookingItem) {
        // TODO: E-ticket view / QR
        print("E-Ticket:", item.id)
    }
}

// MARK: - Booking Card (Dizayn)
struct BookingCard: View {
    let item: BookingItem
    let leftButtonTitle: String
    let onLeftTap: () -> Void
    let onTicketTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {

            HStack(alignment: .top, spacing: 12) {

                AsyncImage(url: URL(string: item.parking.thumbnail_url ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Rectangle().fill(Color.gray.opacity(0.2))
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Rectangle().fill(Color.gray.opacity(0.2))
                            Image(systemName: "photo").foregroundColor(.gray)
                        }
                    }
                }
                .frame(width: 110, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 6) {

                    HStack {
                        Text("Car Parking")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.10))
                            .clipShape(Capsule())

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", item.parking.rating ?? 4.5))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Text(item.parking.name)
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(item.parking.address ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }

                    HStack(spacing: 4) {
                        Text("$\(item.parking.price_per_hour, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.purple)
                        Text("/hr")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            HStack(spacing: 12) {
                Button(action: onLeftTap) {
                    Text(leftButtonTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple.opacity(0.10))
                        .clipShape(Capsule())
                }

                Button(action: onTicketTap) {
                    Text("E-Ticket")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}
