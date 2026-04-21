//
//  UserServices.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 11/12/25.
//

import Foundation
import Supabase

struct UserService {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchCurrentUser() async throws -> User {
        let user = try await client.auth.session.user

        return
            try await client
            .from("users")
            .select()
            .eq("id", value: user.id)
            .single()
            .execute()
            .value
    }

    func updateProfileImageURL(_ imageURL: String) async throws {
        guard let uid = client.auth.currentUser?.id else {
            throw URLError(.userAuthenticationRequired)
        }

        try await client
            .from("users")
            .update(["profile_image_url": imageURL])
            .eq("id", value: uid)
            .execute()
    }

    func updateUsername(_ username: String) async throws {
        guard let uid = client.auth.currentUser?.id else {
            throw URLError(.userAuthenticationRequired)
        }

        try await client
            .from("users")
            .update(["username": username])
            .eq("id", value: uid)
            .execute()
    }
}
