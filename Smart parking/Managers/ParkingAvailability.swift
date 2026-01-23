////
////  ParkingAvailabilityStore.swift
////  Smart parking
////
////  Created by Kenjaboy Xajiyev on 23/01/26.
////
//
//import Foundation
//import Combine
//import Supabase
//import Realtime
//
//// Tez o‘zgaradigan model (realtime record decode uchun Codable qilamiz)
//struct ParkingAvailability: Codable, Sendable {
//    let parking_id: UUID
//    let live_occupancy: Int
//    let reserved_spots: Int
//    let available_spots: Int
//    let updated_at: Date
//}
//
//@MainActor
//final class ParkingAvailabilityStore: ObservableObject {
//
//    // parking_id -> available_spots
//    @Published var available: [UUID: Int] = [:]
//
//    private let client: SupabaseClient
//    private var channel: RealtimeChannelV2?
//
//    // MARK: - Init
//
//    init(client: SupabaseClient) {
//        self.client = client
//    }
//
//    deinit {
//        Task { [weak channel] in
//            await channel?.unsubscribe()
//        }
//    }
//
//    // MARK: - Realtime
//
//    func start() {
//        // Prevent multiple subscriptions
//        guard channel == nil else { return }
//
//        let channelName = "availability-updates"
//        let tableName = "parking_availability"
//
//        let ch = client.channel(channelName)
//        self.channel = ch
//
//        // INSERT (yangi row qo‘shilsa)
//        ch.onPresenceChange(
//            PostgresChangeEvent.insert,
//            schema: "public",
//            table: tableName
//        ) { [weak self] payload in
//            guard let self else { return }
//            self.handleUpsert(payload.record)
//        }
//
//        // UPDATE (row yangilansa)
//        channel.onPostgresChanges(
//            event: .update,
//            schema: "public",
//            table: "parking_availability"
//        ) { [weak self] payload in
//            guard let self else { return }
//            self.handleUpsert(payload.record)
//        }
//
//        // DELETE (row o‘chsa)
//        ch.on(
//            PostgresChangeEvent.delete,
//            schema: "public",
//            table: tableName
//        ) { [weak self] payload in
//            guard let self else { return }
//            self.handleDelete(payload.oldRecord)
//        }
//
//        Task {
//            await ch.subscribe()
//            print("✅ Realtime subscribed: \(channelName) / \(tableName)")
//        }
//    }
//
//    func stop() {
//        guard let ch = channel else { return }
//        channel = nil
//        Task {
//            await ch.unsubscribe()
//            print("🛑 Realtime unsubscribed")
//        }
//    }
//
//    // MARK: - Handlers
//
//    private func handleUpsert(_ record: [String: Any]?) {
//        guard let model: ParkingAvailability = decodeRecord(record) else {
//            print("❌ decode failed. record:", record ?? [:])
//            return
//        }
//
//        // Bizga keraklisi: parking_id -> available_spots
//        available[model.parking_id] = model.available_spots
//
//        // xohlasang debug:
//        // print("✅ upsert:", model.parking_id, "available:", model.available_spots)
//    }
//
//    private func handleDelete(_ oldRecord: [String: Any]?) {
//        guard let model: ParkingAvailability = decodeRecord(oldRecord) else {
//            print("❌ delete decode failed. oldRecord:", oldRecord ?? [:])
//            return
//        }
//
//        available.removeValue(forKey: model.parking_id)
//        // print("✅ deleted:", model.parking_id)
//    }
//
//    // MARK: - Decode helper
//
//    private func decodeRecord<T: Decodable>(_ record: [String: Any]?) -> T? {
//        guard let record else { return nil }
//        do {
//            let data = try JSONSerialization.data(withJSONObject: record)
//            return try JSONDecoder.supabase.decode(T.self, from: data)
//        } catch {
//            print("❌ decodeRecord error:", error)
//            return nil
//        }
//    }
//}
//
//// Supabase default decoder (sana formatlari uchun)
//extension JSONDecoder {
//    static var supabase: JSONDecoder {
//        let d = JSONDecoder()
//        d.dateDecodingStrategy = .iso8601
//        return d
//    }
//}
