//
//  AppCoordinator.swift
//  Smart parking
//
//  Markazlashtirilgan navigation boshqaruvi
//

import SwiftUI

// MARK: - App Routes
enum AppRoute: Hashable {
    case home
    case explore
    case favorite
    case bookings
    case profile

    // Detail views
    case parkingDetail(Parking)
    case notifications
    case bookingFlow(Parking)
    case eTicket(BookingItem)

    // Profile sub-views
    case editProfile
    case myVehicles
    case paymentMethods
    case notificationSettings
}

// MARK: - App Coordinator
@MainActor
@Observable
final class AppCoordinator {
    static let shared = AppCoordinator()

    var path = NavigationPath()
    var selectedTab: Tab = .home
    var showFullScreenBooking: Bool = false
    var currentBookingParking: Parking?

    private init() {}

    enum Tab: Int, CaseIterable {
        case home, explore, favorite, bookings, profile

        var title: String {
            switch self {
            case .home: return "Home"
            case .explore: return "Explore"
            case .favorite: return "Favorite"
            case .bookings: return "Bookings"
            case .profile: return "Profile"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house"
            case .explore: return "location"
            case .favorite: return "heart"
            case .bookings: return "doc.text"
            case .profile: return "person"
            }
        }
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

    func startBookingFlow(_ parking: Parking) {
        currentBookingParking = parking
        showFullScreenBooking = true
    }

    func endBookingFlow() {
        showFullScreenBooking = false
        currentBookingParking = nil
    }

    func showETicket(_ booking: BookingItem) {
        push(.eTicket(booking))
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

// MARK: - BookingItem Hashable Extension
extension BookingItem: Hashable {
    static func == (lhs: BookingItem, rhs: BookingItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
