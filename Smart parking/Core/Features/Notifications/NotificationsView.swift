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
    private let loc = LocalizationManager.shared

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
        ZStack {
            backgroundDecoration

            VStack(spacing: 0) {
                header
                scrollContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if manager.notifications.isEmpty {
                await manager.load()
            }
        }
    }

    private var backgroundDecoration: some View {
        AppAnimatedBackground()
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(AppTheme.Palette.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Palette.surface.opacity(0.9))
                    .clipShape(Circle())
            }
            .pressStyle()

            Spacer()

            VStack(spacing: 2) {
                Text(loc.str(.notifTitle))
                    .font(.headline)

                if manager.isLoading && !manager.notifications.isEmpty {
                    Text(loc.str(.notifLoading))
                        .font(.caption2)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }
            }

            if manager.unreadCount > 0 {
                Text("\(manager.unreadCount) \(loc.str(.notifNew))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.Gradient.brand)
                    .cornerRadius(12)
            }

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if manager.isLoading && manager.notifications.isEmpty {
                    loadingState
                } else if manager.notifications.isEmpty {
                    emptyState
                } else {
                    if !todayNotifications.isEmpty {
                        sectionHeader(loc.str(.notifToday))
                        ForEach(Array(todayNotifications.enumerated()), id: \.element.id) {
                            index, notification in
                            NotificationRow(notification: notification) {
                                Task { await manager.markAsRead(notification.id) }
                            }
                            .appReveal(Double(index) * 0.03)
                        }
                    }

                    if !yesterdayNotifications.isEmpty {
                        sectionHeader(loc.str(.notifYesterday))
                        ForEach(Array(yesterdayNotifications.enumerated()), id: \.element.id) {
                            index, notification in
                            NotificationRow(notification: notification) {
                                Task { await manager.markAsRead(notification.id) }
                            }
                            .appReveal(Double(index) * 0.03 + 0.08)
                        }
                    }

                    if !olderNotifications.isEmpty {
                        sectionHeader(loc.str(.notifOlder))
                        ForEach(Array(olderNotifications.enumerated()), id: \.element.id) {
                            index, notification in
                            NotificationRow(notification: notification) {
                                Task { await manager.markAsRead(notification.id) }
                            }
                            .appReveal(Double(index) * 0.03 + 0.14)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, minHeight: 420, alignment: .top)
        }
        .refreshable {
            await manager.load()
        }
    }

    private var loadingState: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            AppStateView(kind: .loading(title: loc.str(.notifLoading)))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 72)
    }

    private var emptyState: some View {
        AppStateView(
            kind: .empty(
                icon: "bell.slash",
                title: loc.str(.notifEmpty),
                subtitle: loc.str(.notifAllCaughtUp)
            )
        )
        .frame(maxWidth: .infinity)
        .padding(.top, 72)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Palette.textSecondary)

            Spacer()

            if manager.unreadCount > 0 {
                Button(loc.str(.notifMarkAllRead)) {
                    Task { await manager.markAllAsRead() }
                }
                .font(.caption)
                .foregroundColor(AppTheme.Palette.brand)
            }
        }
        .padding(.top, 10)
    }
}

private struct NotificationRow: View {
    let notification: UserNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(notification.iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: notification.icon)
                        .font(.body)
                        .foregroundColor(notification.iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.Palette.textPrimary)

                        Spacer()

                        Text(notification.timeAgo)
                            .font(.caption)
                            .foregroundColor(AppTheme.Palette.textSecondary)
                    }

                    Text(notification.message)
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                        .lineLimit(3)
                }
            }
            .padding()
            .background(AppTheme.Palette.surface.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.Palette.border, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if !notification.is_read {
                    Circle()
                        .fill(AppTheme.Palette.brand)
                        .frame(width: 8, height: 8)
                        .offset(x: -10, y: 10)
                }
            }
        }
        .buttonStyle(.plain)
        .pressStyle()
    }
}
