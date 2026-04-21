//
//  AdminTabView.swift
//  Smart parking
//
//  Parking egalari uchun admin panel — custom glass tab bar
//

import SwiftUI

struct AdminTabView: View {
    let store: AdminStore

    @Environment(AuthManager.self) private var authManager
    @Environment(LocalizationManager.self) private var loc

    @State private var selectedTab: AdminTab = .dashboard

    enum AdminTab: Int, CaseIterable {
        case dashboard, parkings, reservations, profile

        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .parkings: return "car.fill"
            case .reservations: return "calendar.badge.clock"
            case .profile: return "person.fill"
            }
        }

        func label(loc: LocalizationManager) -> String {
            switch self {
            case .dashboard: return loc.str(.adminDashboard)
            case .parkings: return loc.str(.adminMyParkings)
            case .reservations: return loc.str(.adminReservations)
            case .profile: return loc.str(.adminProfile)
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .dashboard:
                    NavigationStack {
                        AdminDashboardView(store: store)
                    }
                case .parkings:
                    NavigationStack {
                        AdminParkingListView(store: store)
                    }
                case .reservations:
                    NavigationStack {
                        AdminReservationsView(store: store)
                    }
                case .profile:
                    NavigationStack {
                        AdminProfileView(store: store)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 72)

            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .task {
            await store.loadAll()
            store.startRealtime()
        }
        .onDisappear {
            store.stopRealtime()
        }
    }

    // MARK: - Custom Glass Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AdminTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: AppTheme.Radius.xLarge)
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
        .appShadow(AppTheme.Shadow.medium())
    }

    private func tabButton(_ tab: AdminTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(AppTheme.Anim.snappy) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .fill(AppTheme.Palette.brandSoft)
                            .frame(width: 48, height: 32)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? AppTheme.Palette.brand : AppTheme.Palette.textTertiary)
                }
                .frame(height: 32)

                Text(tab.label(loc: loc))
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? AppTheme.Palette.brand : AppTheme.Palette.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
