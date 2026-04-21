//
//  MainTabView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//

import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

struct MainTabView: View {
    @Environment(LocalizationManager.self) private var loc
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator

        TabView(selection: $coordinator.selectedTab) {
            HomeView()
                .tag(AppCoordinator.Tab.home)
                .tabItem { Label(loc.str(.tabHome), systemImage: "house") }

            ExploreView()
                .tag(AppCoordinator.Tab.explore)
                .tabItem { Label(loc.str(.tabExplore), systemImage: "location") }

            FavoriteView()
                .tag(AppCoordinator.Tab.favorite)
                .tabItem { Label(loc.str(.tabFavorite), systemImage: "heart") }

            BookingsView()
                .tag(AppCoordinator.Tab.bookings)
                .tabItem { Label(loc.str(.tabBookings), systemImage: "doc.text") }

            ProfileView()
                .tag(AppCoordinator.Tab.profile)
                .tabItem { Label(loc.str(.tabProfile), systemImage: "person") }
        }
        .tint(AppTheme.Palette.brand)
        .toolbarBackground(AppTheme.Palette.surface.opacity(0.96), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .animation(AppTheme.Anim.snappy, value: coordinator.selectedTab)
        .onAppear {
            configureTabBarAppearance()
        }
    }

    private func configureTabBarAppearance() {
        #if canImport(UIKit)
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AppTheme.Palette.surface)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(
                AppTheme.Palette.textSecondary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(AppTheme.Palette.textSecondary)
            ]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.Palette.brand)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(AppTheme.Palette.brand)
            ]

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }
}
