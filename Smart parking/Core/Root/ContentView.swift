//
//  ContentView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 30/11/25.
//

 import Combine
import Supabase
import SwiftUI

struct ContentView: View {

    @Environment(AuthManager.self) private var authManager
    @Environment(UserManager.self) private var userManager
    @Environment(LocalizationManager.self) private var loc
    @Environment(AppearanceManager.self) private var appearance
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var availabilityStore = ParkingAvailabilityStore(client: SB.shared.client)
    @StateObject private var parkingsStore = ParkingsStore()
    @StateObject private var reviewStore = ParkingReviewStore()
    @StateObject private var favoritesStore = FavoritesStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var appCoordinator = AppCoordinator.shared
    @State private var adminStore = AdminStore()

    @State private var didStart = false
    @State private var didRunLaunchGate = false
    @State private var isRunningLaunchGate = false
    @State private var activeNotificationUserID: String?
    @State private var showSplash = true
    @State private var splashOpacity: Double = 1.0
    @State private var launchGateState: LaunchGateState = .idle
    @State private var isBootstrappingAfterLogin = false

    enum LaunchGateState: Equatable {
        case idle
        case loading
        case ready
        case failed(message: String)
    }

    var body: some View {
        @Bindable var appCoordinator = appCoordinator

        ZStack {
            Group {
                if authManager.currentUserID != nil {
                    if isBootstrappingAfterLogin {
                        bootstrapLoadingView
                            .transition(.opacity)
                    } else if userManager.isOwner {
                        AdminTabView(store: adminStore)
                            .environment(appCoordinator)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                removal: .opacity
                            ))
                    } else {
                        NavigationStack(path: $appCoordinator.path) {
                            MainTabView()
                                .navigationDestination(for: AppRoute.self) { route in
                                    routeDestination(for: route)
                                }
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        ))
                        .environment(appCoordinator)
                        .environmentObject(parkingsStore)
                        .environmentObject(reviewStore)
                        .environmentObject(favoritesStore)
                        .environmentObject(availabilityStore)
                        .environmentObject(locationManager)
                        .environmentObject(notificationManager)
                        .fullScreenCover(
                            item: $appCoordinator.fullScreenRoute,
                            onDismiss: {
                                appCoordinator.endBookingFlow()
                            }
                        ) { route in
                            fullScreenDestination(for: route)
                                .environment(appCoordinator)
                                .environmentObject(parkingsStore)
                                .environmentObject(reviewStore)
                                .environmentObject(favoritesStore)
                                .environmentObject(availabilityStore)
                                .environmentObject(locationManager)
                                .environmentObject(notificationManager)
                        }
                    }
                } else {
                    LoginView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authManager.currentUserID)
            .id(appearance.themeVersion)

