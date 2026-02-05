//
//  NotificationManager.swift
//  Smart parking
//
//  Real-time notification manager - Supabase Realtime bilan
//

import Supabase
import SwiftUI
import UserNotifications
internal import Combine

// MARK: - Notification Model
struct UserNotification: Codable, Identifiable, Equatable {
    let id: UUID
    let user_id: UUID
    let type: String
    let title: String
    let message: String
    let is_read: Bool
    let created_at: Date
    let reservation_id: UUID?

    var icon: String {
        switch type {
        case "booking_created": return "car.fill"
        case "booking_canceled": return "xmark.circle.fill"
        case "booking_started": return "flag.fill"
        case "booking_completed": return "checkmark.circle.fill"
        case "time_warning_15": return "clock"
        case "time_warning_5": return "clock.badge.exclamationmark"
        case "time_expired": return "exclamationmark.triangle.fill"
        case "payment_success": return "creditcard.fill"
        default: return "bell.fill"
        }
    }

    var iconColor: Color {
        switch type {
        case "booking_created": return .purple
        case "booking_canceled": return .red
        case "booking_started": return .green
        case "booking_completed": return .blue
        case "time_warning_15": return .orange
        case "time_warning_5": return .red
        case "time_expired": return .red
        case "payment_success": return .green
        default: return .gray
        }
    }

    var timeAgo: String {
        let diff = Date().timeIntervalSince(created_at)
        if diff < 60 { return "now" }
        if diff < 3600 { return "\(Int(diff/60))m" }
        if diff < 86400 { return "\(Int(diff/3600))h" }
        return "\(Int(diff/86400))d"
    }
}

// MARK: - Notification Manager (Singleton + Realtime)
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var notifications: [UserNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false

    private var realtimeChannel: RealtimeChannelV2?
    private var streamTask: Task<Void, Never>?

    private init() {
        requestPushPermission()
    }

    // MARK: - Load Notifications
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let userID = try await currentUserID()

            let rows: [UserNotification] = try await SB.shared.client
                .from("notifications")
                .select()
                .eq("user_id", value: userID)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            self.notifications = rows
            self.unreadCount = rows.filter { !$0.is_read }.count
        } catch {
            self.notifications = []
            self.unreadCount = 0
            print("❌ Notifications load error: \(error)")
        }
    }

    // MARK: - Start Realtime
    func startRealtime() {
        guard realtimeChannel == nil else { return }

        Task {
            do {
                let userID = try await currentUserID()
                let channel = SB.shared.client.realtimeV2.channel("notifications_\(userID)")

                let insertions = channel.postgresChange(
                    InsertAction.self,
                    schema: "public",
                    table: "notifications",
                    filter: .eq("user_id", value: userID)
                )

                try await channel.subscribeWithError()
                self.realtimeChannel = channel

                streamTask?.cancel()
                streamTask = Task { [weak self] in
                    guard let self else { return }
                    for await insertion in insertions {
                        await handleNewNotification(insertion)
                    }
                }
            } catch {
                print("❌ Notification realtime start error: \(error)")
            }
        }
    }

    // MARK: - Stop Realtime
    func stopRealtime() {
        Task {
            if let channel = realtimeChannel {
                streamTask?.cancel()
                streamTask = nil
                await channel.unsubscribe()
                self.realtimeChannel = nil
            }
        }
    }

    // MARK: - Handle New Notification
    private func handleNewNotification(_ action: InsertAction) async {
        do {
            let notification = try action.decodeRecord(
                as: UserNotification.self, decoder: JSONDecoder.supabaseDecoder)

            // Add to list
            await MainActor.run {
                self.notifications.insert(notification, at: 0)
                self.unreadCount += 1
            }

            // Show local push notification
            showLocalNotification(notification)

        } catch {
            print("❌ Decode notification error: \(error)")
        }
    }

    // MARK: - Mark as Read
    func markAsRead(_ id: UUID) async {
        do {
            let userID = try await currentUserID()

            try await SB.shared.client
                .from("notifications")
                .update(["is_read": true])
                .eq("id", value: id.uuidString)
                .eq("user_id", value: userID)
                .execute()

            if let index = notifications.firstIndex(where: { $0.id == id }) {
                let n = notifications[index]
                notifications[index] = UserNotification(
                    id: n.id, user_id: n.user_id, type: n.type,
                    title: n.title, message: n.message, is_read: true,
                    created_at: n.created_at, reservation_id: n.reservation_id
                )
                unreadCount = max(0, unreadCount - 1)
            }
        } catch {
            print("❌ Mark as read error: \(error)")
        }
    }

    func markAllAsRead() async {
        do {
            let userID = try await currentUserID()

            try await SB.shared.client
                .from("notifications")
                .update(["is_read": true])
                .eq("user_id", value: userID)
                .eq("is_read", value: false)
                .execute()

            notifications = notifications.map { n in
                UserNotification(
                    id: n.id, user_id: n.user_id, type: n.type,
                    title: n.title, message: n.message, is_read: true,
                    created_at: n.created_at, reservation_id: n.reservation_id
                )
            }
            unreadCount = 0
        } catch {
            print("❌ Mark all as read error: \(error)")
        }
    }

    // MARK: - Local Push Notification
    private func showLocalNotification(_ notification: UserNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: nil  // Immediately
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Request Push Permission
    private func requestPushPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            granted, error in
            if granted {
                print("✅ Push notifications allowed")
            }
        }
    }

    private func currentUserID() async throws -> String {
        try await SB.shared.client.auth.session.user.id.uuidString
    }
}

// MARK: - JSON Decoder Extension
extension JSONDecoder {
    static var supabaseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            let formatterWithFractional = ISO8601DateFormatter()
            formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsed = formatterWithFractional.date(from: raw) {
                return parsed
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            if let parsed = formatter.date(from: raw) {
                return parsed
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported date format: \(raw)"
            )
        }
        return decoder
    }
}
