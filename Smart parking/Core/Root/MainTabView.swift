//
//  MainTabView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//

import SwiftUI

struct MainTabView: View {
    @Environment(LocalizationManager.self) private var loc

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label(loc.str(.tabHome), systemImage: "house") }

            ExploreView()
                .tabItem { Label(loc.str(.tabExplore), systemImage: "location") }

            FavoriteView()
                .tabItem { Label(loc.str(.tabFavorite), systemImage: "heart") }

            BookingsView()
                .tabItem { Label(loc.str(.tabBookings), systemImage: "doc.text") }

            ProfileView()
                .tabItem { Label(loc.str(.tabProfile), systemImage: "person") }
        }
        .tint(AppTheme.Palette.brand)
    }
}
