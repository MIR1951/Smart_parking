internal import Combine
import Foundation
internal import PostgREST
import Supabase

@MainActor
final class BookingsVM: ObservableObject {
    @Published var items: [BookingItem] = []
    @Published var isLoading = false
    @Published var error: String?

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
                            address,
                            thumbnail_url,
                            price_per_hour,
                            rating
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
            print("❌ bookings load error:", error)
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
                    // active bo'lib turib end_time o'tib ketgan bo'lsa
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
