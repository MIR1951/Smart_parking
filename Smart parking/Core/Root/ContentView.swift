//
//  ContentView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 30/11/25.
//

internal import Combine
import Supabase
import SwiftUI

struct ContentView: View {

    @Environment(AuthManager.self) private var authManager
    @StateObject private var availabilityStore = ParkingAvailabilityStore(client: SB.shared.client)
    @StateObject private var parkingsStore = ParkingsStore()
    @StateObject private var favoritesStore = FavoritesStore()

    @State private var didStart = false
    @State private var didStartNotifications = false
    @State private var showSplash = true
    @State private var splashOpacity: Double = 1.0

    var body: some View {
        ZStack {
            Group {
                if authManager.currentUserID != nil {
                    MainTabView()
                        .environmentObject(parkingsStore)
                        .environmentObject(favoritesStore)
                        .environmentObject(availabilityStore)
                        .onAppear {
                            guard !didStart else { return }
                            didStart = true
                            availabilityStore.initialLoad()
                        }
                } else {
                    LoginView()
                }
            }

            // Splash screen overlay
            if showSplash {
                SplashScreenView()
                    .opacity(splashOpacity)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .onChange(of: authManager.currentUserID) { _, newValue in
            if newValue != nil {
                guard !didStartNotifications else { return }
                didStartNotifications = true
                Task {
                    await NotificationManager.shared.load()
                    NotificationManager.shared.startRealtime()
                }
            } else {
                didStart = false
                didStartNotifications = false
                NotificationManager.shared.stopRealtime()
            }
        }
        .task {
            await authManager.refreshUser()
            // Auth refresh bo'lgandan keyin splash ni yashirish
            try? await Task.sleep(nanoseconds: 1_800_000_000)  // 1.8 soniya minimum
            withAnimation(.easeOut(duration: 0.6)) {
                splashOpacity = 0
            }
            // Animatsiya tugagandan keyin view ni olib tashlash
            try? await Task.sleep(nanoseconds: 700_000_000)
            showSplash = false
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
