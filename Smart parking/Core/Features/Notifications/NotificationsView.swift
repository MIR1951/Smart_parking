//
//  NotificationsView.swift
//  Smart parking
//
//  Bildirishnomalar sahifasi
//

import SwiftUI
internal import Combine

// MARK: - Notification Model
struct AppNotification: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let time: String
    let isNew: Bool
}

// MARK: - Notifications Store
@MainActor
class NotificationsStore: ObservableObject {
    static let shared = NotificationsStore()

    @Published var notifications: [AppNotification] = []
    @Published var newCount: Int = 0

    private init() {
        loadDemoNotifications()
    }

    private func loadDemoNotifications() {
        notifications = [
            AppNotification(
                icon: "car.fill",
                iconColor: .purple,
                title: "Slot Booked Successfully",
                description:
                    "Your parking slot has been booked successfully. Enjoy your parking experience!",
                time: "1h",
                isNew: true
            ),
            AppNotification(
                icon: "clock",
                iconColor: .gray,
                title: "15 Minutes Remain",
                description:
                    "Your parking session will expire in 15 minutes. Please extend or prepare to leave.",
                time: "8h",
                isNew: true
            ),
            AppNotification(
                icon: "star.fill",
                iconColor: .yellow,
                title: "Slot Review Request",
                description: "How was your parking experience? Leave a review to help other users.",
                time: "9h",
                isNew: false
            ),
            AppNotification(
                icon: "xmark.circle.fill",
                iconColor: .red,
                title: "Slot Booking Cancelled",
                description: "Your parking booking has been cancelled as per your request.",
                time: "1d",
                isNew: false
            ),
            AppNotification(
                icon: "creditcard",
                iconColor: .blue,
                title: "New Paypal Added",
                description: "Your PayPal account has been successfully linked to your profile.",
                time: "1d",
                isNew: false
            ),
            AppNotification(
                icon: "clock.badge.exclamationmark",
                iconColor: .orange,
                title: "1 Hours Remain",
                description: "You have 1 hour remaining in your parking session.",
                time: "1d",
                isNew: false
            ),
        ]
        newCount = notifications.filter { $0.isNew }.count
    }

    func markAllAsRead() {
        notifications = notifications.map { n in
            AppNotification(
                icon: n.icon,
                iconColor: n.iconColor,
                title: n.title,
                description: n.description,
                time: n.time,
                isNew: false
            )
        }
        newCount = 0
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = NotificationsStore.shared

    private var todayNotifications: [AppNotification] {
        store.notifications.filter { $0.time.contains("h") || $0.time == "now" }
    }

    private var yesterdayNotifications: [AppNotification] {
        store.notifications.filter { $0.time.contains("d") }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Today Section
                    if !todayNotifications.isEmpty {
                        sectionHeader(title: "TODAY", onMarkRead: { store.markAllAsRead() })

                        ForEach(todayNotifications) { notification in
                            NotificationRow(notification: notification)
                        }
                    }

                    // Yesterday Section
                    if !yesterdayNotifications.isEmpty {
                        sectionHeader(title: "YESTERDAY", onMarkRead: { store.markAllAsRead() })

                        ForEach(yesterdayNotifications) { notification in
                            NotificationRow(notification: notification)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4)
            }

            Spacer()

            Text("Notification")
                .font(.headline)

            // Badge
            if store.newCount > 0 {
                Text("\(store.newCount) NEW")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.purple)
                    .cornerRadius(12)
            }

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Section Header
    private func sectionHeader(title: String, onMarkRead: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.gray)

            Spacer()

            Button("Mark all as read") {
                onMarkRead()
            }
            .font(.caption)
            .foregroundColor(.purple)
        }
        .padding(.top, 8)
    }
}

// MARK: - Notification Row
private struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(notification.iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: notification.icon)
                    .font(.body)
                    .foregroundColor(notification.iconColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text(notification.time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Text(notification.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            // New indicator
            notification.isNew
                ? Circle()
                    .fill(Color.purple)
                    .frame(width: 8, height: 8)
                    .offset(x: 8, y: -8)
                : nil,
            alignment: .topTrailing
        )
    }
}