            // Splash screen overlay
            if showSplash {
                splashOverlay
                    .opacity(splashOpacity)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            guard authManager.currentUserID != nil else { return }
            guard launchGateState == .ready else { return }
            Task {
                await availabilityStore.refreshNow(force: true)
                parkingsStore.applyFilters(userLocation: locationManager.location)
                if !availabilityStore.isRealtimeConnected {
                    availabilityStore.startRealtime()
                }
                parkingsStore.startRealtime(userLocation: locationManager.location)
            }
        }
        .onChange(of: locationManager.placeName) { _, newPlace in
            parkingsStore.bootstrapCity(using: newPlace, fallback: "Tashkent")
        }
        .onChange(of: locationManager.location) { _, newLocation in
            parkingsStore.applyFilters(userLocation: newLocation)
        }
        .onChange(of: authManager.currentUserID) { _, newValue in
            synchronizeSessionState(userID: newValue)

            guard newValue != nil else {
                isBootstrappingAfterLogin = false
                return
            }
            guard didRunLaunchGate else { return }
            guard !isRunningLaunchGate else { return }

            isBootstrappingAfterLogin = true
            Task {
                try? await bootstrapAuthenticatedSessionIfNeeded(forceNetwork: false)
                isBootstrappingAfterLogin = false
            }
        }
        .task {
            guard !didRunLaunchGate else { return }
            didRunLaunchGate = true
            await runLaunchGate()
        }
    }

    @ViewBuilder
    private var bootstrapLoadingView: some View {
        ZStack {
            AppAnimatedBackground()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(AppTheme.Palette.brand)
                Text(loc.str(.launchLoading))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }
            .padding(28)
            .glassCard()
        }
    }

    @ViewBuilder
    private var splashOverlay: some View {
        ZStack {
            SplashScreenView()

            VStack {
                Spacer()

                switch launchGateState {
                case .idle, .loading:
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(.white)
                        Text(loc.str(.launchLoading))
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(.white.opacity(0.92))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.28))
                    .clipShape(Capsule())
                    .padding(.bottom, 52)

                case .failed(let message):
                    AppStateView(
                        kind: .error(
                            title: loc.str(.launchFailed),
                            subtitle: message,
                            actionTitle: loc.str(.retry),
                            action: {
                                Task { await runLaunchGate() }
                            }
                        )
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                case .ready:
                    EmptyView()
                }
            }
        }
    }

    private func runLaunchGate() async {
        isRunningLaunchGate = true
        launchGateState = .loading
        showSplash = true
        splashOpacity = 1

        defer { isRunningLaunchGate = false }

        await authManager.refreshUser()

        guard authManager.currentUserID != nil else {
            launchGateState = .ready
            await hideSplash()
            return
        }

        do {
            try await bootstrapAuthenticatedSessionIfNeeded(forceNetwork: true)
            isBootstrappingAfterLogin = false
            launchGateState = .ready
            await hideSplash()
        } catch {
            launchGateState = .failed(message: launchFailureMessage(from: error))
        }
    }

    private func hideSplash() async {
        withAnimation(.easeOut(duration: 0.45)) {
            splashOpacity = 0
        }
        try? await Task.sleep(nanoseconds: 520_000_000)
        showSplash = false
    }

    private func bootstrapAuthenticatedSessionIfNeeded(forceNetwork: Bool) async throws {
        guard !didStart || forceNetwork else { return }

        await userManager.fetchCurrentUser()
        locationManager.requestPermission()
        try await parkingsStore.loadAndWait(
            userLocation: locationManager.location,
            force: forceNetwork
        )
        parkingsStore.bootstrapCity(
            using: locationManager.placeName,
            fallback: "Tashkent"
        )
        parkingsStore.applyFilters(userLocation: locationManager.location)
        try await availabilityStore.initialLoad(force: forceNetwork)
        availabilityStore.startRealtime()
        didStart = true
    }

    private func launchFailureMessage(from error: Error) -> String {
        let lowered = error.localizedDescription.lowercased()
        if lowered.contains("parkings.city") || (lowered.contains("column") && lowered.contains("city")) {
            return "Backend migration topilmadi: parkings.city ustuni mavjud emas. Avval city migrationni qo'llang."
        }
        return error.localizedDescription
    }

    private func synchronizeSessionState(userID: String?) {
        favoritesStore.setCurrentUserID(userID)
        VehiclesStore.shared.setCurrentUserID(userID)
        WalletManager.shared.setCurrentUserID(userID)

        guard let userID else {
            didStart = false
            activeNotificationUserID = nil
            appCoordinator.resetForLogout()

            let pStore = parkingsStore
            let aStore = availabilityStore
            let aAdminStore = adminStore
            Task.detached(priority: .utility) {
                await MainActor.run {
                    pStore.stopRealtime()
                    aStore.stopRealtime()
                    NotificationManager.shared.stopRealtime()
                    NotificationManager.shared.resetState()
                    aAdminStore.stopRealtime()
                }
            }
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
                .toolbar(.visible, for: .navigationBar)
                .toolbar(.hidden, for: .tabBar)
        case .wallet:
            WalletView()
                .toolbar(.visible, for: .navigationBar)
                .toolbar(.hidden, for: .tabBar)
        }
    }

    @ViewBuilder
    private func fullScreenDestination(for route: AppFullScreenRoute) -> some View {
        switch route {
        case .bookingFlow(let parking, _):
            BookingFlowView(parking: parking)
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
