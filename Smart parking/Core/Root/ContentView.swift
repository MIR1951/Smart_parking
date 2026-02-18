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
    @State private var appCoordinator = AppCoordinator.shared

    @State private var didStart = false
    @State private var activeNotificationUserID: String?
    @State private var showSplash = true
    @State private var splashOpacity: Double = 1.0

    var body: some View {
        @Bindable var appCoordinator = appCoordinator

        ZStack {
            Group {
                if authManager.currentUserID != nil {
                    NavigationStack(path: $appCoordinator.path) {
                        MainTabView()
                            .navigationDestination(for: AppRoute.self) { route in
                                routeDestination(for: route)
                            }
                    }
                    .environment(appCoordinator)
                    .environmentObject(parkingsStore)
                    .environmentObject(favoritesStore)
                    .environmentObject(availabilityStore)
                    .onAppear {
                        guard !didStart else { return }
                        didStart = true
                        availabilityStore.initialLoad()
                    }
                    .fullScreenCover(
                        item: $appCoordinator.fullScreenRoute,
                        onDismiss: {
                            appCoordinator.endBookingFlow()
                        }
                    ) { route in
                        fullScreenDestination(for: route)
                            .environment(appCoordinator)
                            .environmentObject(parkingsStore)
                            .environmentObject(favoritesStore)
                            .environmentObject(availabilityStore)
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
            synchronizeSessionState(userID: newValue)
        }
        .task {
            await authManager.refreshUser()
            synchronizeSessionState(userID: authManager.currentUserID)
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

    private func synchronizeSessionState(userID: String?) {
        favoritesStore.setCurrentUserID(userID)
        VehiclesStore.shared.setCurrentUserID(userID)
        WalletManager.shared.setCurrentUserID(userID)

        guard let userID else {
            didStart = false
            activeNotificationUserID = nil
            appCoordinator.resetForLogout()
            NotificationManager.shared.stopRealtime()
            NotificationManager.shared.resetState()
            return
        }

        guard activeNotificationUserID != userID else { return }
        activeNotificationUserID = userID

        Task {
            await NotificationManager.shared.load()
            NotificationManager.shared.startRealtime()
        }
    }

    @ViewBuilder
    private func routeDestination(for route: AppRoute) -> some View {
        switch route {
        case .parkingDetail(let parking):
            ParkingDetailView(parking: parking)
        case .notifications:
            NotificationsView()
                .toolbar(.hidden, for: .tabBar)
        case .settings:
            SettingsView()
                .toolbar(.hidden, for: .tabBar)
        case .wallet:
            WalletView()
                .toolbar(.hidden, for: .tabBar)
        }
    }

    @ViewBuilder
    private func fullScreenDestination(for route: AppFullScreenRoute) -> some View {
        switch route {
        case .bookingFlow(let parking):
            BookingFlowView(parking: parking)
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
