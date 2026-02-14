//
//  SupabaseAuthService.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import Foundation
import Supabase

struct SupabaseAuthService {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func signUp(email: String, password: String, username: String) async throws -> String {
        let response = try await client.auth.signUp(email: email, password: password)
        let uid = response.user.id.uuidString
        try await uploadUserData(with: uid, email: email, username: username)
        return uid
    }

    func signIn(email: String, password: String) async throws -> String {
        let response = try await client.auth.signIn(email: email, password: password)

        return response.user.id.uuidString
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    func verifyOTP(email: String, token: String) async throws {
        try await client.auth.verifyOTP(
            email: email,
            token: token,
            type: .recovery
        )
    }

    func updatePassword(newPassword: String) async throws {
        try await client.auth.update(user: .init(password: newPassword))
    }

    func getCurrentUserSession() async throws -> String? {
        let session = try await client.auth.session
        let supabaseUser = session.user
        return supabaseUser.id.uuidString
    }
    func uploadUserData(with uid: String, email: String, username: String) async throws {
        let user = User(id: uid, email: email, username: username, createdAt: Date())
        try await client.from("users").insert(user).execute()
    }

}
