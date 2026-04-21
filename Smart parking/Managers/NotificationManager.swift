//
//  NotificationManager.swift
//  Smart parking
//
//  Real-time notification manager - Supabase Realtime bilan
//

import Combine
import os
import Supabase
import SwiftUI
import UserNotifications

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
        if diff < 60 { return LocalizationManager.shared.str(.timeNow) }
        if diff < 3600 { return "\(Int(diff/60))\(LocalizationManager.shared.str(.timeMinAgo))" }
        if diff < 86400 {
            return "\(Int(diff/3600))\(LocalizationManager.shared.str(.timeHourAgo))"
        }
        return "\(Int(diff/86400))\(LocalizationManager.shared.str(.timeDayAgo))"
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
    private var realtimeUserID: String?

    private init() {
        requestPushPermission()
    }

    // MARK: - Load Notifications
    func load() async {
        let previousNotifications = notifications
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
            // Refresh xatoligida mavjud listani saqlab qolamiz, UI "empty" ga tushib qolmasin.
            if previousNotifications.isEmpty {
                self.notifications = []
                self.unreadCount = 0
            } else {
                self.notifications = previousNotifications
                self.unreadCount = previousNotifications.filter { !$0.is_read }.count
            }

        }
    }

    // MARK: - Start Realtime
    func startRealtime() {
        Task {
            do {
                let userID = try await currentUserID()

                if realtimeUserID == userID, realtimeChannel != nil {
                    return
                }

                if realtimeChannel != nil {
                    stopRealtime()
                }

                let channel = SB.shared.client.realtimeV2.channel("notifications_\(userID)")

                let insertions = channel.postgresChange(
                    InsertAction.self,
                    schema: "public",
                    table: "notifications",
                    filter: .eq("user_id", value: userID)
                )

                try await channel.subscribeWithError()
                self.realtimeChannel = channel
                self.realtimeUserID = userID

                streamTask?.cancel()
                streamTask = Task { [weak self] in
                    guard let self else { return }
                    for await insertion in insertions {
                        await handleNewNotification(insertion)
                    }
                }
            } catch {
                Logger.auth.error("Notification realtime failed: \(error.localizedDescription)")
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
                self.realtimeUserID = nil
            }
        }
    }

    func resetState() {
        notifications = []
        unreadCount = 0
        isLoading = false
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
            Logger.auth.error("Notification decode failed: \(error.localizedDescription)")
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
            Logger.auth.error("markAsRead failed: \(error.localizedDescription)")
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
            Logger.auth.error("markAllAsRead failed: \(error.localizedDescription)")
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
