//
//  NotificationsView.swift
//  Smart parking
//
//  Real-time bildirishnomalar sahifasi
//

import SwiftUI
internal import Combine
struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotificationManager.shared
    private var loc = LocalizationManager.shared

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
                Spacer(minLength: 24)
                AppStateView(kind: .loading(title: loc.str(.notifLoading)))
                Spacer()
            } else if manager.notifications.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .background(AppTheme.Palette.pageBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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
                    .foregroundColor(AppTheme.Palette.textPrimary)
                    .padding(12)
                    .background(AppTheme.Palette.surface)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4)
            }

            Spacer()

            Text(loc.str(.notifTitle))
                .font(.headline)

            if manager.unreadCount > 0 {
                Text("\(manager.unreadCount) \(loc.str(.notifNew))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.Palette.brand)
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
                    sectionHeader(loc.str(.notifToday))
                    ForEach(todayNotifications) { notification in
                        NotificationRow(notification: notification) {
                            Task { await manager.markAsRead(notification.id) }
                        }
                    }
                }

                if !yesterdayNotifications.isEmpty {
                    sectionHeader(loc.str(.notifYesterday))
                    ForEach(yesterdayNotifications) { notification in
                        NotificationRow(notification: notification) {
                            Task { await manager.markAsRead(notification.id) }
                        }
                    }
                }

                if !olderNotifications.isEmpty {
                    sectionHeader(loc.str(.notifOlder))
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
        AppStateView(
            kind: .empty(
                icon: "bell.slash",
                title: loc.str(.notifEmpty),
                subtitle: loc.str(.notifAllCaughtUp)
            )
        )
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
                Button(loc.str(.notifMarkAllRead)) {
                    Task { await manager.markAllAsRead() }
                }
                .font(.caption)
                .foregroundColor(AppTheme.Palette.brand)
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
        .background(AppTheme.Palette.surface)
        .cornerRadius(16)
        .overlay(
            !notification.is_read
                ? Circle()
                    .fill(AppTheme.Palette.brand)
                    .frame(width: 8, height: 8)
                    .offset(x: 8, y: -8)
                : nil,
            alignment: .topTrailing
        )
        .onTapGesture(perform: onTap)
    }
}
