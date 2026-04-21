//
//  UserManager.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 11/12/25.
//

import Foundation
import os

@Observable
@MainActor
class UserManager {
    var currentUser: User?
    var lastError: String?
    var isOwner: Bool { currentUser?.role == .owner }
    private var service: UserService

    init(service: UserService? = nil) {
        self.service = service ?? UserService(client: SB.shared.client)
    }

    func fetchCurrentUser() async {
        do {
            self.currentUser = try await self.service.fetchCurrentUser()
        } catch {
            Logger.auth.error("Failed to fetch current user: \(error.localizedDescription)")
            lastError = error.localizedDescription
        }
    }

    func updateProfileImageURL(_ imageURL: String) async throws {
        try await service.updateProfileImageURL(imageURL)
        self.currentUser?.profileImageURL = imageURL
    }

    func updateUsername(_ username: String) async throws {
        try await service.updateUsername(username)
        currentUser?.username = username
    }
}
