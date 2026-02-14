//
//  MainTabView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//

import SwiftUI

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
    }
}
