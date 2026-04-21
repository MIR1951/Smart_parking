//
//  AppCoordinator.swift
//  Smart parking
//
//  Markazlashtirilgan navigation boshqaruvi
//

import SwiftUI

// MARK: - App Routes
enum AppRoute: Hashable {
    case parkingDetail(Parking)
    case notifications
    case settings
    case wallet
}

enum AppFullScreenRoute: Hashable, Identifiable {
    case bookingFlow(Parking, UUID)

    var id: String {
        switch self {
        case .bookingFlow(let parking, let sessionID):
            return "booking_\(parking.id.uuidString)_\(sessionID.uuidString)"
        }
    }
}

// MARK: - App Coordinator
@MainActor
@Observable
final class AppCoordinator {
    static let shared = AppCoordinator()

    var path = NavigationPath()
    var selectedTab: Tab = .home
    var fullScreenRoute: AppFullScreenRoute?

    private init() {}

    enum Tab: Int, CaseIterable {
        case home, explore, favorite, bookings, profile
    }

    // MARK: - Navigation Actions

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func goToHome() {
        selectedTab = .home
        popToRoot()
        endBookingFlow()
    }

    func goToBookings() {
        selectedTab = .bookings
        popToRoot()
    }

    // MARK: - Specific Navigation

    func showParkingDetail(_ parking: Parking) {
        push(.parkingDetail(parking))
    }

    func showNotifications() {
        push(.notifications)
    }

    func showSettings() {
        push(.settings)
    }

    func showWallet() {
        push(.wallet)
    }

    func startBookingFlow(_ parking: Parking) {
        fullScreenRoute = .bookingFlow(parking, UUID())
    }

    func endBookingFlow() {
        fullScreenRoute = nil
    }

    func resetForLogout() {
        selectedTab = .home
        popToRoot()
        endBookingFlow()
    }
}

// MARK: - Parking Hashable Extension
extension Parking: Hashable {
    static func == (lhs: Parking, rhs: Parking) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
