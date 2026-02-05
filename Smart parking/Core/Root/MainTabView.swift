//
//  MainTabView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//


import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }

            ExploreView()
                .tabItem { Label("Explore", systemImage: "location") }
            FavoriteView()
               
                .tabItem { Label("Favorite", systemImage: "heart") }

            BookingsView()
                .tabItem { Label("Bookings", systemImage: "doc.text") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
        }
        .tint(AppTheme.Palette.brand)
    }
}
