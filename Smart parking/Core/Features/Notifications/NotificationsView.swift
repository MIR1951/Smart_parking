//
//  NotificationsView.swift
//  Smart parking
//
//  Real-time bildirishnomalar sahifasi
//

import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotificationManager.shared

    private var todayNotifications: [UserNotification] {
        manager.notifications.filter { Calendar.current.isDateInToday($0.created_at) }
    }

    private var yesterdayNotifications: [UserNotification] {
        manager.notifications.filter { Calendar.current.isDateInYesterday($0.created_at) }
    }

    private var olderNotifications: [UserNotification] {
        manager.notifications.filter {
            !Calendar.current.isDateInToday($0.created_at)
                && !Calendar.current.isDateInYesterday($0.created_at)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if manager.isLoading && manager.notifications.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if manager.notifications.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            await manager.load()
            manager.startRealtime()
        }
        .onDisappear {
            manager.stopRealtime()
        }
        .refreshable {
            await manager.load()
        }
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

            Text("Notifications")
                .font(.headline)

            if manager.unreadCount > 0 {
                Text("\(manager.unreadCount) NEW")
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

    // MARK: - Content
    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                if !todayNotifications.isEmpty {
                    sectionHeader("TODAY")
                    ForEach(todayNotifications) { notification in
                        NotificationRow(notification: notification) {
                            Task { await manager.markAsRead(notification.id) }
                        }
                    }
                }

                if !yesterdayNotifications.isEmpty {
                    sectionHeader("YESTERDAY")
                    ForEach(yesterdayNotifications) { notification in
                        NotificationRow(notification: notification) {
                            Task { await manager.markAsRead(notification.id) }
                        }
                    }
                }

                if !olderNotifications.isEmpty {
                    sectionHeader("OLDER")
                    ForEach(olderNotifications) { notification in
                        NotificationRow(notification: notification) {
                            Task { await manager.markAsRead(notification.id) }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("No Notifications")
                .font(.headline)
                .foregroundColor(.gray)
            Text("You're all caught up!")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
            Spacer()
        }
    }

    // MARK: - Section Header
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.gray)

            Spacer()

            if manager.unreadCount > 0 {
                Button("Mark all read") {
                    Task { await manager.markAllAsRead() }
                }
                .font(.caption)
                .foregroundColor(.purple)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Notification Row
private struct NotificationRow: View {
    let notification: UserNotification
    let onTap: () -> Void

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

                    Text(notification.timeAgo)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            !notification.is_read
                ? Circle()
                    .fill(Color.purple)
                    .frame(width: 8, height: 8)
                    .offset(x: 8, y: -8)
                : nil,
            alignment: .topTrailing
        )
        .onTapGesture(perform: onTap)
    }
}
