//
//  UserServices.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 11/12/25.
//

import Foundation
import Supabase

struct UserService {

    func fetchCurrentUser() async throws -> User {
        let user = try await SB.shared.client.auth.session.user

        return try await SB.shared.client
            .from("users")
            .select()
            .eq("id", value: user.id.uuidString)
            .single()
            .execute()
            .value
    }

    func updateProfileImageURL(_ imageURL: String) async throws {
        guard let uid = SB.shared.client.auth.currentUser?.id.uuidString else {
            print("DEBUG: No valid session found. User is not authenticated.")
            throw URLError(.userAuthenticationRequired)
        }

        try await SB.shared.client
            .from("users")
            .update(["profileImageURL": imageURL])
            .eq("id", value: uid)
            .execute()

        print("DEBUG: Profile image URL updated successfully!")
    }
}
