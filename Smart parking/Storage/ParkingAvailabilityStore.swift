//
//  ParkingAvailabilityStore.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 24/01/26.
//


import Foundation
import Supabase
internal import Combine

@MainActor
final class ParkingAvailabilityStore: ObservableObject,Sendable {

    @Published private(set) var byParkingId: [UUID: ParkingAvailability] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var available: [UUID: Int] = [:]


    private let client: SupabaseClient
    private var channel: RealtimeChannelV2?
    private var hasLoadedOnce = false

    init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - Read helper (UI dan qulay)
    func availability(for parkingId: UUID) -> ParkingAvailability? {
        byParkingId[parkingId]
    }

    // MARK: - Initial load (select)
    func initialLoad(force: Bool = false) {
        if hasLoadedOnce && !force { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                self.isLoading = true
                self.errorMessage = nil
                defer { self.isLoading = false }

                let rows: [ParkingAvailability] = try await client
                    .from("parking_availability")
                    .select()
                    .execute()
                    .value

                var map: [UUID: ParkingAvailability] = [:]
                var avail: [UUID: Int] = [:]
                rows.forEach { map[$0.parkingId] = $0
                    avail[$0.parkingId] = $0.availableSpots}
                self.byParkingId = map
                self.available = avail
                self.hasLoadedOnce = true
            } catch {
                self.errorMessage = "Availability yuklanmadi"
                print("availability initialLoad error:", error)
            }
        }
    }

    // MARK: - Realtime subscribe (UPDATE)
    func startRealtime() {
        // ikki marta subscribe bo'lib ketmasin
        if channel != nil { return }

        Task { [weak self] in
            guard let self else { return }

            do {
                let channel = client.realtimeV2.channel("realtime:parking_availability")
                self.channel = channel

                // ✅ Muhim: UpdateAction ishlatamiz, shunda update.record bor.
                let updates = channel.postgresChange(
                    UpdateAction.self,
                    schema: "public",
                    table: "parking_availability"
                )

                try await channel.subscribe()

                // stream listener
                Task { [weak self] in
                    guard let self else { return }
                    for await update in updates {
                        print("✅ REALTIME UPDATE:", update.record)
                        print("raw available_spots:", update.record["available_spots"] as Any,
                              "type:", type(of: update.record["available_spots"] as Any))

                        if let decoded = self.decodeAvailability(from: update.record) {
                            print("✅ DECODED:", decoded.parkingId, decoded.availableSpots)
                            self.byParkingId[decoded.parkingId] = decoded
                            self.available[decoded.parkingId] = decoded.availableSpots
                            print("✅ DECODED available:", decoded.availableSpots,
                                  "reserved:", decoded.reservedSpots,
                                  "live:", decoded.liveOccupancy)

                        } else {
                            print("❌ decode failed")
                        }
                    }
                }

            } catch {
                self.errorMessage = "Realtime ishlamadi"
                print("availability realtime error:", error)
            }
        }
    }

    func stopRealtime() {
        Task { [weak self] in
            guard let self, let ch = self.channel else { return }
            await ch.unsubscribe()
            self.channel = nil
        }
    }

    // MARK: - Decode
    private func decodeAvailability(from record: JSONObject) -> ParkingAvailability? {

        // parking_id: UUID yoki String bo'lishi mumkin
        func uuid(_ key: String) -> UUID? {
            if let u = record[key] as? UUID { return u }
            if let s = record[key] as? String { return UUID(uuidString: s) }

            // ba'zan CustomStringConvertible bo'lib keladi
            if let any = record[key] as? CustomStringConvertible {
                return UUID(uuidString: any.description)
            }
            return nil
        }

        // int: Int yoki Double yoki String bo'lishi mumkin
        func int(_ key: String) -> Int {
            guard let raw = record[key] else { return 0 }

            // 1) common numeric types
            if let v = raw as? Int { return v }
            if let v = raw as? Int64 { return Int(v) }
            if let v = raw as? Double { return Int(v) }
            if let v = raw as? Float { return Int(v) }

            // 2) NSNumber (most common from JSON bridging)
            if let n = raw as? NSNumber { return n.intValue }

            // 3) String number
            if let s = raw as? String { return Int(s) ?? 0 }

            // 4) Fallback: parse from description (handles many wrapper types)
            let desc = String(describing: raw)          // e.g. "69" or "Optional(69)"
            let cleaned = desc
                .replacingOccurrences(of: "Optional(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return Int(cleaned) ?? 0
        }


        // updated_at: String yoki Date bo'lishi mumkin
        func date(_ key: String) -> Date {
            if let d = record[key] as? Date { return d }
            if let s = record[key] as? String {
                // Supabase timestamp ko'pincha fractionalSeconds bilan keladi
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let d = f.date(from: s) { return d }

                // fallback (fractionalSeconds bo'lmasa)
                let f2 = ISO8601DateFormatter()
                f2.formatOptions = [.withInternetDateTime]
                return f2.date(from: s) ?? Date()
            }

            if let any = record[key] as? CustomStringConvertible {
                let s = any.description
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return f.date(from: s) ?? Date()
            }

            return Date()
        }

        guard let pid = uuid("parking_id") else { return nil }

        return ParkingAvailability(
            parkingId: pid,
            liveOccupancy: int("live_occupancy"),
            reservedSpots: int("reserved_spots"),
            availableSpots: int("available_spots"),
            updatedAt: date("updated_at")
        )
    }


}
