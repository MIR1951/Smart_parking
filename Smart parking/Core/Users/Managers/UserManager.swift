//
//  UserManager.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 11/12/25.
//

import Foundation

@Observable
@MainActor
class UserManager {
    var currentUser: User?
    private var service: UserService

    init(service: UserService? = nil) {
        self.service = service ?? UserService(client: SB.shared.client)
    }

    func fetchCurrentUser() async {
        do {
            self.currentUser = try await self.service.fetchCurrentUser()
        } catch {

        }
    }
    func updateProfileImageURL(_ imageURL: String) async {
        do {
            try await service.updateProfileImageURL(imageURL)
            self.currentUser?.profileImageURL = imageURL
        } catch {

        }
    }

    func updateUsername(_ username: String) async throws {
        try await service.updateUsername(username)
        currentUser?.username = username
    }
}
