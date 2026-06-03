 import Combine
import Foundation
 import PostgREST
import Supabase

@MainActor
final class BookingsVM: ObservableObject {
    @Published var items: [BookingItem] = []
    @Published var isLoading = false
    @Published var error: String?

    private var realtimeTask: Task<Void, Never>?
    private var reservationsChannel: RealtimeChannelV2?

    deinit {
        realtimeTask?.cancel()
    }

    func startRealtime() {
        guard realtimeTask == nil else { return }
        let client = SB.shared.client

        realtimeTask = Task { [weak self] in
            guard let self else { return }
            let channel = client.realtimeV2.channel("bookings:user")
            let changes = channel.postgresChange(AnyAction.self, schema: "public", table: "reservations")

            do {
                try await channel.subscribeWithError()
                self.reservationsChannel = channel

                for await _ in changes {
                    guard !Task.isCancelled else { break }
                    await self.load()
                }
            } catch {
                // Realtime failed — REST polling via refreshable continues
            }
        }
    }

    func stopRealtime() {
        realtimeTask?.cancel()
        realtimeTask = nil
        let ch = reservationsChannel
        reservationsChannel = nil
        Task { await ch?.unsubscribe() }
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let userID = try await SB.shared.client.auth.session.user.id.uuidString

            // ✅ Supabase join (reservations -> parkings)
            // FK: reservations.parking_id -> parkings.id
            let rows: [BookingItem] = try await SB.shared.client
                .from("reservations")
                .select(
                    """
                        id,
                        status,
                        start_time,
                        end_time,
                        actual_start_time,
                        actual_end_time,
                        parking:parkings(
                            id,
                            name,
                            city,
                            address,
                            latitude,
                            longitude,
                            thumbnail_url,
                            price_per_hour,
                            rating,
                            total_spots,
                            description,
                            is_popular,
                            images,
                            features
                        )
                    """
                )
                .eq("user_id", value: userID)
                .order("created_at", ascending: false)
                .execute()
                .value

            self.items = rows
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled { return }
            self.error = LocalizationManager.shared.str(.bookingsLoadFailed)

        }
    }

    func filtered(_ tab: BookingTab) -> [BookingItem] {
        let now = Date()

        switch tab {
        case .ongoing:
            return items.filter { item in
                switch item.status {
                case "in_use":
                    return item.actual_end_time == nil
                case "active":
                    // oldinda band qilingan, muddati tugamagan
                    return (item.end_time ?? now) > now
                default:
                    return false
                }
            }

        case .completed:
            return items.filter { item in
                switch item.status {
                case "completed", "expired", "no_show":
                    return true
                case "active":
                    return (item.end_time ?? now) <= now
                default:
                    return false
                }
            }

        case .cancelled:
            return items.filter { $0.status == "cancelled" || $0.status == "canceled" }
        }
    }
}
